// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

abstract contract PostconditionsPerpsAccountModule is PostconditionsBase {
    event DebugPost(string s);
    function modifyCollateralPostconditions(
        int256 amountDelta,
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address collateral,
        uint128 accountId
    ) internal {
        uint collateralId = collateral == address(wethTokenMock)
            ? 1
            : collateral == address(wbtcTokenMock)
                ? 2
                : 0; //SUSD

        if (success) {
            emit DebugPost("modifyCollateralPostconditions HERE#1");
            _after(actorsToUpdate);
            emit DebugPost("modifyCollateralPostconditions HERE#2");

            if (amountDelta < 0) {
                invariant_MGN_01(accountId);
                invariant_MGN_12(accountId, collateralId);
                invariant_MGN_13(amountDelta, collateral);
            }
            emit DebugPost("modifyCollateralPostconditions HERE#3");
            invariant_MGN_03(accountId);
            invariant_MGN_04(accountId);
            invariant_MGN_05(amountDelta, collateral);
            invariant_MGN_06(amountDelta, collateral);
            invariant_MGN_13(amountDelta, collateral);
            invariant_MGN_14(accountId);
            invariant_MGN_16();
            emit DebugPost("modifyCollateralPostconditions HERE#MGN_13");

            // invariant_MGN_07();

            onSuccessInvariantsGeneral(returnData, accountId);
            emit DebugPost("modifyCollateralPostconditions HERE#4");
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
            invariant_MGN_15(accountId);
            // invariant_MGN_07();
            invariant_MGN_16();
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
