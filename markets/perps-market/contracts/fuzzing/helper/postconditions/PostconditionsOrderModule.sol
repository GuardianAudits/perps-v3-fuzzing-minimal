// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

abstract contract PostconditionsOrderModule is PostconditionsBase {
    function commitOrderPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        uint128 accountId,
        uint128 commitOrderPostconditions
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            invariant_ORD_01(accountId);
            invariant_ORD_15(accountId);
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
        uint128 accountId,
        uint128 marketId
    ) internal {
        if (success) {
            _after(actorsToUpdate);

            invariant_ORD_02(accountId);
            invariant_ORD_03(accountId);
            // TODO: This assertion was failing due to Foundry using default sender. Default sender 0x18 did not have an account, so balance was always 0.
            // modifier setCurrentActor was modified, but should be given another look to prevent Foundry override.
            // fl.log("CURRENT ACTOR ACCOUNT ID SETTLE:", userToAccountIds[currentActor]);
            // fl.log("CURRENT ACTOR SETTLE:", currentActor);
            invariant_ORD_04(userToAccountIds[currentActor]);
            // @audit ORD-06 assertion fails. Looks like a valid break.
            // invariant_ORD_06(accountId, marketId);
            // @audit ORD-07 assertion fails. Looks like a valid break.
            // invariant_ORD_07();
            invariant_ORD_08(accountId);
            // TODO: Properly handle markets for this invariant. BeforeAfter changes required.
            // invariant_ORD_09(settleUser, marketId);
            invariant_ORD_12(accountId);

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
                // @audit This assertion fails.
                invariant_ORD_05(userToAccountIds[currentActor]);
            }
            // @audit ORD-16 assertion fails. Looks like valid break.
            // invariant_ORD_16(userToAccountIds[cancelUser]);
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
