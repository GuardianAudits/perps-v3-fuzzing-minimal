// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FuzzLiquidationModule.sol";
import "./FuzzOrderModule.sol";
import "./FuzzAdmin.sol";
import "./FuzzPerpsAccountModule.sol";

contract FuzzGuidedModule is
    FuzzLiquidationModule,
    FuzzPerpsAccountModule,
    FuzzOrderModule,
    FuzzAdmin
{
    function fuzz_guided_depositAndShort() public {
        fuzz_modifyCollateral(1e18, 1);
        fuzz_commitOrder(-2e18, type(uint256).max - 1); //-1 is weth short
    }

    function fuzz_guided_createDebt_LiquidateMarginOnly(
        bool isWETH,
        int amountToDeposit
    ) public {
        uint collateralId = isWETH ? 1 : 2;
        amountToDeposit = fl.clamp(amountToDeposit, 1, type(int64).max);

        getPendingOrders(currentActor);
        closeAllPositions(userToAccountIds[currentActor]);
        repayDebt();
        fuzz_withdrawAllCollateral(
            userToAccountIds[currentActor],
            true,
            true,
            true
        );

        //Make sure it is zero @giraffe
        //pump here $50k
        isWETH ? fuzz_pumpWETHPythPrice(20) : fuzz_pumpWBTCPythPrice(20);

        fuzz_modifyCollateral(amountToDeposit, collateralId);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getCollateralAmount.selector,
                userToAccountIds[currentActor],
                collateralId
            )
        );
        require(success);
        uint256 amount = abi.decode(returnData, (uint256));
        fl.log(
            "Currect collateral amount afrer withdrawal and deposits",
            amount
        );

        require(amount > 0, "User needs some collateral");

        //make sure we are on high enough price @giraffe

        fuzz_commitOrder(
            int128(uint128(amount) * 2),
            isWETH ? type(uint256).max - 1 : type(uint256).max //maxprice + marketId
        );
        fuzz_settleOrder();
        isWETH
            ? fuzz_crashWETHPythPrice(uint(amountToDeposit))
            : fuzz_crashWBTCPythPrice(uint(amountToDeposit)); //20% lower
        fuzz_commitOrder((int128(uint128(amount * 2)) * -1), isWETH ? 6 : 5); //maxprice + marketId
        fuzz_settleOrder();
        isWETH ? fuzz_crashWETHPythPrice(20) : fuzz_crashWBTCPythPrice(20); //
        fuzz_liquidateMarginOnly();
    }

    function repayDebt() public returns (int256 debt) {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.debt.selector,
                userToAccountIds[currentActor]
            )
        );
        require(success);
        debt = abi.decode(returnData, (int256));
        if (debt > 0) {
            fuzz_payDebt(uint128(int128(debt)));
        }
    }

    function getPendingOrders(address user) internal {
        uint128 accountId = userToAccountIds[user];

        // Get the order
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderModuleImpl.getOrder.selector,
                accountId
            )
        );
        require(success);
        AsyncOrder.Data memory order = abi.decode(
            returnData,
            (AsyncOrder.Data)
        );

        // Check if the order is expired
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.isOrderExpired.selector,
                accountId
            )
        );
        require(success);
        bool isOrderExpired = abi.decode(returnData, (bool));

        // Validate the order
        require(
            order.request.sizeDelta == 0 || isOrderExpired,
            "No unsettled orders"
        );
    }
    function closeAllPositions(uint128 accountId) internal {
        uint128[] memory marketIds = new uint128[](2);
        marketIds[0] = 1; // WETH market
        marketIds[1] = 2; // WBTC market

        for (uint i = 0; i < marketIds.length; i++) {
            uint128 marketId = marketIds[i];
            bool isWETH = (marketId == 1);

            // Get open position
            (bool success, bytes memory returnData) = perps.call(
                abi.encodeWithSelector(
                    perpsAccountModuleImpl.getOpenPosition.selector,
                    accountId,
                    marketId
                )
            );
            require(success);

            (
                int256 totalPnl,
                int256 accruedFunding,
                int128 positionSize,
                uint256 owedInterest
            ) = abi.decode(returnData, (int256, int256, int128, uint256));

            // If position size is not zero, close the position
            if (positionSize != 0) {
                vm.prank(accountIdToUser[accountId]);
                fuzz_commitOrder(
                    int128(uint128(positionSize)) * -1,
                    isWETH ? 6 : 5 // 6 for WETH (marketId 1), 5 for WBTC (marketId 2)
                );

                // Settle the order
                fuzz_settleOrder();
            }
        }
    }

    function fuzz_withdrawAllCollateral(
        uint128 accountId,
        bool weth,
        bool wbtc,
        bool huge
    ) internal {
        uint128[] memory collateralIds = new uint128[](3);
        uint8 collateralCount = 0;

        if (weth) {
            collateralIds[collateralCount] = 1;
            collateralCount++;
        }
        if (wbtc) {
            collateralIds[collateralCount] = 2;
            collateralCount++;
        }
        if (huge) {
            collateralIds[collateralCount] = 3;
            collateralCount++;
        }

        for (uint i = 0; i < collateralCount; i++) {
            uint128 collateralId = collateralIds[i];
            // Get collateral amount
            (bool success, bytes memory returnData) = perps.call(
                abi.encodeWithSelector(
                    perpsAccountModuleImpl.getCollateralAmount.selector,
                    accountId,
                    collateralId
                )
            );
            require(success);
            uint256 amount = abi.decode(returnData, (uint256));
            if (amount > 0) {
                vm.prank(accountIdToUser[accountId]);
                (success, returnData) = perps.call(
                    abi.encodeWithSelector(
                        perpsAccountModuleImpl.modifyCollateral.selector,
                        accountId,
                        collateralId,
                        -int256(amount)
                    )
                );
                require(success);
            }
        }
    }
}
