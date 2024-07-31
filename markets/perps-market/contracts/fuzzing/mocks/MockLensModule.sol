//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {AsyncOrder} from "../../storage/AsyncOrder.sol";
import {PerpsMarketConfiguration} from "../../storage/PerpsMarketConfiguration.sol";
import {SettlementStrategy} from "../../storage/SettlementStrategy.sol";
import {PerpsAccount} from "../../storage/PerpsAccount.sol";
import {GlobalPerpsMarket} from "../../storage/GlobalPerpsMarket.sol";
import {PerpsMarket} from "../../storage/PerpsMarket.sol";
import {PerpsPrice} from "../../storage/PerpsPrice.sol";
import {Position} from "../../storage/Position.sol";
import {MockPythERC7412Wrapper} from "../../mocks/MockPythERC7412Wrapper.sol";
import "@perimetersec/fuzzlib/src/IHEVM.sol";

// import {IAsyncOrderSettlementPythModule} from "../../interfaces/IAsyncOrderSettlementPythModule.sol"; //TODO: delete

import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {SafeCastI256, SafeCastU256, SafeCastU128} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import {console2} from "lib/forge-std/src/Test.sol";

contract MockLensModule {
    using AsyncOrder for AsyncOrder.Data;
    using PerpsAccount for PerpsAccount.Data;
    using GlobalPerpsMarket for GlobalPerpsMarket.Data;
    using PerpsMarket for PerpsMarket.Data;
    using Position for Position.Data;
    using SetUtil for SetUtil.UintSet;
    using SafeCastI256 for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    MockPythERC7412Wrapper public pythWrapper;

    struct StackCache {
        uint256 currentPrice;
        uint256 notionalValue;
        int256 totalPnl;
        int256 pricePnl;
        uint256 chargedInterest;
        int256 accruedFunding;
        int256 netFundingPerUnit;
        int256 nextFunding;
        int128 positionSize;
    }
    struct SettleOrderRuntime {
        uint128 marketId;
        uint128 accountId;
        int128 sizeDelta;
        int256 pnl;
        uint256 chargedInterest;
        int256 accruedFunding;
        uint256 settlementReward;
        uint256 fillPrice;
        uint256 totalFees;
        uint256 referralFees;
        uint256 feeCollectorFees;
        Position.Data newPosition;
        uint256 synthDeductionIterator;
        uint128[] deductedSynthIds;
        uint256[] deductedAmount;
        int256 chargedAmount;
        uint256 newAccountDebt;
    }

    function getPythWrapperAddress() public view returns (address) {
        return address(pythWrapper);
    }

    function setPythWrapperAddress(address _pythWrapper) public {
        bool done;
        require(!done); //only once

        pythWrapper = MockPythERC7412Wrapper(_pythWrapper);
        done = true;
    }

    function getChargeAmount(
        uint128 accountId
    ) external returns (int256 chargedAmount) {
        SettleOrderRuntime memory runtime;
        // runtime.accountId = asyncOrder.request.accountId;
        // runtime.marketId = asyncOrder.request.marketId;

        AsyncOrder.Data storage asyncOrder = AsyncOrder.load(accountId);
        console2.log(
            "MockLens::isOrderExpired::order.request.marketId",
            asyncOrder.request.marketId
        );
        console2.log(
            "MockLens::isasyncOrderExpired::asyncOrder.request.sizeDelta",
            asyncOrder.request.sizeDelta
        );

        if (asyncOrder.request.sizeDelta != 0) {
            SettlementStrategy.Data
                storage settlementStrategy = PerpsMarketConfiguration
                    .load(asyncOrder.request.marketId)
                    .settlementStrategies[
                        asyncOrder.request.settlementStrategyId
                    ];
            console2.log("PythWrapper in MockLens", address(pythWrapper));
            int256 offchainPrice = pythWrapper.getBenchmarkPrice(
                settlementStrategy.feedId,
                0
            );
            console2.log("After pythWrapper.getBenchmarkPrice");
            console2.log("offchainPrice:", offchainPrice);

            uint256 price = offchainPrice.toUint();

            Position.Data storage oldPosition;
            console2.log("Before asyncOrder.validateRequest");
            (
                runtime.newPosition,
                runtime.totalFees,
                runtime.fillPrice,
                oldPosition
            ) = asyncOrder.validateRequest(settlementStrategy, price);
            console2.log("After asyncOrder.validateRequest");
            console2.log("runtime.totalFees:", runtime.totalFees);
            console2.log("runtime.fillPrice:", runtime.fillPrice);

            console2.log("Before asyncOrder.validateAcceptablePrice");
            asyncOrder.validateAcceptablePrice(runtime.fillPrice);
            console2.log("After asyncOrder.validateAcceptablePrice");

            console2.log("Before oldPosition.getPnl");
            (
                runtime.pnl,
                ,
                runtime.chargedInterest,
                runtime.accruedFunding,
                ,

            ) = oldPosition.getPnl(runtime.fillPrice);
            console2.log("After oldPosition.getPnl");
            console2.log("runtime.pnl:", runtime.pnl);
            console2.log("runtime.chargedInterest:", runtime.chargedInterest);
            console2.log("runtime.accruedFunding:", runtime.accruedFunding);

            chargedAmount = runtime.pnl - runtime.totalFees.toInt();
            console2.log("chargedAmount:", chargedAmount);
        } else {
            console2.log("getChargedAmount skipped, no order found");
        }
    }
    function isAccountLiquidatable(
        uint128 accountId
    ) external view returns (bool) {
        GlobalPerpsMarket.Data storage globalMarketData = GlobalPerpsMarket
            .load();
        return globalMarketData.liquidatableAccounts.contains(accountId);
    }

    function getPositionData(
        uint128 accountId,
        uint128 marketId
    )
        external
        view
        returns (
            uint256 notionalValue,
            int256 totalPnl,
            int256 pricePnl,
            uint256 chargedInterest,
            int256 accruedFunding,
            int256 netFundingPerUnit,
            int256 nextFunding,
            int128 positionSize
        )
    {
        StackCache memory cache;

        Position.Data storage position = PerpsMarket.load(marketId).positions[
            accountId
        ];

        cache.currentPrice = PerpsPrice.getCurrentPrice(
            marketId,
            PerpsPrice.Tolerance.DEFAULT
        );

        (
            cache.notionalValue,
            cache.totalPnl,
            cache.pricePnl,
            cache.chargedInterest,
            cache.accruedFunding,
            cache.netFundingPerUnit,
            cache.nextFunding
        ) = Position.getPositionData(position, cache.currentPrice);

        cache.positionSize = position.size;

        return (
            cache.notionalValue,
            cache.totalPnl,
            cache.pricePnl,
            cache.chargedInterest,
            cache.accruedFunding,
            cache.netFundingPerUnit,
            cache.nextFunding,
            cache.positionSize
        );
    }
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

    function getMaxLiquidatableAmount(
        uint128 marketId,
        uint128 requestedLiquidationAmount
    ) external returns (uint128 liquidatableAmount) {
        PerpsMarket.Data storage market = PerpsMarket.load(marketId);

        liquidatableAmount = PerpsMarket.maxLiquidatableAmount(
            market,
            requestedLiquidationAmount
        );
    }
}
