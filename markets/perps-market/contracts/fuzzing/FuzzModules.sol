// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FuzzLiquidationModule.sol";
import "./FuzzOrderModule.sol";
import "./FuzzAdmin.sol";
import "./FuzzPerpsAccountModule.sol";

contract FuzzModules is
    FuzzLiquidationModule,
    FuzzPerpsAccountModule,
    FuzzOrderModule,
    FuzzAdmin
{
    function fuzz_guided_createDebt_LiquidateMarginOnly(bool isWETH) public {
        uint collateralId = isWETH ? 1 : 2;
        require(currentActor != USER1);
        withdrawAllCollateral(userToAccountIds[currentActor]);

        fuzz_modifyCollateral(1e18, collateralId);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getCollateralAmount.selector,
                userToAccountIds[currentActor],
                collateralId
            )
        );
        assert(success);

        uint256 amount = abi.decode(returnData, (uint256));

        require(amount > 0, "User needs some collateral");

        fuzz_commitOrder(
            int128(uint128(amount) * 2),
            isWETH ? type(uint256).max - 1 : type(uint256).max //maxprice + marketId
        );
        fuzz_settleOrder();
        isWETH ? fuzz_crashWETHPythPrice(1) : fuzz_crashWBTCPythPrice(1);
        fuzz_commitOrder((int128(uint128(amount * 2)) * -1), isWETH ? 6 : 5); //maxprice + marketId
        fuzz_settleOrder();

        fuzz_crashWBTCPythPrice(9);
        fuzz_liquidateMarginOnly();
    }

    function withdrawAllCollateral(uint128 accountId) internal {
        uint128[] memory collateralIds = new uint128[](2);
        collateralIds[0] = 1;
        collateralIds[1] = 2;

        for (uint i = 0; i < collateralIds.length; i++) {
            uint128 collateralId = collateralIds[i];

            // Get collateral amount
            (bool success, bytes memory returnData) = perps.call(
                abi.encodeWithSelector(
                    perpsAccountModuleImpl.getCollateralAmount.selector,
                    accountId,
                    collateralId
                )
            );
            // assert(success);
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
                // assert(success);
            }
        }
    }
}
