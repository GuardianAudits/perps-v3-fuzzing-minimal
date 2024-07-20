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
    struct PositionVars {
        // Position.Data position; getting separately instead
        int256 totalPnl;
        int256 accruedFunding;
        int128 positionSize;
        uint256 owedInterest;
    }

    struct MarketVars {
        uint128 marketSize;
        uint256 liquidationCapacity;
        uint128 marketSkew;
    }

    struct State {
        // account => actorStates
        mapping(uint128 => ActorStates) actorStates;
        MarketVars wethMarket;
        MarketVars wbtcMarket;
        uint256 depositedSusdCollateral;
        uint256 depositedWethCollateral;
        uint256 depositedWbtcCollateral;
        int256 totalCollateralValueUsd;
        uint256 marketSizeGhost;
        uint256 delegatedCollateralValueUsd; //get with lens
        uint128 currentUtilizationAccruedComputed; //get with lens
        uint256 utilizationRate; //perpsMarketFactoryModuleImpl.utilizationRate
        uint256 delegatedCollateral; //perpsMarketFactoryModuleImpl.utilizationRate
        uint256 lockedCredit; //perpsMarketFactoryModuleImpl.utilizationRate
        int256 reportedDebt;
        int256 reportedDebtGhost;
        int256 totalCollateralValueUsdGhost;
        uint256 minimumCredit;
        int128 skew;
    }

    struct ActorStates {
        bool isPositionLiquidatable;
        bool isPositionLiquidatablePassing;
        bool isMarginLiquidatable;
        uint128 debt;
        uint256[] collateralIds; //perpsAccountModuleImpl.getAccountCollateralIds
        uint256 collateralAmountSUSD; //perpsAccountModuleImpl.getCollateralAmount
        uint256 collateralAmountWETH; //perpsAccountModuleImpl.getCollateralAmount
        uint256 collateralAmountWBTC; //perpsAccountModuleImpl.getCollateralAmount
        uint256 totalCollateralValue; //perpsAccountModuleImpl.totalCollateralValue
        int128 sizeDelta;
        bool isOrderExpired;
        uint256 fillPriceWETH;
        uint256 fillPriceWBTC;
        uint256 sUSDBalance;
        int256 availableMargin; //perpsAccountModuleImpl.getAvailableMargin
        uint256 requiredInitialMargin; //perpsAccountModuleImpl.getRequiredMargins
        uint256 requiredMaintenanceMargin; //perpsAccountModuleImpl.getRequiredMargins
        uint256 marginKeeperFee; //perpsAccountModuleImpl.getRequiredMargins
        uint256 depositedWethCollateral;
        uint256 depositedSusdCollateral;
        PositionVars wethMarket; //TODO:rename to position
        PositionVars wbtcMarket;
    }

    struct StackCache {
        uint256 capacity;
        uint256 maxLiquidationInWindow;
        uint256 latestLiquidationTimestamp;
        int256 totalPnl;
        int256 accruedFunding;
        int128 positionSize;
        uint256 owedInterest;
        int128 skew;
        uint128 marketSkew;
        uint128 marketSize;
        uint256 rate;
        uint256 delegatedCollateral;
        uint256 lockedCredit;
        int256 availableMargin;
        uint256 requiredInitialMargin;
        uint256 requiredMaintenanceMargin;
        uint256 maxLiquidationReward;
        bool isOrderExpired;
        address collateralToken;
        int256 amount;
        bytes32 nodeId;
        int256 price;
        int256 value;
        int256 totalCollateralValueUsdGhost;
        uint128 accountId;
        int256 collateralValueUsd;
        int256 pricePnL;
        int256 pendingFunding;
        int256 debtUsd;
        int256 reportedDebtGhost;
        uint256 marketSizeGhost;
        int256 userReportedDebt;
        uint256 fillPriceWETH;
        uint256 fillPriceWBTC;
        uint256 orderFeesWBTC;
        uint256 orderFeesWETH;
        uint256 positionSizeSum;
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
    function _setStates(uint8 callNum, address[] memory actors) internal {
        for (uint256 i = 0; i < ACCOUNTS.length; i++) {
            _setActorState(callNum, ACCOUNTS[i], accountIdToUser[ACCOUNTS[i]]);
        }

        // Set states here that are independent from actors
    }
    function _setActorState(uint8 callNum, uint128 accountId, address actor) internal {
        console2.log("===== BeforeAfter::_setActorState START ===== ");
        StackCache memory cache;

        resetGhostVariables(callNum);
        getLiquidationValues(callNum, accountId, cache);
        getCollateralInfo(callNum, accountId, cache);
        getOrderInfo(callNum, accountId, cache);
        getPositionInfo(callNum, accountId, cache);
        getMarketInfo(callNum, cache);
        getGlobalCollateralValues(callNum, cache);
        calculateTotalCollateralValueGhost(callNum, cache);
        getUtilizationInfo(callNum, cache);
        getMarginInfo(callNum, accountId, cache);
        calculateReportedDebtGhost(callNum, cache);

        console2.log("===== BeforeAfter::_setActorState END ===== ");
    }

    function resetGhostVariables(uint8 callNum) private {
        states[callNum].totalCollateralValueUsdGhost = 0;
        states[callNum].reportedDebtGhost = 0;
        states[callNum].marketSizeGhost = 0;
    }

    function getLiquidationValues(
        uint8 callNum,
        uint128 accountId,
        StackCache memory cache
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.canLiquidate.selector, accountId)
        );
        states[callNum].actorStates[accountId].isPositionLiquidatablePassing = success;
        fl.log("SUCC VALUE:", success);
        fl.log("ACCOUNT ID:", accountId);
        fl.log("CALL NUM:", callNum);
        // fl.t(false, "!passing success");
        states[callNum].actorStates[accountId].isPositionLiquidatable = abi.decode(
            returnData,
            (bool)
        );

        (success, returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.canLiquidateMarginOnly.selector, accountId)
        );
        assert(success);
        states[callNum].actorStates[accountId].isMarginLiquidatable = abi.decode(
            returnData,
            (bool)
        );

        _logLiquidatableCoverage(
            states[callNum].actorStates[accountId].isPositionLiquidatable,
            states[callNum].actorStates[accountId].isMarginLiquidatable
        );
    }

    function getCollateralInfo(uint8 callNum, uint128 accountId, StackCache memory cache) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getAccountCollateralIds.selector,
                accountId
            )
        );
        assert(success);
        states[callNum].actorStates[accountId].collateralIds = abi.decode(returnData, (uint256[]));

        getCollateralAmount(callNum, accountId, 0, cache);
        getCollateralAmount(callNum, accountId, 1, cache);
        getCollateralAmount(callNum, accountId, 2, cache);

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.totalCollateralValue.selector, accountId)
        );
        assert(success);
        states[callNum].actorStates[accountId].totalCollateralValue = abi.decode(
            returnData,
            (uint256)
        );

        // Coverage check at the end
        _logCollateralIdsCoverage(
            states[callNum].actorStates[accountId].collateralIds // from map
        );

        // Additional coverage for collateral amounts and total value
        _logCollateralAmountsCoverage(
            states[callNum].actorStates[accountId].collateralAmountSUSD, // from map
            states[callNum].actorStates[accountId].collateralAmountWETH, // from map
            states[callNum].actorStates[accountId].collateralAmountWBTC, // from map
            states[callNum].actorStates[accountId].totalCollateralValue // from map
        );
    }

    function getCollateralAmount(
        uint8 callNum,
        uint128 accountId,
        uint256 collateralId,
        StackCache memory cache
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
            states[callNum].actorStates[accountId].collateralAmountSUSD = amount;
        } else if (collateralId == 1) {
            states[callNum].actorStates[accountId].collateralAmountWETH = amount;
        } else if (collateralId == 2) {
            states[callNum].actorStates[accountId].collateralAmountWBTC = amount;
        }
    }

    function getOrderInfo(uint8 callNum, uint128 accountId, StackCache memory cache) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.debt.selector, accountId)
        );
        assert(success);
        states[callNum].actorStates[accountId].debt = abi.decode(returnData, (uint128));

        (success, returnData) = perps.call(
            abi.encodeWithSelector(asyncOrderModuleImpl.getOrder.selector, accountId)
        );
        assert(success);
        AsyncOrder.Data memory order = abi.decode(returnData, (AsyncOrder.Data));
        states[callNum].actorStates[accountId].sizeDelta = order.request.sizeDelta;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(mockLensModuleImpl.isOrderExpired.selector, accountId)
        );
        assert(success);
        cache.isOrderExpired = abi.decode(returnData, (bool));
        states[callNum].actorStates[accountId].isOrderExpired = cache.isOrderExpired;

        getOrderFees(callNum, accountId, 1, WETH_PYTH_PRICE_FEED_ID, cache);
        getOrderFees(callNum, accountId, 2, WBTC_PYTH_PRICE_FEED_ID, cache);

        states[callNum].actorStates[accountId].sUSDBalance = sUSDTokenMock.balanceOf(
            accountIdToUser[accountId]
        );

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
        bytes32 priceFeedId,
        StackCache memory cache
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderModuleImpl.computeOrderFeesWithPrice.selector,
                marketId,
                states[callNum].actorStates[accountId].sizeDelta,
                pythWrapper.getBenchmarkPrice(priceFeedId, 0)
            )
        );
        assert(success);
        (uint256 orderFees, uint256 fillPrice) = abi.decode(returnData, (uint256, uint256));
        if (marketId == 1) {
            states[callNum].actorStates[accountId].fillPriceWETH = fillPrice;
        } else if (marketId == 2) {
            states[callNum].actorStates[accountId].fillPriceWBTC = fillPrice;
        }
    }

    function getPositionInfo(uint8 callNum, uint128 accountId, StackCache memory cache) private {
        getOpenPosition(callNum, accountId, 1, cache);
        getOpenPosition(callNum, accountId, 2, cache);
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

    function getOpenPosition(
        uint8 callNum,
        uint128 accountId,
        uint256 marketId,
        StackCache memory cache
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getOpenPosition.selector,
                accountId,
                marketId
            )
        );
        assert(success);
        (cache.totalPnl, cache.accruedFunding, cache.positionSize, cache.owedInterest) = abi.decode(
            returnData,
            (int256, int256, int128, uint256)
        );
        if (marketId == 1) {
            states[callNum].actorStates[accountId].wethMarket.totalPnl = cache.totalPnl;
            states[callNum].actorStates[accountId].wethMarket.accruedFunding = cache.accruedFunding;
            states[callNum].actorStates[accountId].wethMarket.positionSize = cache.positionSize;
            states[callNum].actorStates[accountId].wethMarket.owedInterest = cache.owedInterest;
        } else if (marketId == 2) {
            states[callNum].actorStates[accountId].wbtcMarket.totalPnl = cache.totalPnl;
            states[callNum].actorStates[accountId].wbtcMarket.accruedFunding = cache.accruedFunding;
            states[callNum].actorStates[accountId].wbtcMarket.positionSize = cache.positionSize;
            states[callNum].actorStates[accountId].wbtcMarket.owedInterest = cache.owedInterest;
        }
    }

    function getMarketInfo(uint8 callNum, StackCache memory cache) private {
        getLiquidationCapacity(callNum, 1, cache);
        getLiquidationCapacity(callNum, 2, cache);

        getMarketSize(callNum, 1, cache);
        getMarketSize(callNum, 2, cache);

        _logMarketInfoCoverage(
            states[callNum].wethMarket.liquidationCapacity,
            states[callNum].wbtcMarket.liquidationCapacity,
            states[callNum].wethMarket.marketSize,
            states[callNum].wbtcMarket.marketSize
        );
    }

    function getLiquidationCapacity(
        uint8 callNum,
        uint256 marketId,
        StackCache memory cache
    ) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.liquidationCapacity.selector, marketId)
        );
        assert(success);
        (cache.capacity, cache.maxLiquidationInWindow, cache.latestLiquidationTimestamp) = abi
            .decode(returnData, (uint256, uint256, uint256));
        if (marketId == 1) {
            states[callNum].wethMarket.liquidationCapacity = cache.capacity;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.liquidationCapacity = cache.capacity;
        }
    }

    function getMarketSize(uint8 callNum, uint256 marketId, StackCache memory cache) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.size.selector, marketId)
        );
        assert(success);
        cache.marketSize = abi.decode(returnData, (uint128));
        if (marketId == 1) {
            states[callNum].wethMarket.marketSize = cache.marketSize;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.marketSize = cache.marketSize;
        }
    }

    function getGlobalCollateralValues(uint8 callNum, StackCache memory cache) private {
        getGlobalCollateralValue(callNum, 0);
        getGlobalCollateralValue(callNum, 1);
        getGlobalCollateralValue(callNum, 2);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(globalPerpsMarketModuleImpl.totalGlobalCollateralValue.selector)
        );
        assert(success);
        uint256 totalCollateralValue = abi.decode(returnData, (uint256));
        states[callNum].totalCollateralValueUsd = int256(totalCollateralValue);

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.skew.selector, 1)
        );
        assert(success);
        cache.skew = abi.decode(returnData, (int128));
        states[callNum].skew = cache.skew;

        _logGlobalCollateralValuesCoverage(
            states[callNum].depositedSusdCollateral,
            states[callNum].depositedWethCollateral,
            states[callNum].depositedWbtcCollateral,
            states[callNum].totalCollateralValueUsd,
            states[callNum].totalCollateralValueUsdGhost,
            states[callNum].skew
        );
    }

    function getGlobalCollateralValue(uint8 callNum, uint256 collateralId) private {
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

    function calculateTotalCollateralValueGhost(uint8 callNum, StackCache memory cache) private {
        cache.totalCollateralValueUsdGhost = 0;
        for (uint256 i = 0; i < USERS.length; i++) {
            cache.accountId = userToAccountIds[USERS[i]];
            cache.totalCollateralValueUsdGhost += calculateCollateralValueForAccount(
                callNum,
                cache.accountId,
                cache
            );
        }
        states[callNum].totalCollateralValueUsdGhost = cache.totalCollateralValueUsdGhost;
    }

    function calculateCollateralValueForAccount(
        uint8 callNum,
        uint128 accountId,
        StackCache memory cache
    ) private view returns (int256) {
        int256 totalValue = 0;
        totalValue += calculateCollateralValueForToken(callNum, accountId, 0, 1e18, cache);
        totalValue += calculateCollateralValueForToken(
            callNum,
            accountId,
            1,
            pythWrapper.getBenchmarkPrice(WETH_FEED_ID, 0),
            cache
        );
        totalValue += calculateCollateralValueForToken(
            callNum,
            accountId,
            2,
            pythWrapper.getBenchmarkPrice(WBTC_FEED_ID, 0),
            cache
        );
        return totalValue;
    }

    function calculateCollateralValueForToken(
        uint8 callNum,
        uint128 accountId,
        uint256 collateralId,
        int256 price,
        StackCache memory cache
    ) private view returns (int256) {
        int256 amount;
        if (collateralId == 0) {
            amount = int256(states[callNum].actorStates[accountId].collateralAmountSUSD);
        } else if (collateralId == 1) {
            amount = int256(states[callNum].actorStates[accountId].collateralAmountWETH);
        } else if (collateralId == 2) {
            amount = int256(states[callNum].actorStates[accountId].collateralAmountWBTC);
        }
        return (price * amount) / 1e18;
    }

    function getUtilizationInfo(uint8 callNum, StackCache memory cache) private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketFactoryModuleImpl.minimumCredit.selector, 1)
        );
        assert(success);
        states[callNum].minimumCredit = abi.decode(returnData, (uint256));

        (success, returnData) = perps.staticcall(
            abi.encodeWithSelector(perpsMarketFactoryModuleImpl.utilizationRate.selector)
        );
        assert(success);
        (cache.rate, cache.delegatedCollateral, cache.lockedCredit) = abi.decode(
            returnData,
            (uint256, uint256, uint256)
        );
        states[callNum].utilizationRate = cache.rate;
        states[callNum].delegatedCollateral = cache.delegatedCollateral;
        states[callNum].lockedCredit = cache.lockedCredit;

        _logUtilizationInfoCoverage(
            states[callNum].minimumCredit,
            states[callNum].utilizationRate,
            states[callNum].delegatedCollateral,
            states[callNum].lockedCredit
        );
    }

    function getMarginInfo(uint8 callNum, uint128 accountId, StackCache memory cache) private {
        (bool success, bytes memory returnData) = perps.staticcall(
            abi.encodeWithSelector(perpsAccountModuleImpl.getAvailableMargin.selector, accountId)
        );
        assert(success);
        cache.availableMargin = abi.decode(returnData, (int256));
        states[callNum].actorStates[accountId].availableMargin = cache.availableMargin;

        (success, returnData) = perps.staticcall(
            abi.encodeWithSelector(perpsAccountModuleImpl.getRequiredMargins.selector, accountId)
        );
        assert(success);
        (
            cache.requiredInitialMargin,
            cache.requiredMaintenanceMargin,
            cache.maxLiquidationReward
        ) = abi.decode(returnData, (uint256, uint256, uint256));
        states[callNum].actorStates[accountId].requiredInitialMargin = cache.requiredInitialMargin;
        states[callNum].actorStates[accountId].requiredMaintenanceMargin = cache
            .requiredMaintenanceMargin;
        states[callNum].actorStates[accountId].marginKeeperFee = cache.maxLiquidationReward;

        _logMarginInfoCoverage(
            states[callNum].actorStates[accountId].availableMargin,
            states[callNum].actorStates[accountId].requiredInitialMargin,
            states[callNum].actorStates[accountId].requiredMaintenanceMargin,
            states[callNum].actorStates[accountId].marginKeeperFee
        );
    }

    function calculateReportedDebtGhost(uint8 callNum, StackCache memory cache) private {
        cache.reportedDebtGhost = 0;
        cache.marketSizeGhost = 0;

        for (uint256 i = 0; i < USERS.length; i++) {
            cache.accountId = userToAccountIds[USERS[i]];
            (
                cache.collateralValueUsd,
                cache.pricePnL,
                cache.pendingFunding,
                cache.debtUsd,
                cache.positionSizeSum
            ) = getAccountValues(callNum, cache.accountId); //sum markets

            cache.userReportedDebt =
                (cache.collateralValueUsd + cache.pricePnL + cache.pendingFunding) -
                cache.debtUsd;
            cache.reportedDebtGhost += cache.userReportedDebt;
            cache.marketSizeGhost += cache.positionSizeSum;

            _logReportedDebtGhostCoverage(cache.reportedDebtGhost, cache.marketSizeGhost);

            emit DebugSize(
                int256(cache.positionSizeSum),
                USERS[i],
                cache.accountId,
                "Total position size"
            );
        }
        /*
        //positions.sum(p.collateralUsd + p.pricePnL + p.pendingFunding - p.pendingUtilization - p.debtUsd)";
         int256 totalDebt = collateralValue.toInt() +
                totalMarketDebt -
                globalMarket.totalAccountsDebt.toInt();

            */
        if (cache.reportedDebtGhost < 0) cache.reportedDebtGhost = 0; // Reported Debt Cannot Go Negative

        // Store the calculated values in the state
        states[callNum].reportedDebtGhost = cache.reportedDebtGhost;
        states[callNum].marketSizeGhost = cache.marketSizeGhost;

        console2.log("reportedDebtGhost", states[callNum].reportedDebtGhost);
        console2.log("marketSizeGhost", states[callNum].marketSizeGhost);
    }

    function getAccountValues(
        uint8 callNum,
        uint128 accountId
    ) private returns (int256, int256, int256, int256, uint256) {
        int256 collateralValueUsd;
        int256 pricePnL = 0;
        int256 pendingFunding = 0;
        int256 debtUsd;
        uint256 positionSizeSum = 0;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.totalCollateralValue.selector, accountId)
        );
        assert(success);
        collateralValueUsd = int256(abi.decode(returnData, (uint256)));

        for (uint128 marketId = 1; marketId <= 2; marketId++) {
            (success, returnData) = perps.call(
                abi.encodeWithSelector(
                    perpsAccountModuleImpl.getOpenPosition.selector,
                    accountId,
                    marketId
                )
            );
            assert(success);
            (int256 totalPnl, int256 accruedFunding, int128 positionSize, ) = abi.decode(
                returnData,
                (int256, int256, int128, uint256)
            );

            pricePnL += totalPnl;
            pendingFunding += accruedFunding;
            positionSizeSum += uint256(MathUtil.abs(positionSize));
        }

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.debt.selector, accountId)
        );
        assert(success);
        debtUsd = abi.decode(returnData, (int256));

        return (collateralValueUsd, pricePnL, pendingFunding, debtUsd, positionSizeSum);
    }

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
