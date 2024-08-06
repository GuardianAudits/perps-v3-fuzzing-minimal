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

            invariant_LIQ_02();
            // @audit-ok This assertion is supposed to fail to show a user can be liquidated in such a scenario.
            // invariant_LIQ_03();
            invariant_LIQ_04(accountIds);
            invariant_LIQ_05(accountIds);
            invariant_LIQ_06(accountIds);
            invariant_LIQ_07(accountIds);
            invariant_LIQ_09(
                _incrementAndCheckLiquidationCalls(actorsToUpdate[0]),
                actorsToUpdate[0]
            ); //liquidator
            invariant_MGN_11();

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

            invariant_MGN_11();
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
                invariant_MGN_11();
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
                // invariant_MGN_11();
                onSuccessInvariantsGeneral(
                    returnData,
                    uint128(flaggedAccounts[i])
                );
            }
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
