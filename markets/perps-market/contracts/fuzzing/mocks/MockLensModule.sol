//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {AsyncOrder} from "../../storage/AsyncOrder.sol";
import {SettlementStrategy} from "../../storage/SettlementStrategy.sol";
import {PerpsMarketConfiguration} from "../../storage/PerpsMarketConfiguration.sol";
import {console2} from "lib/forge-std/src/Test.sol";

contract MockLensModule {
    using AsyncOrder for AsyncOrder.Data;

    function isOrderExpired(uint128 accountId) external view returns (bool) {
        AsyncOrder.Data storage order = AsyncOrder.load(accountId);
        console2.log("MockLens::isOrderExpired::order.request.marketId", order.request.marketId);
        console2.log("MockLens::isOrderExpired::order.request.sizeDelta", order.request.sizeDelta);
        if (order.request.sizeDelta != 0) {
            SettlementStrategy.Data storage strategy = PerpsMarketConfiguration
                .load(order.request.marketId)
                .settlementStrategies[order.request.settlementStrategyId];

            return AsyncOrder.expired(order, strategy);
        }

        return false;
    }

    function getOrder(uint128 accountId) external view returns (AsyncOrder.Data memory) {
        return AsyncOrder.load(accountId);
    }

    function getSettlementRewardCost(
        uint128 marketId,
        uint128 settlementStrategyId
    ) external view returns (uint256) {
        SettlementStrategy.Data storage strategy = PerpsMarketConfiguration
            .loadValidSettlementStrategy(marketId, settlementStrategyId);
        return AsyncOrder.settlementRewardCost(strategy);
    }

    function calculateFillPrice(
        int256 skew,
        uint256 skewScale,
        int128 sizeDelta,
        uint256 price
    ) external pure returns (uint256) {
        return AsyncOrder.calculateFillPrice(skew, skewScale, sizeDelta, price);
    }

    // function calculateOrderFee(
    //     int128 sizeDelta,
    //     uint256 fillPrice,
    //     int256 marketSkew,
    //     AsyncOrder.OrderFee storage orderFeeData //marketConfig.orderFees
    // ) external view returns (uint256) {
    //     return AsyncOrder.calculateOrderFee(sizeDelta, fillPrice, marketSkew, orderFeeData);
    // }
}
