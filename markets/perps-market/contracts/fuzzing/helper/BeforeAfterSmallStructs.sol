// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "../FuzzSetup.sol";
import {AsyncOrder} from "../../storage/AsyncOrder.sol";
import {MathUtil} from "../../utils/MathUtil.sol";
import {LiquidationCoverage} from "./logicalCoverage/LiquidationCoverage.sol";
import {OrderCoverage} from "./logicalCoverage/OrderCoverage.sol";
import {PositionCoverage} from "./logicalCoverage/PositionCoverage.sol";
import {MarketCoverage} from "./logicalCoverage/MarketCoverage.sol";
import {GlobalCoverage} from "./logicalCoverage/GlobalCoverage.sol";

import {console2} from "lib/forge-std/src/Test.sol";

abstract contract BeforeAfter is
    FuzzSetup,
    LiquidationCoverage,
    OrderCoverage,
    PositionCoverage,
    MarketCoverage,
    GlobalCoverage
{
    mapping(uint8 => State) states;
    mapping(uint8 => State) positionStates;
    mapping(uint256 => mapping(address => uint256)) liquidationCallsInBlock;
    uint lcov_liquidateMarginOnlyCovered;

    struct PositionVars {
        // Position.Data position; getting separately instead
        int256 totalPnl;
        int256 accruedFunding;
        int128 positionSize;
        uint256 owedInterest;
        uint256 maxLiquidatableAmount;
    }

    struct MarketVars {
        int256 skew;
        uint256 marketSize;
        uint256 liquidationCapacity;
        uint128 marketSkew;
        uint256 reportedDebt;
        uint256 debtCorrectionAccumulator;
    }

    struct State {
        // account => actorStates
        mapping(uint128 => ActorStates) actorStates;
        MarketVars wethMarket;
        MarketVars wbtcMarket;
        MarketVars hugeMarket;
        uint128[] globalCollateralTypes;
        uint256 depositedSusdCollateral;
        uint256 depositedWethCollateral;
        uint256 depositedWbtcCollateral;
        int256 collateralValueAllUsersSUSDCalculated;
        int256 collateralValueAllUsersWETHCalculated;
        int256 collateralValueAllUsersWBTCCalculated;
        uint depositedHUGECollateral;
        uint256 totalCollateralValueUsd;
        uint256 marketSizeGhost;
        uint256 delegatedCollateralValueUsd; //get with lens
        uint128 currentUtilizationAccruedComputed; //get with lens
        uint256 utilizationRate; //perpsMarketFactoryModuleImpl.utilizationRate
        uint256 delegatedCollateral; //perpsMarketFactoryModuleImpl.utilizationRate
        uint256 lockedCredit; //perpsMarketFactoryModuleImpl.utilizationRate
        uint256 reportedDebtGhost;
        uint256 totalCollateralValueUsdGhost;
        uint256 minimumCredit;
        int128 skew;
        int256 totalDebtCalculated;
        int256 totalDebt;
        bool calculateFillPricePassing;
    }

    struct ActorStates {
        bool isPositionLiquidatable;
        bool isPositionLiquidatablePassing;
        bool isMarginLiquidatable;
        uint128 debt;
        uint256[] collateralIds; //perpsAccountModuleImpl.getAccountCollateralIds
        uint256 balanceOfSUSD;
        uint256 balanceOfWETH;
        uint256 balanceOfWBTC;
        uint256 collateralAmountSUSD;
        uint256 collateralAmountWETH; //perpsAccountModuleImpl.getCollateralAmount
        uint256 collateralAmountWBTC; //perpsAccountModuleImpl.getCollateralAmount
        uint256 collateralAmountHUGE; //perpsAccountModuleImpl.getCollateralAmount
        uint256 totalCollateralValue; //perpsAccountModuleImpl.totalCollateralValue
        int128 sizeDelta;
        bool isOrderExpired;
        uint256 fillPriceWETH;
        uint256 fillPriceWBTC;
        uint256 sUSDBalance;
        int256 availableMargin; //perpsAccountModuleImpl.getAvailableMargin
        uint256 requiredInitialMargin; //perpsAccountModuleImpl.getRequiredMargins
        uint256 requiredMaintenanceMargin; //perpsAccountModuleImpl.getRequiredMargins
        uint256 maxLiquidationReward; //perpsAccountModuleImpl.getRequiredMargins
        uint256 depositedWethCollateral;
        uint256 depositedSusdCollateral;
        uint128[] activeCollateralTypes;
        uint128[] openPositionMarketIds;
        PositionVars wethMarket; //TODO:rename to position
        PositionVars wbtcMarket;
        bool isAccountLiquidatable;
        bool isPreviousPositionInLoss;
        int256 latestPositionPnl;
        bool isPreviousTradePositionInLoss;
        int256 previousTradePositionPnl;
    }

    event DebugSize(int size, address a, string s);
    event DebugSize(int size, address a, uint128 account, string s);

    function _before(address[] memory actors) internal {
        _setStates(0, actors);

        if (DEBUG) debugBefore(actors);
    }

    function _after(address[] memory actors) internal {
        _setStates(1, actors);

        if (DEBUG) debugAfter(actors);
    }

    function _beforeSettlement(uint128 accountId, uint128 marketId) internal {
        _setStates(0, accountId, marketId);
    }

    function _afterSettlement(uint128 accountId, uint128 marketId) internal {
        _setStates(1, accountId, marketId);
    }

    function zeroOutMemory() public {
        // Clear state mappings
        for (uint8 i = 0; i < 2; i++) {
            delete states[i];
            delete positionStates[i];
        }
    }

    function _checkLCov(bool lcov) internal {
        lcov
            ? lcov_liquidateMarginOnlyCovered += 1
            : lcov_liquidateMarginOnlyCovered;
    }

    function _setStates(uint8 callNum, address[] memory actors) internal {
        for (uint256 i = 0; i < ACCOUNTS.length; i++) {
            _setActorState(callNum, ACCOUNTS[i], accountIdToUser[ACCOUNTS[i]]);
        }

        // Set states here that are independent from actors
    }

    function _setStates(
        uint8 callNum,
        uint128 accountId,
        uint128 marketId
    ) internal {
        _setActorState(
            callNum,
            accountId,
            marketId,
            accountIdToUser[accountId]
        );
    }

    function _setActorState(
        uint8 callNum,
        uint128 accountId,
        address actor
    ) internal {
        console2.log("===== BeforeAfter::_setActorState START ===== ");

        resetGhostVariables(callNum);
        getLiquidationValues(callNum, accountId);
        getCollateralInfo(callNum, accountId);
        getOrderInfo(callNum, accountId);
        getPositionInfo(callNum, accountId);
        getMarketInfo(callNum);
        getGlobalCollateralValues(callNum);
        calculateTotalCollateralValueGhost(callNum);
        getUtilizationInfo(callNum);
        getMarginInfo(callNum, accountId);
        getGlobalDebt(callNum);
        getMarketDebt(callNum);
        getAccountBalances(callNum, accountId);
        calculateReportedDebtComparison(callNum);
        calculateTotalAccountsDebt(callNum);
        checkIfAccountLiquidatable(callNum, accountId);
        calculateCollateralValueForEveryToken(callNum);
        console2.log("===== BeforeAfter::_setActorState END ===== ");
    }

    function _setActorState(
        uint8 callNum,
        uint128 accountId,
        uint128 marketId,
        address actor
    ) internal {
        console2.log("===== BeforeAfter::_setActorState START ===== ");

        // _checkIfPositionWasProifitable(callNum, accountId, marketId);
        console2.log("===== BeforeAfter::_setActorState END ===== ");
    }
    function _incrementAndCheckLiquidationCalls(
        address liquidator
    ) internal returns (bool isFirstCall) {
        isFirstCall = liquidationCallsInBlock[block.number][liquidator] == 0;
        liquidationCallsInBlock[block.number][liquidator]++;
        console2.log(
            "_incrementAndCheckLiquidationCalls::incremened to ",
            liquidationCallsInBlock[block.number][liquidator]
        );
        return isFirstCall;
    }
    function resetGhostVariables(uint8 callNum) private {
        states[callNum].totalCollateralValueUsdGhost = 0;
        states[callNum].reportedDebtGhost = 0;
        states[callNum].marketSizeGhost = 0;
        states[callNum].totalDebtCalculated = 0;
    }

    struct LiquidationValues {
        bool success;
        bytes returnData;
    }

    function getLiquidationValues(uint8 callNum, uint128 accountId) private {
        LiquidationValues memory liquidationValues;

        (liquidationValues.success, liquidationValues.returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.canLiquidate.selector,
                accountId
            )
        );
        states[callNum]
            .actorStates[accountId]
            .isPositionLiquidatablePassing = liquidationValues.success;
        fl.log("SUCC VALUE:", liquidationValues.success);
        fl.log("ACCOUNT ID:", accountId);
        fl.log("CALL NUM:", callNum);
        // fl.t(false, "!passing success");
        states[callNum].actorStates[accountId].isPositionLiquidatable = abi
            .decode(liquidationValues.returnData, (bool));

        (liquidationValues.success, liquidationValues.returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.canLiquidateMarginOnly.selector,
                accountId
            )
        );
        assert(liquidationValues.success);
        states[callNum].actorStates[accountId].isMarginLiquidatable = abi
            .decode(liquidationValues.returnData, (bool));

        _logLiquidatableCoverage(
            states[callNum].actorStates[accountId].isPositionLiquidatable,
            states[callNum].actorStates[accountId].isMarginLiquidatable
        );

        _logLiquidateMarginOnlyCoverage(lcov_liquidateMarginOnlyCovered);
    }

    function getAccountBalances(uint8 callNum, uint128 accountId) private {
        states[callNum].actorStates[accountId].balanceOfWETH = wethTokenMock
            .balanceOf(accountIdToUser[accountId]);
        states[callNum].actorStates[accountId].balanceOfSUSD = sUSDTokenMock
            .balanceOf(accountIdToUser[accountId]);
        states[callNum].actorStates[accountId].balanceOfWBTC = wbtcTokenMock
            .balanceOf(accountIdToUser[accountId]);
    }

    struct CollateralInfo {
        bool success;
        bytes returnData;
        uint256[] collateralIds;
        uint256 totalCollateralValue;
    }

    function getCollateralInfo(uint8 callNum, uint128 accountId) private {
        CollateralInfo memory collateralInfo;

        (collateralInfo.success, collateralInfo.returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getAccountCollateralIds.selector,
                accountId
            )
        );
        assert(collateralInfo.success);
        collateralInfo.collateralIds = abi.decode(
            collateralInfo.returnData,
            (uint256[])
        );
        states[callNum].actorStates[accountId].collateralIds = collateralInfo
            .collateralIds;

        getCollateralAmount(callNum, accountId, 0);
        getCollateralAmount(callNum, accountId, 1);
        getCollateralAmount(callNum, accountId, 2);
        getCollateralAmount(callNum, accountId, 3);

        collateralInfo.totalCollateralValue = getTotalCollateralValue(
            accountId
        );
        states[callNum]
            .actorStates[accountId]
            .totalCollateralValue = collateralInfo.totalCollateralValue;

        // Coverage check at the end
        _logCollateralIdsCoverage(
            states[callNum].actorStates[accountId].collateralIds
        );

        // Additional coverage for collateral amounts and total value
        _logCollateralAmountsCoverage(
            states[callNum].actorStates[accountId].collateralAmountSUSD,
            states[callNum].actorStates[accountId].collateralAmountWETH,
            states[callNum].actorStates[accountId].collateralAmountWBTC,
            // states[callNum].actorStates[accountId].collateralAmountHUGE, // TODO: add huge
            states[callNum].actorStates[accountId].totalCollateralValue
        );
    }
    function getTotalCollateralValue(
        uint128 accountId
    ) internal returns (uint256 totalCollateralValue) {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.totalCollateralValue.selector,
                accountId
            )
        );
        assert(success);
        totalCollateralValue = abi.decode(returnData, (uint256));
    }
    function getCollateralAmount(
        uint8 callNum,
        uint128 accountId,
        uint256 collateralId
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getCollateralAmount.selector,
                accountId,
                collateralId
            )
        );
        assert(success);
        uint256 amount = abi.decode(returnData, (uint256));

        if (collateralId == 0) {
            states[callNum]
                .actorStates[accountId]
                .collateralAmountSUSD = amount;
        } else if (collateralId == 1) {
            states[callNum]
                .actorStates[accountId]
                .collateralAmountWETH = amount;
        } else if (collateralId == 2) {
            states[callNum]
                .actorStates[accountId]
                .collateralAmountWBTC = amount;
        } else if (collateralId == 3) {
            states[callNum]
                .actorStates[accountId]
                .collateralAmountHUGE = amount;
        }
    }
    struct OrderInfo {
        bool isOrderExpired;
        AsyncOrder.Data order;
    }

    function getOrderInfo(uint8 callNum, uint128 accountId) private {
        OrderInfo memory orderInfo;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.debt.selector,
                accountId
            )
        );
        assert(success);
        states[callNum].actorStates[accountId].debt = abi.decode(
            returnData,
            (uint128)
        );

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderModuleImpl.getOrder.selector,
                accountId
            )
        );
        assert(success);
        orderInfo.order = abi.decode(returnData, (AsyncOrder.Data));
        states[callNum].actorStates[accountId].sizeDelta = orderInfo
            .order
            .request
            .sizeDelta;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.isOrderExpired.selector,
                accountId
            )
        );
        assert(success);
        orderInfo.isOrderExpired = abi.decode(returnData, (bool));
        states[callNum].actorStates[accountId].isOrderExpired = orderInfo
            .isOrderExpired;

        getOrderFees(callNum, accountId, 1, WETH_PYTH_PRICE_FEED_ID);
        getOrderFees(callNum, accountId, 2, WBTC_PYTH_PRICE_FEED_ID);

        states[callNum].actorStates[accountId].sUSDBalance = sUSDTokenMock
            .balanceOf(accountIdToUser[accountId]);

        _logOrderInfoCoverage(
            states[callNum].actorStates[accountId].debt,
            states[callNum].actorStates[accountId].sizeDelta,
            states[callNum].actorStates[accountId].isOrderExpired,
            states[callNum].actorStates[accountId].fillPriceWETH,
            states[callNum].actorStates[accountId].fillPriceWBTC,
            states[callNum].actorStates[accountId].sUSDBalance
        );
    }

    function getOrderFees(
        uint8 callNum,
        uint128 accountId,
        uint256 marketId,
        bytes32 priceFeedId
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderModuleImpl.computeOrderFeesWithPrice.selector,
                marketId,
                states[callNum].actorStates[accountId].sizeDelta,
                pythWrapper.getBenchmarkPrice(priceFeedId, 0)
            )
        );
        states[callNum].calculateFillPricePassing = success;
        (uint256 orderFees, uint256 fillPrice) = abi.decode(
            returnData,
            (uint256, uint256)
        );

        if (marketId == 1) {
            states[callNum].actorStates[accountId].fillPriceWETH = fillPrice;
        } else if (marketId == 2) {
            states[callNum].actorStates[accountId].fillPriceWBTC = fillPrice;
        }
    }

    struct PositionInfo {
        uint128[] openPositionMarketIds;
        uint128[] activeCollateralTypes;
        uint128[] globalCollateralTypes;
    }

    function getPositionInfo(uint8 callNum, uint128 accountId) private {
        PositionInfo memory positionInfo;

        getOpenPosition(callNum, accountId, 1);
        getOpenPosition(callNum, accountId, 2);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getOpenPositionMarketIds.selector,
                accountId
            )
        );
        assert(success);
        positionInfo.openPositionMarketIds = abi.decode(
            returnData,
            (uint128[])
        );
        states[callNum]
            .actorStates[accountId]
            .openPositionMarketIds = positionInfo.openPositionMarketIds;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getGlobalCollateralTypes.selector,
                accountId
            )
        );
        assert(success);
        positionInfo.activeCollateralTypes = abi.decode(
            returnData,
            (uint128[])
        );
        states[callNum]
            .actorStates[accountId]
            .activeCollateralTypes = positionInfo.activeCollateralTypes;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getGlobalCollateralTypes.selector
            )
        );
        assert(success);
        positionInfo.globalCollateralTypes = abi.decode(
            returnData,
            (uint128[])
        );
        states[callNum].globalCollateralTypes = positionInfo
            .globalCollateralTypes;

        if (
            states[callNum].actorStates[accountId].wethMarket.positionSize != 0
        ) {
            states[callNum]
                .actorStates[accountId]
                .wethMarket
                .maxLiquidatableAmount = getMaxLiquidatableAmount(
                1,
                states[callNum].actorStates[accountId].wethMarket.positionSize
            );
        }
        if (
            states[callNum].actorStates[accountId].wbtcMarket.positionSize != 0
        ) {
            states[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .maxLiquidatableAmount = getMaxLiquidatableAmount(
                2,
                states[callNum].actorStates[accountId].wbtcMarket.positionSize
            );
        }

        _logPositionInfoCoverage(
            states[callNum].actorStates[accountId].wethMarket.totalPnl,
            states[callNum].actorStates[accountId].wethMarket.accruedFunding,
            states[callNum].actorStates[accountId].wethMarket.positionSize,
            states[callNum].actorStates[accountId].wethMarket.owedInterest,
            states[callNum].actorStates[accountId].wbtcMarket.totalPnl,
            states[callNum].actorStates[accountId].wbtcMarket.accruedFunding,
            states[callNum].actorStates[accountId].wbtcMarket.positionSize,
            states[callNum].actorStates[accountId].wbtcMarket.owedInterest
        );
    }

    function getMaxLiquidatableAmount(
        uint128 marketId,
        int128 positionSize
    ) private returns (uint128) {
        if (positionSize < 0) {
            positionSize = positionSize * -1;
        }
        uint128 absPositionSize = uint128(positionSize);
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getMaxLiquidatableAmount.selector,
                marketId,
                positionSize
            )
        );
        assert(success);
        return abi.decode(returnData, (uint128));
    }

    struct OpenPositionInfo {
        int256 totalPnl;
        int256 accruedFunding;
        int128 positionSize;
        uint256 owedInterest;
    }

    function getOpenPosition(
        uint8 callNum,
        uint128 accountId,
        uint256 marketId
    ) private {
        OpenPositionInfo memory openPositionInfo;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getOpenPosition.selector,
                accountId,
                marketId
            )
        );
        assert(success);
        (
            openPositionInfo.totalPnl,
            openPositionInfo.accruedFunding,
            openPositionInfo.positionSize,
            openPositionInfo.owedInterest
        ) = abi.decode(returnData, (int256, int256, int128, uint256));

        console2.log("Debug position size", openPositionInfo.positionSize);

        if (marketId == 1) {
            states[callNum]
                .actorStates[accountId]
                .wethMarket
                .totalPnl = openPositionInfo.totalPnl;
            states[callNum]
                .actorStates[accountId]
                .wethMarket
                .accruedFunding = openPositionInfo.accruedFunding;
            states[callNum]
                .actorStates[accountId]
                .wethMarket
                .positionSize = openPositionInfo.positionSize;
            states[callNum]
                .actorStates[accountId]
                .wethMarket
                .owedInterest = openPositionInfo.owedInterest;
        } else if (marketId == 2) {
            states[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .totalPnl = openPositionInfo.totalPnl;
            states[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .accruedFunding = openPositionInfo.accruedFunding;
            states[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .positionSize = openPositionInfo.positionSize;
            states[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .owedInterest = openPositionInfo.owedInterest;
        }
    }

    function getMarketInfo(uint8 callNum) private {
        getLiquidationCapacity(callNum, 1);
        getLiquidationCapacity(callNum, 2);
        getLiquidationCapacity(callNum, 3);
        getMarketSize(callNum, 1);
        getMarketSize(callNum, 2);
        getMarketSize(callNum, 3);
        getMarketSkew(callNum, 1);
        getMarketSkew(callNum, 2);
        getMarketSkew(callNum, 3);

        _logMarketInfoCoverage(
            states[callNum].wethMarket.liquidationCapacity,
            states[callNum].wbtcMarket.liquidationCapacity,
            states[callNum].wethMarket.marketSize,
            states[callNum].wbtcMarket.marketSize
        );
    }
    struct LiquidationCapacityInfo {
        uint256 capacity;
        uint256 maxLiquidationInWindow;
        uint256 latestLiquidationTimestamp;
    }

    function getLiquidationCapacity(uint8 callNum, uint256 marketId) private {
        LiquidationCapacityInfo memory liquidationCapacityInfo;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.liquidationCapacity.selector,
                marketId
            )
        );
        assert(success);
        (
            liquidationCapacityInfo.capacity,
            liquidationCapacityInfo.maxLiquidationInWindow,
            liquidationCapacityInfo.latestLiquidationTimestamp
        ) = abi.decode(returnData, (uint256, uint256, uint256));

        if (marketId == 1) {
            states[callNum]
                .wethMarket
                .liquidationCapacity = liquidationCapacityInfo.capacity;
        } else if (marketId == 2) {
            states[callNum]
                .wbtcMarket
                .liquidationCapacity = liquidationCapacityInfo.capacity;
        }
    }

    function getMarketSize(uint8 callNum, uint256 marketId) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsMarketModuleImpl.size.selector,
                marketId
            )
        );
        assert(success);
        uint256 marketSize = abi.decode(returnData, (uint256));

        if (marketId == 1) {
            states[callNum].wethMarket.marketSize = marketSize;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.marketSize = marketSize;
        }
    }
    function getMarketSkew(uint8 callNum, uint256 marketId) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsMarketModuleImpl.skew.selector,
                marketId
            )
        );
        assert(success);
        int256 skew = abi.decode(returnData, (int256));

        if (marketId == 1) {
            states[callNum].wethMarket.skew = skew;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.skew = skew;
        } else if (marketId == 3) {
            states[callNum].hugeMarket.skew = skew;
        }
    }
    function getGlobalCollateralValues(uint8 callNum) private {
        getGlobalCollateralValue(callNum, 0);
        getGlobalCollateralValue(callNum, 1);
        getGlobalCollateralValue(callNum, 2);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                globalPerpsMarketModuleImpl.totalGlobalCollateralValue.selector
            )
        );
        assert(success);
        uint256 totalCollateralValue = abi.decode(returnData, (uint256));
        states[callNum].totalCollateralValueUsd = totalCollateralValue;

        _logGlobalCollateralValuesCoverage(
            states[callNum].depositedSusdCollateral,
            states[callNum].depositedWethCollateral,
            states[callNum].depositedWbtcCollateral,
            // states[callNum].depositedHUGECollateral,
            states[callNum].totalCollateralValueUsd,
            states[callNum].totalCollateralValueUsdGhost,
            states[callNum].skew
        );
    }

    function getGlobalCollateralValue(
        uint8 callNum,
        uint256 collateralId
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                globalPerpsMarketModuleImpl.globalCollateralValue.selector,
                collateralId
            )
        );
        assert(success);
        uint256 collateralValue = abi.decode(returnData, (uint256));
        if (collateralId == 0) {
            states[callNum].depositedSusdCollateral = collateralValue;
        } else if (collateralId == 1) {
            states[callNum].depositedWethCollateral = collateralValue;
        } else if (collateralId == 2) {
            states[callNum].depositedWbtcCollateral = collateralValue;
        }
    }

    function calculateTotalCollateralValueGhost(uint8 callNum) private {
        uint256 totalCollateralValueUsdGhost = 0;
        for (uint256 i = 0; i < USERS.length; i++) {
            uint128 accountId = userToAccountIds[USERS[i]];
            uint256 accountCollateralValue = calculateCollateralValueForAccount(
                callNum,
                accountId
            );
            totalCollateralValueUsdGhost += accountCollateralValue;
            console2.log(">>>BEFOREAFTER:Call num:", callNum);
            console2.log(">>>BEFOREAFTER:Account:", accountId);
            console2.log(
                ">>>BEFOREAFTER:Collateral value:",
                accountCollateralValue
            );
        }
        states[callNum]
            .totalCollateralValueUsdGhost = totalCollateralValueUsdGhost;
        console2.log(
            "calculateTotalCollateralValueGhost::totalCollateralValueUsdGhost",
            states[callNum].totalCollateralValueUsdGhost
        );
        console2.log(
            "comparing with totalCollateralValue of system report::totalCollateralValueUsd",
            states[callNum].totalCollateralValueUsd
        );
    }

    function calculateCollateralValueForAccount(
        uint8 callNum,
        uint128 accountId
    ) private view returns (uint256) {
        uint256 totalValue = 0;
        totalValue += calculateCollateralValueForToken(
            callNum,
            accountId,
            0,
            1e18
        );
        console2.log(
            "CALCCOLLVALUE0:",
            calculateCollateralValueForToken(callNum, accountId, 0, 1e18)
        );
        totalValue += calculateCollateralValueForToken(
            callNum,
            accountId,
            1,
            mockOracleManager.process(WETH_ORACLE_NODE_ID).price
        );
        console2.log(
            "CALCCOLLVALUE1NEW:",
            calculateCollateralValueForToken(
                callNum,
                accountId,
                1,
                mockOracleManager.process(WETH_ORACLE_NODE_ID).price
            )
        );
        console2.log("BenchmarkPrice1:");
        console2.logInt(pythWrapper.getBenchmarkPrice(WETH_FEED_ID, 0));
        totalValue += calculateCollateralValueForToken(
            callNum,
            accountId,
            2,
            mockOracleManager.process(WBTC_ORACLE_NODE_ID).price
        );
        console2.log(
            "CALCCOLLVALUE2NEW:",
            calculateCollateralValueForToken(
                callNum,
                accountId,
                2,
                mockOracleManager.process(WBTC_ORACLE_NODE_ID).price
            )
        );

        return totalValue;
    }

    function calculateCollateralValueForToken(
        uint8 callNum,
        uint128 accountId,
        uint256 collateralId,
        int256 price
    ) private view returns (uint256) {
        uint256 amount;
        if (collateralId == 0) {
            amount = states[callNum]
                .actorStates[accountId]
                .collateralAmountSUSD;
        } else if (collateralId == 1) {
            amount = states[callNum]
                .actorStates[accountId]
                .collateralAmountWETH;
        } else if (collateralId == 2) {
            amount = states[callNum]
                .actorStates[accountId]
                .collateralAmountWBTC;
        }
        return (uint256(price) * amount) / 1e18;
    }

    function calculateCollateralValueForEveryToken(uint8 callNum) private {
        states[callNum]
            .collateralValueAllUsersSUSDCalculated = calculateCollateralValueForTokenAllUsers(
            callNum,
            0
        );
        states[callNum]
            .collateralValueAllUsersWETHCalculated = calculateCollateralValueForTokenAllUsers(
            callNum,
            1
        );
        states[callNum]
            .collateralValueAllUsersWBTCCalculated = calculateCollateralValueForTokenAllUsers(
            callNum,
            2
        );
    }

    function calculateCollateralValueForTokenAllUsers(
        uint8 callNum,
        uint128 collateralId
    ) private returns (int256) {
        int256 collateralValueForTokenGhost = 0;

        for (uint256 i = 0; i < USERS.length; i++) {
            uint128 accountId = userToAccountIds[USERS[i]];

            if (collateralId == 0) {
                collateralValueForTokenGhost += int256(
                    states[callNum].actorStates[accountId].collateralAmountSUSD
                );
            } else if (collateralId == 1) {
                collateralValueForTokenGhost += int256(
                    states[callNum].actorStates[accountId].collateralAmountWETH
                );
            } else if (collateralId == 2) {
                collateralValueForTokenGhost += int256(
                    states[callNum].actorStates[accountId].collateralAmountWBTC
                );
            }

            console2.log(
                "collateralValueForTokenGhost",
                collateralValueForTokenGhost
            );
        }
        return collateralValueForTokenGhost;
    }

    function getUtilizationInfo(uint8 callNum) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.minimumCredit.selector,
                1
            )
        );
        assert(success);
        states[callNum].minimumCredit = abi.decode(returnData, (uint256));

        (success, returnData) = perps.staticcall(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.utilizationRate.selector
            )
        );
        assert(success);
        (uint256 rate, uint256 delegatedCollateral, uint256 lockedCredit) = abi
            .decode(returnData, (uint256, uint256, uint256));

        states[callNum].utilizationRate = rate;
        states[callNum].delegatedCollateral = delegatedCollateral;
        states[callNum].lockedCredit = lockedCredit;

        _logUtilizationInfoCoverage(
            states[callNum].minimumCredit,
            states[callNum].utilizationRate,
            states[callNum].delegatedCollateral,
            states[callNum].lockedCredit
        );
    }

    function getMarginInfo(uint8 callNum, uint128 accountId) private {
        // Get available margin
        (bool success, bytes memory returnData) = perps.staticcall(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getAvailableMargin.selector,
                accountId
            )
        );
        assert(success);
        int256 availableMargin = abi.decode(returnData, (int256));
        states[callNum]
            .actorStates[accountId]
            .availableMargin = availableMargin;

        // Get required margins and max liquidation reward
        (success, returnData) = perps.staticcall(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getRequiredMargins.selector,
                accountId
            )
        );
        assert(success);
        (
            uint256 requiredInitialMargin,
            uint256 requiredMaintenanceMargin,
            uint256 maxLiquidationReward
        ) = abi.decode(returnData, (uint256, uint256, uint256));

        states[callNum]
            .actorStates[accountId]
            .requiredInitialMargin = requiredInitialMargin;
        states[callNum]
            .actorStates[accountId]
            .requiredMaintenanceMargin = requiredMaintenanceMargin;
        states[callNum]
            .actorStates[accountId]
            .maxLiquidationReward = maxLiquidationReward;

        _logMarginInfoCoverage(
            states[callNum].actorStates[accountId].availableMargin,
            states[callNum].actorStates[accountId].requiredInitialMargin,
            states[callNum].actorStates[accountId].requiredMaintenanceMargin,
            states[callNum].actorStates[accountId].maxLiquidationReward
        );
    }

    struct ReportedDebtInfo {
        uint128 accountId;
        int256 collateralValueUsd;
        int256 pricePnL;
        int256 pendingFunding;
        int256 debtUsd;
        uint256 positionSizeSum;
        int256 userReportedDebt;
        int256 reportedDebtGhost;
    }

    function calculateReportedDebtComparison(uint8 callNum) private {
        ReportedDebtInfo memory info;
        info.reportedDebtGhost = 0;

        for (uint256 i = 0; i < USERS.length; i++) {
            info.accountId = userToAccountIds[USERS[i]];
            (
                info.collateralValueUsd,
                info.pricePnL,
                info.pendingFunding,
                info.debtUsd,
                info.positionSizeSum
            ) = getAccountValues(callNum, info.accountId); //sum markets

            if (callNum > 0) {
                console2.log("USERS.length, info.accountId", info.accountId);
                console2.log("collateralValueUsd", info.collateralValueUsd);
                console2.log("pricePnL", info.pricePnL);
                console2.log("pendingFunding", info.pendingFunding);
                console2.log("debtUsd", info.debtUsd);
                console2.log("positionSizeSum", info.positionSizeSum);
            }

            console2.log("User", i);
            console2.log("userReportedDebt before", info.userReportedDebt);
            info.userReportedDebt = (info.collateralValueUsd +
                info.pricePnL +
                info.pendingFunding -
                info.debtUsd); // need to subtract debt
            console2.log("userReportedDebt after", info.userReportedDebt);
            console2.log("reportedDebtGhost before", info.reportedDebtGhost);
            info.reportedDebtGhost += info.userReportedDebt;
            console2.log("reportedDebtGhost after", info.reportedDebtGhost);
        }
        if (info.reportedDebtGhost < 0) info.reportedDebtGhost = 0;

        states[callNum].reportedDebtGhost = uint256(info.reportedDebtGhost);
    }

    function getPositionData(
        uint128 accountId,
        uint128 marketId
    )
        private
        returns (
            uint256, //notionalValue,
            int256, //totalPnl
            int256, //pricePnl
            uint256, //chargedInterest
            int256, //accruedFunding
            int256, //netFundingPerUnit
            int256, //nextFunding
            int128 //positionSize
        )
    {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getPositionData.selector,
                accountId,
                marketId
            )
        );
        assert(success);

        return
            abi.decode(
                returnData,
                (
                    uint256,
                    int256,
                    int256,
                    uint256,
                    int256,
                    int256,
                    int256,
                    int128
                )
            );
    }

    struct AccountValuesInfo {
        uint128 accountId;
        int256 pricePnL;
        int256 pendingFunding;
        uint256 positionSizeSum;
    }

    function getAccountValues(
        uint8 callNum,
        uint128 accountId
    ) private returns (int256, int256, int256, int256, uint256) {
        AccountValuesInfo memory info;
        info.accountId = accountId;

        int256 collateralValueUsd = getCollateralValue(info.accountId);
        (
            info.pricePnL,
            info.pendingFunding,
            info.positionSizeSum
        ) = getPositionValues(callNum, info.accountId);
        int256 debtUsd = getDebtValue(info.accountId);

        return (
            collateralValueUsd,
            info.pricePnL,
            info.pendingFunding,
            debtUsd,
            info.positionSizeSum
        );
    }

    struct PositionValuesInfo {
        uint128 accountId;
        int256 pricePnL;
        int256 pendingFunding;
        uint256 positionSizeSum;
    }

    function getCollateralValue(uint128 accountId) private returns (int256) {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.totalCollateralValue.selector,
                accountId
            )
        );
        assert(success);
        return int256(abi.decode(returnData, (uint256)));
    }

    function getPositionValues(
        uint8 callNum,
        uint128 accountId
    ) private returns (int256, int256, uint256) {
        PositionValuesInfo memory info;
        info.accountId = accountId;
        info.pricePnL = 0;
        info.pendingFunding = 0;
        info.positionSizeSum = 0;

        for (uint128 marketId = 1; marketId <= 2; marketId++) {
            (, int256 accruedFunding, int128 positionSize, ) = getOpenPosition(
                info.accountId,
                marketId
            );
            (, , int256 pricePnLReturned, , , , , ) = getPositionData(
                info.accountId,
                marketId
            );
            if (callNum > 0) {
                logPositionDetails(info.pricePnL, accruedFunding, positionSize);
            }
            info.pricePnL += pricePnLReturned;
            info.pendingFunding += accruedFunding;
            info.positionSizeSum += uint256(MathUtil.abs(positionSize));
        }
        console2.log("getPositionValues::pricePnL TOTAL", info.pricePnL);

        return (info.pricePnL, info.pendingFunding, info.positionSizeSum);
    }

    function getOpenPosition(
        uint128 accountId,
        uint128 marketId
    ) private returns (int256, int256, int128, uint256) {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getOpenPosition.selector,
                accountId,
                marketId
            )
        );
        assert(success);
        return abi.decode(returnData, (int256, int256, int128, uint256));
    }

    function logPositionDetails(
        int256 totalPnl,
        int256 accruedFunding,
        int128 positionSize
    ) private {
        console2.log("totalPnl", totalPnl);
        console2.log("accruedFunding", accruedFunding);
        console2.log("positionSize", positionSize);
    }

    function getDebtValue(uint128 accountId) private returns (int256) {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.debt.selector,
                accountId
            )
        );
        assert(success);
        return abi.decode(returnData, (int256));
    }

    struct DebtInfo {
        uint128 accountId;
        int256 accountDebt;
    }

    function calculateTotalAccountsDebt(uint8 callNum) private {
        DebtInfo memory info;
        for (uint256 i = 0; i < USERS.length; i++) {
            info.accountId = userToAccountIds[USERS[i]];
            (, , , info.accountDebt, ) = getAccountValues(
                callNum,
                info.accountId
            );
            states[callNum].totalDebtCalculated += info.accountDebt;
        }
    }

    function getGlobalDebt(uint8 callNum) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getGlobalTotalAccountsDebt.selector
            )
        );
        assert(success);
        states[callNum].totalDebt = abi.decode(returnData, (int256));
    }

    function getMarketDebt(uint8 callNum) private {
        getReportedDebt(callNum, 1);
        getReportedDebt(callNum, 2);
        getMarketDebtCorrectionAccumulator(callNum, 1);
        getMarketDebtCorrectionAccumulator(callNum, 2);
    }

    function getReportedDebt(uint8 callNum, uint128 marketId) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.reportedDebt.selector,
                marketId
            )
        );
        assert(success);

        if (marketId == 1) {
            states[callNum].wethMarket.reportedDebt = abi.decode(
                returnData,
                (uint256)
            );
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.reportedDebt = abi.decode(
                returnData,
                (uint256)
            );
        }
    }

    function getMarketDebtCorrectionAccumulator(
        uint8 callNum,
        uint128 marketId
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getDebtCorrectionAccumulator.selector,
                marketId
            )
        );
        assert(success);

        if (marketId == 1) {
            states[callNum].wethMarket.debtCorrectionAccumulator = abi.decode(
                returnData,
                (uint256)
            );
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.debtCorrectionAccumulator = abi.decode(
                returnData,
                (uint256)
            );
        }
    }

    function checkIfAccountLiquidatable(
        uint8 callNum,
        uint128 accountId
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.isAccountLiquidatable.selector,
                accountId
            )
        );
        assert(success);
        states[callNum].actorStates[accountId].isAccountLiquidatable = abi
            .decode(returnData, (bool));
    }

    // struct PositionInfo {
    //     int256 totalPnl;
    //     int256 accruedFunding;
    //     int128 positionSize;
    //     uint256 owedInterest;
    // }

    // function _checkIfPositionWasProifitable(
    //     uint8 callNum,
    //     uint128 accountId,
    //     uint128 marketId
    // ) internal {
    //     console2.log("checkIfPositionWasProifitable::accountId", accountId);
    //     console2.log("checkIfPositionWasProifitable::marketId", marketId);

    //     PositionInfo memory info;
    //     bool isPositionClosed;

    //     console2.log("marketId", marketId);
    //     console2.log("accountId", accountId);

    //     (bool success, bytes memory returnData) = perps.call(
    //         abi.encodeWithSelector(
    //             perpsAccountModuleImpl.getOpenPosition.selector,
    //             accountId,
    //             marketId
    //         )
    //     );
    //     assert(success);
    //     (
    //         info.totalPnl,
    //         info.accruedFunding,
    //         info.positionSize,
    //         info.owedInterest
    //     ) = abi.decode(returnData, (int256, int256, int128, uint256));

    //     if (marketId == 1) {
    //         _handleWETHMarket(callNum, accountId, info, isPositionClosed);
    //     } else if (marketId == 2) {
    //         _handleWBTCMarket(callNum, accountId, info, isPositionClosed);
    //     } else {
    //         console2.log("Invalid marketId", marketId);
    //         revert("Invalid marketId");
    //     }
    //     console2.log(
    //         "checkIfPositionWasProifitable::isPreviousPositionInLoss",
    //         positionStates[callNum]
    //             .actorStates[accountId]
    //             .isPreviousPositionInLoss
    //     );

    //     console2.log(
    //         "checkIfPositionWasProifitable::isPreviousTradePositionInLoss",
    //         positionStates[callNum]
    //             .actorStates[accountId]
    //             .isPreviousTradePositionInLoss
    //     );
    //     console2.log(
    //         "checkIfPositionWasProifitable::previousTradePositionPnl",
    //         positionStates[callNum]
    //             .actorStates[accountId]
    //             .previousTradePositionPnl
    //     );

    //     positionStates[callNum].actorStates[accountId].latestPositionPnl = info
    //         .totalPnl;
    //     console2.log(
    //         "checkIfPositionWasProifitable::latestPositionPnl",
    //         positionStates[callNum].actorStates[accountId].latestPositionPnl
    //     );
    // }

    // function _handleWETHMarket(
    //     uint8 callNum,
    //     uint128 accountId,
    //     PositionInfo memory info,
    //     bool isPositionClosed
    // ) private {
    //     console2.log("Market: WETH");

    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .previousTradePositionPnl = positionStates[callNum]
    //         .actorStates[accountId]
    //         .wethMarket
    //         .totalPnl;

    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .wethMarket
    //         .totalPnl = info.totalPnl;

    //     console2.log(
    //         "totalPnl (WETH)",
    //         positionStates[callNum].actorStates[accountId].wethMarket.totalPnl
    //     );

    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .wethMarket
    //         .positionSize = info.positionSize;

    //     isPositionClosed = info.positionSize == 0;
    //     console2.log("isPositionClosed (WETH)", isPositionClosed);
    //     console2.log(
    //         "Current positionSize (WETH)",
    //         positionStates[callNum]
    //             .actorStates[accountId]
    //             .wethMarket
    //             .positionSize
    //     );
    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .isPreviousPositionInLoss = info.totalPnl < 0;

    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .isPreviousTradePositionInLoss =
    //         positionStates[callNum]
    //             .actorStates[accountId]
    //             .previousTradePositionPnl <
    //         0;
    // }

    // function _handleWBTCMarket(
    //     uint8 callNum,
    //     uint128 accountId,
    //     PositionInfo memory info,
    //     bool isPositionClosed
    // ) private {
    //     console2.log("Market: WBTC");

    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .previousTradePositionPnl = positionStates[callNum]
    //         .actorStates[accountId]
    //         .wbtcMarket
    //         .totalPnl;

    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .wbtcMarket
    //         .totalPnl = info.totalPnl;
    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .wbtcMarket
    //         .positionSize = info.positionSize;

    //     console2.log(
    //         "totalPnl (WBTC)",
    //         positionStates[callNum].actorStates[accountId].wbtcMarket.totalPnl
    //     );

    //     isPositionClosed = info.positionSize == 0;

    //     console2.log(
    //         "Current positionSize (WBTC)",
    //         positionStates[callNum]
    //             .actorStates[accountId]
    //             .wbtcMarket
    //             .positionSize
    //     );

    //     console2.log("isPositionClosed (WBTC)", isPositionClosed);
    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .isPreviousPositionInLoss = info.totalPnl < 0;

    //     positionStates[callNum]
    //         .actorStates[accountId]
    //         .isPreviousTradePositionInLoss =
    //         positionStates[callNum]
    //             .actorStates[accountId]
    //             .previousTradePositionPnl <
    //         0;
    // }
    function debugBefore(address[] memory actors) internal {
        debugState(0, actors);
    }

    function debugAfter(address[] memory actors) internal {
        debugState(1, actors);
    }

    function debugState(uint8 callNum, address[] memory actors) internal {
        for (uint256 i = 0; i < actors.length; i++) {
            debugActorState(callNum, actors[i]);
        }
    }

    function debugActorState(uint8 callNum, address actor) internal {
        fl.log("Actor: ", actor);
    }
}
