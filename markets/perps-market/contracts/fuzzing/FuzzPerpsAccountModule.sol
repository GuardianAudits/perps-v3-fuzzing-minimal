// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./helper/preconditions/PreconditionsPerpsAccountModule.sol";
import "./helper/postconditions/PostconditionsPerpsAccountModule.sol";
import "./util/FunctionCalls.sol";

contract FuzzPerpsAccountModule is
    PreconditionsPerpsAccountModule,
    PostconditionsPerpsAccountModule
{
    event DebugPerpsAccount(string s);
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
        emit DebugPerpsAccount("HERE#1");
        _before(actorsToUpdate);
        emit DebugPerpsAccount("HERE#2");

        (bool success, bytes memory returnData) = _modifyCollateralCall(
            params.accountId,
            params.collateralId,
            params.amountDelta
        );
        emit DebugPerpsAccount("HERE#3");

        modifyCollateralPostconditions(
            params.amountDelta,
            success,
            returnData,
            actorsToUpdate,
            params.collateralAddress,
            params.accountId
        );
        emit DebugPerpsAccount("HERE#4");
    }

    function fuzz_payDebt(uint128 amount) public setCurrentActor {
        PayDebtParams memory params = payDebtPreconditions(amount);

        address[] memory actorsToUpdate = new address[](1);
        actorsToUpdate[0] = currentActor;

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _payDebtCall(
            params.accountId,
            params.amount
        );

        payDebtPostconditions(
            success,
            returnData,
            actorsToUpdate,
            params.accountId
        );
    }
}
