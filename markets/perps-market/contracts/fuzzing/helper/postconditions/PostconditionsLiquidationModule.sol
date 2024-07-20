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
        uint128 accountId
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            // invariant_LIQ_02(accountId);
            // invariant_LIQ_03();
            // invariant_LIQ_08();
            // invariant_LIQ_09(accountId);
            // invariant_LIQ_10(accountId);
            // invariant_LIQ_11(accountId);
            // invariant_LIQ_12(accountId);
            onSuccessInvariantsGeneral(returnData, accountId);
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
            // invariant_LIQ_12(accountId);
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

            onSuccessInvariantsGeneral(returnData, type(uint128).max);
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

            onSuccessInvariantsGeneral(returnData, type(uint128).max);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
