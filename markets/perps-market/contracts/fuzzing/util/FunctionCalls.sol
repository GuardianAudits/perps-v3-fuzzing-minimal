// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@perimetersec/fuzzlib/src/FuzzBase.sol";
import "../helper/FuzzStorageVariables.sol";
import {AsyncOrder} from "../../storage/AsyncOrder.sol";

contract FunctionCalls is FuzzBase, FuzzStorageVariables {
    event ModifyCollateralCall(
        uint128 accountId,
        uint128 collateralId,
        int256 amountDelta
    );
    event PayDebtCall(uint128 accountId, uint128 amount);
    event SettleOrderCall(address settleUser, uint128 accountId);
    event CancelOrderCall(address settleUser, uint128 accountId);
    event CommitOrderCall(
        uint128 accountId,
        uint128 marketId,
        int128 sizeDelta,
        uint256 acceptablePrice,
        uint128 settlementStrategyId,
        bytes32 trackingCode,
        address referrer
    );
    event LiquidatePositionCall(uint128 accountId);
    event LiquidateMarginOnlyCall(uint128 accountId);
    event LiquidateFlaggedAccountsCall(uint[] flaggedAccounts);
    event LiquidateFlaggedCall(uint maxNumberOfAccounts);

    function _modifyCollateralCall(
        uint128 accountId,
        uint128 collateralId,
        int256 amountDelta
    ) internal returns (bool success, bytes memory returnData) {
        emit ModifyCollateralCall(accountId, collateralId, amountDelta);

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.modifyCollateral.selector,
                accountId,
                collateralId,
                amountDelta
            )
        );
    }

    function _payDebtCall(
        uint128 accountId,
        uint128 amount
    ) internal returns (bool success, bytes memory returnData) {
        emit PayDebtCall(accountId, amount);

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.payDebt.selector,
                accountId,
                amount
            )
        );
    }

    function _commitOrderCall(
        uint128 accountId,
        uint128 marketId,
        int128 sizeDelta,
        uint256 acceptablePrice,
        uint128 settlementStrategyId,
        bytes32 trackingCode,
        address referrer
    ) internal returns (bool success, bytes memory returnData) {
        emit CommitOrderCall(
            accountId,
            marketId,
            sizeDelta,
            acceptablePrice,
            settlementStrategyId,
            trackingCode,
            referrer
        );

        AsyncOrder.OrderCommitmentRequest memory commitment = AsyncOrder
            .OrderCommitmentRequest({
                marketId: marketId,
                accountId: accountId,
                sizeDelta: sizeDelta,
                settlementStrategyId: settlementStrategyId,
                acceptablePrice: acceptablePrice,
                trackingCode: trackingCode,
                referrer: referrer
            });

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderModuleImpl.commitOrder.selector,
                commitment
            )
        );
    }
    function _settleOrderCall(
        address settleUser,
        uint128 accountId
    ) internal returns (bool success, bytes memory returnData) {
        emit SettleOrderCall(settleUser, accountId);
        vm.warp(block.timestamp + 6);

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderSettlementPythModuleImpl.settleOrder.selector,
                accountId
            )
        );
    }

    function _cancelOrderCall(
        address settleUser,
        uint128 accountId
    ) internal returns (bool success, bytes memory returnData) {
        emit CancelOrderCall(settleUser, accountId);
        vm.warp(block.timestamp + 6);

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderCancelModuleImpl.cancelOrder.selector,
                accountId
            )
        );
    }

    function _liquidatePositionCall(
        uint128 accountId
    ) internal returns (bool success, bytes memory returnData) {
        emit LiquidatePositionCall(accountId);

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.liquidate.selector,
                accountId
            )
        );
    }

    function _liquidateMarginOnlyCall(
        uint128 accountId
    ) internal returns (bool success, bytes memory returnData) {
        emit LiquidateMarginOnlyCall(accountId);

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.liquidateMarginOnly.selector,
                accountId
            )
        );
    }

    function _liquidateFlaggedCall(
        uint256 maxNumberOfAccounts
    ) internal returns (bool success, bytes memory returnData) {
        emit LiquidateFlaggedCall(maxNumberOfAccounts);

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.liquidateFlagged.selector,
                maxNumberOfAccounts
            )
        );
    }

    function _liquidateFlaggedAccountsCall(
        uint[] memory flaggedAccounts
    ) internal returns (bool success, bytes memory returnData) {
        emit LiquidateFlaggedAccountsCall(flaggedAccounts);

        vm.prank(currentActor);
        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.liquidateFlaggedAccounts.selector,
                flaggedAccounts
            )
        );
    }
}
