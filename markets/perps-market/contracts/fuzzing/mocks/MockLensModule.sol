//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {AsyncOrder} from "../../storage/AsyncOrder.sol";
import {PerpsMarketConfiguration} from "../../storage/PerpsMarketConfiguration.sol";
import {SettlementStrategy} from "../../storage/SettlementStrategy.sol";
import {console2} from "lib/forge-std/src/Test.sol";
import {PerpsAccount} from "../../storage/PerpsAccount.sol";
import {GlobalPerpsMarket} from "../../storage/GlobalPerpsMarket.sol";
import {PerpsMarket} from "../../storage/PerpsMarket.sol";

import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {SafeCastI256, SafeCastU256, SafeCastU128} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

contract MockLensModule {
    using AsyncOrder for AsyncOrder.Data;
    using PerpsAccount for PerpsAccount.Data;
    using GlobalPerpsMarket for GlobalPerpsMarket.Data;
    using SetUtil for SetUtil.UintSet;
    using SafeCastI256 for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;

    function getDebtCorrectionAccumulator(
        uint128 marketId
    ) external returns (int256) {
        PerpsMarket.Data storage perpsMarketData = PerpsMarket.load(marketId);
        return perpsMarketData.debtCorrectionAccumulator;
    }

    function getOpenPositionMarketIds(
        uint128 accountId
    ) external returns (uint128[] memory) {
        PerpsAccount.Data storage account = PerpsAccount.load(accountId);
        uint256 length = account.openPositionMarketIds.length();
        uint128[] memory marketIds = new uint128[](length);

        for (uint256 i = 1; i <= length; i++) {
            //1 based index
            marketIds[i - 1] = account.openPositionMarketIds.valueAt(i).to128();
        }

        return marketIds;
    }

    function getCollateralTypes(
        uint128 accountId
    ) external returns (uint128[] memory) {
        PerpsAccount.Data storage account = PerpsAccount.load(accountId);
        uint256 length = account.activeCollateralTypes.length();
        uint128[] memory collateralTypes = new uint128[](length);

        for (uint256 i = 1; i <= length; i++) {
            //1 based index
            collateralTypes[i - 1] = account
                .activeCollateralTypes
                .valueAt(i)
                .to128();
        }

        return collateralTypes;
    }
    function getGlobalCollateralTypes()
        external
        view
        returns (uint128[] memory)
    {
        GlobalPerpsMarket.Data storage globalMarketData = GlobalPerpsMarket
            .load();
        SetUtil.UintSet storage activeCollateralTypes = globalMarketData
            .activeCollateralTypes;
        uint256 activeCollateralLength = activeCollateralTypes.length();
        uint128[] memory globalCollateralTypes = new uint128[](
            activeCollateralLength
        );

        for (uint256 i = 1; i <= activeCollateralLength; i++) {
            globalCollateralTypes[i - 1] = uint128(
                activeCollateralTypes.valueAt(i)
            );
        }

        return globalCollateralTypes;
    }

    function getGlobalTotalAccountsDebt() external view returns (uint256) {
        GlobalPerpsMarket.Data storage globalMarketData = GlobalPerpsMarket
            .load();

        return globalMarketData.totalAccountsDebt;
    }

    function isOrderExpired(uint128 accountId) external view returns (bool) {
        AsyncOrder.Data storage order = AsyncOrder.load(accountId);
        console2.log(
            "MockLens::isOrderExpired::order.request.marketId",
            order.request.marketId
        );
        console2.log(
            "MockLens::isOrderExpired::order.request.sizeDelta",
            order.request.sizeDelta
        );
        if (order.request.sizeDelta != 0) {
            SettlementStrategy.Data storage strategy = PerpsMarketConfiguration
                .load(order.request.marketId)
                .settlementStrategies[order.request.settlementStrategyId];

            return AsyncOrder.expired(order, strategy);
        }

        return false;
    }

    function getOrder(
        uint128 accountId
    ) external view returns (AsyncOrder.Data memory) {
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
