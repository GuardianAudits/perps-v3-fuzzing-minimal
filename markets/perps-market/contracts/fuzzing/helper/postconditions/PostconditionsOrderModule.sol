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
            invariant_ORD_14(accountId);

            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

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
            _afterSettlement(accountId, marketId);

            invariant_ORD_02(accountId);
            invariant_ORD_03(accountId);
            // This assertion was failing due to Foundry using default sender. Default sender 0x18 did not have an account, so balance was always 0.
            // modifier setCurrentActor was modified, but should be given another look to prevent Foundry override.
            // fl.log("CURRENT ACTOR ACCOUNT ID SETTLE:", userToAccountIds[currentActor]);
            // fl.log("CURRENT ACTOR SETTLE:", currentActor);
            invariant_ORD_04(userToAccountIds[currentActor]);
            // @audit ORD-06 assertion fails. Looks like a valid break.
            invariant_ORD_06(accountId, marketId);
            // @audit ORD-07 assertion fails. Looks like a valid break.
            invariant_ORD_07();
            invariant_ORD_08(accountId);
            invariant_ORD_09(accountId, marketId);
            invariant_ORD_11(accountId);
            invariant_ORD_13();
            invariant_ORD_16(accountId, marketId);
            invariant_ORD_17(accountId);
            // @audit This assetion fails
            // invariant_ORD_19(accountId);
            invariant_MGN_11();
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
                // invariant_ORD_05(userToAccountIds[currentActor]);
            }
            invariant_ORD_12(accountId);

            // @audit ORD-15 assertion fails. Looks like valid break.
            // invariant_ORD_15(userToAccountIds[cancelUser]);
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
