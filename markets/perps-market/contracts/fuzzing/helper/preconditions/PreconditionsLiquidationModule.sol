// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

abstract contract PreconditionsLiquidationModule is PreconditionsBase {
    struct LiquidateMarginOnlyParams {
        address user;
        uint128 accountId;
        uint128 marketId;
    }

    struct LiquidatePositionParams {
        address user;
        uint128 accountId;
        uint128 marketId;
    }

    struct LiquidateFlaggedParams {
        uint numberOfAccounts;
        uint[] flaggedAccounts;
        uint128 marketId;
    }
    struct LiquidateFlaggedAccountsParams {
        uint[] initialFlaggedAccounts;
        uint[] flaggedAccounts;
        uint128 marketId;
    }

    function liquidatePositionPreconditions(
        uint8 flagUser
    ) internal returns (LiquidatePositionParams memory) {
        address userToLiquidate;
        uint128 accountToLiquidate;
        // search users array for one is eligible for liquidation
        for (uint128 i; i < ACCOUNTS.length; i++) {
            (bool success, bytes memory returnData) = perps.call(
                abi.encodeWithSelector(liquidationModuleImpl.canLiquidate.selector, i)
            );
            assert(success);

            bool isEligible = abi.decode(returnData, (bool));

            if (isEligible) {
                accountToLiquidate = ACCOUNTS[i];
                break;
            }

            if (i == ACCOUNTS.length - 1) {
                require(false, "no flagged users to liquidate");
            }
        }

        uint128 marketId = flagUser % 2 == 0 ? 1 : 2;
        return
            LiquidatePositionParams({
                user: accountIdToUser[accountToLiquidate],
                accountId: accountToLiquidate,
                marketId: marketId
            });
    }

    function liquidateMarginOnlyPreconditions(
        uint8 flagUser
    ) internal returns (LiquidateMarginOnlyParams memory) {
        uint128 account = ACCOUNTS[flagUser % (ACCOUNTS.length - 1)];

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.canLiquidateMarginOnly.selector, account)
        );
        assert(success);

        bool isEligible = abi.decode(returnData, (bool));
        require(isEligible, "This account is not eligible for liquidation");

        uint128 marketId = flagUser % 2 == 0 ? 1 : 2;
        address user = accountIdToUser[account];
        return LiquidateMarginOnlyParams({user: user, accountId: account, marketId: marketId});
    }

    function liquidateFlaggedPreconditions(
        uint8 maxNumberOfAccounts
    ) internal returns (LiquidateFlaggedParams memory) {
        uint numberOfAccounts = fl.clamp(maxNumberOfAccounts, 0, (ACCOUNTS.length - 1));

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.flaggedAccounts.selector)
        );
        assert(success);

        uint256[] memory flaggedAccounts = abi.decode(returnData, (uint256[]));

        require(flaggedAccounts.length > 0, "No accounts to liquidate");

        uint128 marketId = maxNumberOfAccounts % 2 == 0 ? 1 : 2;

        return
            LiquidateFlaggedParams({
                numberOfAccounts: numberOfAccounts,
                flaggedAccounts: flaggedAccounts,
                marketId: marketId
            });
    }

    function liquidateFlaggedAccountsPreconditions(
        uint8 maxNumberOfAccounts
    ) internal returns (LiquidateFlaggedAccountsParams memory) {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.flaggedAccounts.selector)
        );
        assert(success);

        uint256[] memory flaggedAccounts = abi.decode(returnData, (uint256[]));
        require(flaggedAccounts.length > 0, "No accounts to liquidate");

        uint newLength = fl.clamp(maxNumberOfAccounts, 1, flaggedAccounts.length);
        uint256[] memory cutFlaggedAccounts = new uint256[](newLength);

        for (uint256 i = 0; i < newLength; i++) {
            cutFlaggedAccounts[i] = flaggedAccounts[i];
        }
        uint128 marketId = maxNumberOfAccounts % 2 == 0 ? 1 : 2;

        return
            LiquidateFlaggedAccountsParams({
                initialFlaggedAccounts: flaggedAccounts,
                flaggedAccounts: cutFlaggedAccounts,
                marketId: marketId
            });
    }
}
