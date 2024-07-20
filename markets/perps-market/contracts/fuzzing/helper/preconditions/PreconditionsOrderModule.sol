// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {AsyncOrder} from "../../../storage/AsyncOrder.sol";

import "./PreconditionsBase.sol";

abstract contract PreconditionsOrderModule is PreconditionsBase {
    struct CommitOrderParams {
        uint128 accountId;
        uint128 marketId;
        int128 sizeDelta;
        uint256 acceptablePrice;
        uint128 settlementStrategyId;
        bytes32 trackingCode;
        address referrer;
    }

    struct SettleOrderParams {
        address settleUser;
        uint128 accountId;
    }

    struct CancelOrderParams {
        address cancelUser;
        uint128 accountId;
    }

    function commitOrderPreconditions(
        int128 sizeDelta,
        uint256 acceptablePrice,
        bytes32 trackingCode,
        address referrer
    ) internal returns (CommitOrderParams memory) {
        console2.log("===== PreconditionsOrderModule:commitOrderPreconditions START =====");

        uint128 settlementStrategyId = 0; //@coverage:limiter currently employing only one settlement strategy
        console2.log("===== uint128 account  START =====");
        console2.log("currentActor", currentActor);
        console2.log("acceptablePrice", acceptablePrice);

        uint128[] memory accountIds = userToAccountIds[currentActor];
        console2.log("Number of accounts for currentActor", accountIds.length);
        uint128 account = userToAccountIds[currentActor][
            acceptablePrice % userToAccountIds[currentActor].length
        ];
        console2.log("===== uint128 account  END =====");

        uint128 marketId = acceptablePrice % 2 == 0 ? 1 : 2;
        console2.log("===== Constructing CommitOrderParams START =====");

        console2.log("account", account);
        console2.log("marketId", marketId);

        int128 clampedSizeDelta = int128(
            fl.clamp(
                sizeDelta,
                -int128(marketId == 1 ? WETH_MAX_MARKET_SIZE : WBTC_MAX_MARKET_SIZE),
                int128(marketId == 1 ? WETH_MAX_MARKET_SIZE : WBTC_MAX_MARKET_SIZE)
            )
        );
        console2.log("clampedSizeDelta", clampedSizeDelta);

        console2.log("WETH_MAX_MARKET_SIZE", WETH_MAX_MARKET_SIZE);
        console2.log("WBTC_MAX_MARKET_SIZE", WBTC_MAX_MARKET_SIZE);

        console2.log("acceptablePrice", acceptablePrice);
        console2.log("===== Constructing CommitOrderParams END =====");

        return
            CommitOrderParams({
                accountId: account,
                marketId: marketId,
                sizeDelta: int128(
                    fl.clamp(
                        sizeDelta,
                        -int128(marketId == 1 ? WETH_MAX_MARKET_SIZE : WBTC_MAX_MARKET_SIZE),
                        int128(marketId == 1 ? WETH_MAX_MARKET_SIZE : WBTC_MAX_MARKET_SIZE)
                    )
                ),
                acceptablePrice: acceptablePrice,
                settlementStrategyId: settlementStrategyId,
                trackingCode: trackingCode,
                referrer: referrer
            });
        console2.log("===== PreconditionsOrderModule:commitOrderPreconditions END =====");
    }

    function settleOrderPreconditions(
        uint8 settleUser
    ) internal returns (SettleOrderParams memory) {
        uint128 account = userToAccountIds[commitCaller][
            settleUser % userToAccountIds[commitCaller].length
        ];

        return SettleOrderParams({settleUser: commitCaller, accountId: account});
    }

    function cancelOrderPreconditions(
        uint8 cancelUser
    ) internal view returns (CancelOrderParams memory) {
        address user = USERS[cancelUser % (USERS.length - 1)];
        uint128 account = userToAccountIds[user][
            cancelUser % userToAccountIds[currentActor].length
        ];
        uint128 marketId = cancelUser % 2 == 0 ? 1 : 2;

        return
            CancelOrderParams({
                cancelUser: USERS[cancelUser % (USERS.length - 1)],
                accountId: account
            });
    }
}
