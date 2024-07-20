// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

abstract contract PostconditionsOrderModule is PostconditionsBase {
    function commitOrderPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        uint128 accountId
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            // invariant_ORD_01(accountId);
            // invariant_ORD_15(accountId);
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    //TODO: after settle

    function settleOrderPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address settleUser,
        uint128 accountId
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            // invariant_ORD_02(accountId);
            // invariant_ORD_03(accountId);
            // invariant_ORD_04(userToAccountIds[currentActor][0]);
            // invariant_ORD_06(accountId);
            // invariant_ORD_07();
            // invariant_ORD_08(accountId);
            // invariant_ORD_09(settleUser);
            // invariant_ORD_12(accountId);

            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function cancelOrderPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address cancelUser,
        uint128 accountId
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            if (cancelUser != currentActor) {
                // invariant_ORD_05(userToAccountIds[currentActor][0]);
            }
            // invariant_ORD_16(cancelUser);
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
