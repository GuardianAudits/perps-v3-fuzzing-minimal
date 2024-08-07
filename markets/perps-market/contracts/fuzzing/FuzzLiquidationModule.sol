// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FuzzSetup.sol";
import "./helper/preconditions/PreconditionsLiquidationModule.sol";
import "./helper/postconditions/PostconditionsLiquidationModule.sol";
import "./util/FunctionCalls.sol";

/**
 * @title FuzzLiquidationModule
 * @author 0xScourgedev
 * @notice Fuzz handlers for LiquidationModule
 */
contract FuzzLiquidationModule is
    PreconditionsLiquidationModule,
    PostconditionsLiquidationModule
{
    event Debug(string s);
    event LogBytes(bytes data);

    function fuzz_liquidatePosition() public setCurrentActor {
        LiquidatePositionParams
            memory params = liquidatePositionPreconditions();

        address[] memory actorsToUpdate = new address[](2);
        actorsToUpdate[0] = currentActor; //This is liquidator
        actorsToUpdate[1] = params.user;

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _liquidatePositionCall(
            params.accountId
        );

        liquidatePositionPostconditions(
            success,
            returnData,
            actorsToUpdate,
            params.user,
            currentActor,
            params.accountId
        );
    }

    function fuzz_liquidateMarginOnly() public setCurrentActor {
        LiquidateMarginOnlyParams
            memory params = liquidateMarginOnlyPreconditions();

        address[] memory actorsToUpdate = new address[](2);
        actorsToUpdate[0] = currentActor; //This is liquidator
        actorsToUpdate[1] = params.user;

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _liquidateMarginOnlyCall(
            params.accountId
        );

        liquidateMarginOnlyPostconditions(
            success,
            returnData,
            actorsToUpdate,
            params.user,
            params.accountId
        );
    }

    function fuzz_liquidateFlagged(
        uint8 maxNumberOfAccounts
    ) public setCurrentActor {
        LiquidateFlaggedParams memory params = liquidateFlaggedPreconditions(
            maxNumberOfAccounts
        );

        if (params.numberOfAccounts == 0) return;

        address[] memory actorsToUpdate = new address[](2);
        actorsToUpdate[0] = currentActor; //This is liquidator

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _liquidateFlaggedCall(
            params.numberOfAccounts
        );

        liquidateFlaggedPostconditions(
            success,
            returnData,
            actorsToUpdate,
            params.flaggedAccounts
        );
    }

    function fuzz_liquidateFlaggedAccounts(
        uint8 maxNumberOfAccounts
    ) public setCurrentActor {
        LiquidateFlaggedParams memory params = liquidateFlaggedPreconditions(
            maxNumberOfAccounts
        );

        if (params.numberOfAccounts == 0) return;

        address[] memory actorsToUpdate = new address[](2);
        actorsToUpdate[0] = currentActor; //This is liquidator

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _liquidateFlaggedAccountsCall(
            params.flaggedAccounts
        );

        luquidateFlaggedAccountsPostconditions(
            success,
            returnData,
            actorsToUpdate,
            params.flaggedAccounts
        );
    }
}
