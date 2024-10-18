// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FuzzSetup.sol";
import "./helper/preconditions/PreconditionsOrderModule.sol";
import "./helper/postconditions/PostconditionsOrderModule.sol";
import "./util/FunctionCalls.sol";
import "../storage/Position.sol";

contract FuzzOrderModule is
    PreconditionsOrderModule,
    PostconditionsOrderModule
{
    mapping(uint128 accountId => CommitOrderParams params) public pendingOrder;

    function fuzz_commitOrder(
        int128 sizeDelta,
        uint256 acceptablePrice
    ) public setCurrentActor {

        address[] memory actorsToUpdate = new address[](1);
        actorsToUpdate[0] = currentActor;

        bytes32 trackingCode;
        address referrer;
        int128 positionSize;
        _before(actorsToUpdate);


        CommitOrderParams memory params = commitOrderPreconditions(
            sizeDelta,
            acceptablePrice,
            trackingCode,
            referrer
        );

        require(params.marketId != 0);
        _beforeSettlement(params.accountId, params.marketId);

        // require(pendingOrder[params.accountId].accountId == uint128(0), "User has a pending order");


        positionSize = params.marketId == 1
            ? states[0].actorStates[params.accountId].wethMarket.positionSize
            : states[0].actorStates[params.accountId].wbtcMarket.positionSize;

        // Close position entirely.
        if (acceptablePrice % 5 == 0 && positionSize != 0) {
            params.sizeDelta = positionSize * -1;
        }

        (bool success, bytes memory returnData) = _commitOrderCall(
            params.accountId,
            params.marketId,
            params.sizeDelta,
            params.acceptablePrice,
            params.settlementStrategyId,
            params.trackingCode,
            params.referrer
        );

        commitOrderPostconditions(
            success,
            returnData,
            actorsToUpdate,
            params.accountId,
            params.marketId
        );

        pendingOrder[params.accountId] = params;

    }

    function fuzz_settleOrder() public setCurrentActor {
        SettleOrderParams memory params = settleOrderPreconditions();

        address[] memory actorsToUpdate = new address[](2);
        actorsToUpdate[0] = currentActor;
        actorsToUpdate[1] = params.settleUser;

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _settleOrderCall(
            actorsToUpdate[1],
            params.accountId
        );
        // if (success && (params.sizeDelta < 0)) {
        //     fl.eq(params.sizeDelta, 0, "SO SIZE NEGATIVE SETTLED");
        // }

        if (pendingOrder[params.accountId].marketId != 0) {
            settleOrderPostconditions(
                success,
                returnData,
                actorsToUpdate,
                params.settleUser,
                params.accountId,
                pendingOrder[params.accountId].marketId
            );
        }
        delete pendingOrder[params.accountId];
    }

    function fuzz_cancelOrder(uint8 cancelUser) public setCurrentActor {
        CancelOrderParams memory params = cancelOrderPreconditions(cancelUser);

        address[] memory actorsToUpdate = new address[](2);
        actorsToUpdate[0] = currentActor;
        actorsToUpdate[1] = params.cancelUser;

        _before(actorsToUpdate);

        (bool success, bytes memory returnData) = _cancelOrderCall(
            actorsToUpdate[1],
            params.accountId
        );

        cancelOrderPostconditions(
            success,
            returnData,
            actorsToUpdate,
            params.cancelUser,
            params.accountId
        );
        delete pendingOrder[params.accountId];
    }
}
