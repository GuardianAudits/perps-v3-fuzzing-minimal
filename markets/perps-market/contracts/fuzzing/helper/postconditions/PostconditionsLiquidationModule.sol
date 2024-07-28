// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

abstract contract PostconditionsLiquidationModule is PostconditionsBase {
    function liquidatePositionPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address flaggedUser,
        address liquidator,
        uint128 accountIds
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            // invariant_LIQ_03();
            // @audit-ok This assertion is supposed to fail to show a user can be liquidated in such a scenario.
            // invariant_LIQ_08();
            invariant_LIQ_09(accountIds);
            invariant_LIQ_11(accountIds);
            invariant_LIQ_16();
            invariant_LIQ_17(accountIds);
            invariant_MGN_16();
            onSuccessInvariantsGeneral(returnData, accountIds);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function liquidateMarginOnlyPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address flaggedUser,
        uint128 accountId
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            _checkLCov(true);

            invariant_MGN_16();
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function liquidateFlaggedPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        uint[] memory flaggedAccounts
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            for (uint i = 0; i < flaggedAccounts.length; i++) {
                invariant_MGN_16();
                onSuccessInvariantsGeneral(
                    returnData,
                    uint128(flaggedAccounts[i])
                );
            }
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function luquidateFlaggedAccountsPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        uint[] memory flaggedAccounts
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            for (uint i = 0; i < flaggedAccounts.length; i++) {
                //@audit currently fails
                invariant_MGN_16();
                onSuccessInvariantsGeneral(
                    returnData,
                    uint128(flaggedAccounts[i])
                );
            }
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function liquidatePositionPostconditionsAndICheckAfterPriceMove(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address flaggedUser,
        address liquidator,
        uint128 accountIds
    ) internal {
        if (success) {
            _after(actorsToUpdate);

            //@audit should fail only here
            invariant_ORD_21();

            onSuccessInvariantsGeneral(returnData, accountIds);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
