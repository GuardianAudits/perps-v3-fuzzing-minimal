// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

abstract contract PostconditionsPerpsAccountModule is PostconditionsBase {
    function modifyCollateralPostconditions(
        int256 amountDelta,
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address collateral,
        uint128 accountId
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            modifyCalled = true;
            if (amountDelta < 0) {
                // invariant_MGN_01(accountId);
            }
            // invariant_MGN_02(accountId);
            // invariant_MGN_03(accountId);
            // @audit Currently fails.
            // invariant_MGN_04(accountId);
            // invariant_MGN_05(amountDelta, collateral);
            // invariant_MGN_06(amountDelta, collateral);
            // invariant_MGN_07();
            // invariant_MGN_12(accountId);
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function payDebtPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        uint128 accountId
    ) internal {
        if (success) {
            _after(actorsToUpdate);
            // invariant_MGN_07();
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
