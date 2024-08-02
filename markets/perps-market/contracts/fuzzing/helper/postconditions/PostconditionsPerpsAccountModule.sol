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
                : collateral == address(hugePrecisionTokenMock)
                    ? 3
                    : 0; //SUSD

        if (success) {
            _after(actorsToUpdate);

            if (amountDelta < 0) {
                invariant_MGN_01(accountId);
                invariant_MGN_07(accountId, collateralId);
                invariant_MGN_08(accountId, collateralId);
            }
            invariant_MGN_02(accountId);
            invariant_MGN_03(accountId);
            invariant_MGN_04(amountDelta, collateral);
            invariant_MGN_05(amountDelta, collateral);
            invariant_MGN_06();
            invariant_MGN_08(accountId, collateralId);
            invariant_MGN_09(accountId);
            invariant_MGN_11();

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
            invariant_MGN_10(accountId);

            invariant_MGN_11();
            onSuccessInvariantsGeneral(returnData, accountId);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
