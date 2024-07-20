// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./helper/preconditions/PreconditionsPerpsAccountModule.sol";
import "./helper/postconditions/PostconditionsPerpsAccountModule.sol";
import "./util/FunctionCalls.sol";

contract FuzzPerpsAccountModule is
    PreconditionsPerpsAccountModule,
    PostconditionsPerpsAccountModule
{
    function fuzz_modifyCollateral(
        int256 amountDelta,
        uint collateralTokenIndex
    ) public setCurrentActor {
        ModifyCollateralParams memory params = modifyCollateralPreconditions(
            amountDelta,
            collateralTokenIndex
        );
        address[] memory actorsToUpdate = new address[](1);
        actorsToUpdate[0] = currentActor;

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _modifyCollateralCall(
            params.accountId,
            params.collateralAddress,
            params.amountDelta
        );

        modifyCollateralPostconditions(
            params.amountDelta,
            success,
            returnData,
            actorsToUpdate,
            params.collateralAddress,
            params.accountId
        );
    }

    function fuzz_payDebt(uint128 amount) public setCurrentActor {
        PayDebtParams memory params = payDebtPreconditions(amount);

        address[] memory actorsToUpdate = new address[](1);
        actorsToUpdate[0] = currentActor;

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _payDebtCall(params.accountId, params.amount);

        payDebtPostconditions(success, returnData, actorsToUpdate, params.accountId);
    }
}
