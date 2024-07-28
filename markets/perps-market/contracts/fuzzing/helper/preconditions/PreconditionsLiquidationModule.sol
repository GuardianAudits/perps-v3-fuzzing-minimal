// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

abstract contract PreconditionsLiquidationModule is PreconditionsBase {
    struct LiquidateMarginOnlyParams {
        address user;
        uint128 accountId;
    }

    struct LiquidatePositionParams {
        address user;
        uint128 accountId;
    }

    struct LiquidateFlaggedParams {
        uint numberOfAccounts;
        uint[] flaggedAccounts;
    }

    function liquidatePositionPreconditions()
        internal
        returns (LiquidatePositionParams memory)
    {
        address userToLiquidate;
        uint128 accountToLiquidate;
        // search users array for one is eligible for liquidation
        for (uint128 i; i < USERS.length; i++) {
            console2.log("Checking account:", userToAccountIds[USERS[i]]);

            (bool success, bytes memory returnData) = perps.call(
                abi.encodeWithSelector(
                    liquidationModuleImpl.canLiquidate.selector,
                    userToAccountIds[USERS[i]]
                )
            );
            assert(success);

            bool isEligible = abi.decode(returnData, (bool));

            if (isEligible) {
                accountToLiquidate = userToAccountIds[USERS[i]];
                break;
            }

            if (i == USERS.length - 1) {
                require(false, "no flagged users to liquidate");
            }
        }

        return
            LiquidatePositionParams({
                user: accountIdToUser[accountToLiquidate],
                accountId: accountToLiquidate
            });
    }

    function liquidateMarginOnlyPreconditions()
        internal
        returns (LiquidateMarginOnlyParams memory)
    {
        uint128 accountToLiquidate;
        for (uint128 i; i < USERS.length; i++) {
            console2.log("Checking account for margin-only liquidation:", i);

            (bool success, bytes memory returnData) = perps.call(
                abi.encodeWithSelector(
                    liquidationModuleImpl.canLiquidateMarginOnly.selector,
                    userToAccountIds[USERS[i]]
                )
            );
            assert(success);

            bool isEligible = abi.decode(returnData, (bool));

            if (isEligible) {
                accountToLiquidate = userToAccountIds[USERS[i]];
                break;
            }

            if (i == USERS.length - 1) {
                require(false, "no flagged users to liquidate margin-only");
            }
        }

        return
            LiquidateMarginOnlyParams({
                user: accountIdToUser[accountToLiquidate],
                accountId: accountToLiquidate
            });
    }

    function liquidateFlaggedPreconditions(
        uint8 maxNumberOfAccounts
    ) internal returns (LiquidateFlaggedParams memory) {
        uint numberOfAccounts = fl.clamp(
            maxNumberOfAccounts,
            0,
            (USERS.length - 1)
        );
        uint256 liquidatableAccountsCount = 0;
        uint256[] memory liquidatableAccounts = new uint256[](USERS.length);

        for (uint128 i; i < USERS.length; i++) {
            console2.log("Checking account:", userToAccountIds[USERS[i]]);

            (bool success, bytes memory returnData) = perps.call(
                abi.encodeWithSelector(
                    liquidationModuleImpl.canLiquidate.selector,
                    userToAccountIds[USERS[i]]
                )
            );
            assert(success);

            bool isEligible = abi.decode(returnData, (bool));

            if (isEligible) {
                liquidatableAccounts[
                    liquidatableAccountsCount
                ] = userToAccountIds[USERS[i]];
                liquidatableAccountsCount++;
            }
        }

        require(liquidatableAccountsCount > 0, "No accounts to liquidate");

        uint256[] memory finalLiquidatableAccounts = new uint256[](
            liquidatableAccountsCount
        );
        for (uint256 i = 0; i < liquidatableAccountsCount; i++) {
            finalLiquidatableAccounts[i] = liquidatableAccounts[i];
        }

        return
            LiquidateFlaggedParams({
                numberOfAccounts: uint128(
                    fl.min(numberOfAccounts, liquidatableAccountsCount)
                ),
                flaggedAccounts: finalLiquidatableAccounts
            });
    }
}
