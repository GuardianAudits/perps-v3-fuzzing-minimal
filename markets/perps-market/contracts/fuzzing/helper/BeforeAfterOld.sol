// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "../FuzzSetup.sol";
import {AsyncOrder} from "../../storage/AsyncOrder.sol";
import {MathUtil} from "../../utils/MathUtil.sol";

import {console2} from "lib/forge-std/src/Test.sol";

abstract contract BeforeAfter is FuzzSetup {
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

    event DebugBeforeAfter(string s);

    function _setActorState(uint8 callNum, uint128 accountId, address actor) internal {
        console2.log("===== BeforeAfter::_setActorState START ===== ");
        states[callNum].totalCollateralValueUsdGhost = 0; // zero the ghost variable to not continuously accumulate on it
        states[callNum].reportedDebtGhost = 0; // set previously calculated value to 0 to not affect new calculation
        states[callNum].marketSizeGhost = 0;

        StackCache memory cache;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.canLiquidate.selector, accountId)
        );
        states[callNum].actorStates[accountId].isPositionLiquidatablePassing = success;
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

        //no functionality to getLiquidationFees specifically

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getAccountCollateralIds.selector,
                accountId
            )
        );
        assert(success);
        uint256[] memory collateralIds = abi.decode(returnData, (uint256[]));

        states[callNum].actorStates[accountId].collateralIds = collateralIds;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getCollateralAmount.selector,
                accountId,
                0
            )
        );
        assert(success);
        states[callNum].actorStates[accountId].collateralAmountSUSD = abi.decode(
            returnData,
            (uint256)
        );

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getCollateralAmount.selector,
                accountId,
                1
            )
        );
        assert(success);
        states[callNum].actorStates[accountId].collateralAmountWETH = abi.decode(
            returnData,
            (uint256)
        );

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getCollateralAmount.selector,
                accountId,
                2
            )
        );
        assert(success);
        states[callNum].actorStates[accountId].collateralAmountWBTC = abi.decode(
            returnData,
            (uint256)
        );

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.totalCollateralValue.selector, accountId)
        );
        assert(success);
        uint totalCollateralValue = abi.decode(returnData, (uint256));

        states[callNum].actorStates[accountId].totalCollateralValue = totalCollateralValue;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.debt.selector, accountId)
        );
        assert(success);
        uint128 accountDebt = abi.decode(returnData, (uint128));

        states[callNum].actorStates[accountId].debt = accountDebt;

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

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderModuleImpl.computeOrderFeesWithPrice.selector,
                1, // marketId,
                states[callNum].actorStates[accountId].sizeDelta,
                pythWrapper.getBenchmarkPrice(WETH_PYTH_PRICE_FEED_ID, 0)
            )
        );
        assert(success);
        (cache.orderFeesWETH, cache.fillPriceWETH) = abi.decode(returnData, (uint256, uint256));
        states[callNum].actorStates[accountId].fillPriceWETH = cache.fillPriceWETH;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderModuleImpl.computeOrderFeesWithPrice.selector,
                2,
                states[callNum].actorStates[accountId].sizeDelta,
                pythWrapper.getBenchmarkPrice(WBTC_PYTH_PRICE_FEED_ID, 0)
            )
        );
        assert(success);
        (cache.orderFeesWBTC, cache.fillPriceWBTC) = abi.decode(returnData, (uint256, uint256));
        states[callNum].actorStates[accountId].fillPriceWBTC = cache.fillPriceWBTC;

        emit DebugBeforeAfter("BEFOREAFTER #1");

        states[callNum].actorStates[accountId].sUSDBalance = sUSDTokenMock.balanceOf(actor);
        emit DebugBeforeAfter("BEFOREAFTER #1.01");

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.getOpenPosition.selector, accountId, 1)
        );
        assert(success);
        emit DebugBeforeAfter("BEFOREAFTER #1.1");
        (cache.totalPnl, cache.accruedFunding, cache.positionSize, cache.owedInterest) = abi.decode(
            returnData,
            (int256, int256, int128, uint256)
        );
        emit DebugBeforeAfter("BEFOREAFTER #1.2");

        states[callNum].actorStates[accountId].wethMarket.totalPnl = cache.totalPnl;
        states[callNum].actorStates[accountId].wethMarket.accruedFunding = cache.accruedFunding;
        states[callNum].actorStates[accountId].wethMarket.positionSize = cache.positionSize;
        states[callNum].actorStates[accountId].wethMarket.owedInterest = cache.owedInterest;

        emit DebugBeforeAfter("BEFOREAFTER #2");

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.getOpenPosition.selector, accountId, 2)
        );
        assert(success);
        (cache.totalPnl, cache.accruedFunding, cache.positionSize, cache.owedInterest) = abi.decode(
            returnData,
            (int256, int256, int128, uint256)
        );

        states[callNum].actorStates[accountId].wbtcMarket.totalPnl = cache.totalPnl;
        states[callNum].actorStates[accountId].wbtcMarket.accruedFunding = cache.accruedFunding;
        states[callNum].actorStates[accountId].wbtcMarket.positionSize = cache.positionSize;
        states[callNum].actorStates[accountId].wbtcMarket.owedInterest = cache.owedInterest;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.liquidationCapacity.selector, 1)
        );
        assert(success);
        (cache.capacity, cache.maxLiquidationInWindow, cache.latestLiquidationTimestamp) = abi
            .decode(returnData, (uint256, uint256, uint256));

        states[callNum].wethMarket.liquidationCapacity = cache.capacity;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(liquidationModuleImpl.liquidationCapacity.selector, 2)
        );
        assert(success);
        (cache.capacity, cache.maxLiquidationInWindow, cache.latestLiquidationTimestamp) = abi
            .decode(returnData, (uint256, uint256, uint256));

        states[callNum].wbtcMarket.liquidationCapacity = cache.capacity;

        emit DebugBeforeAfter("BEFOREAFTER #3");

        (success, returnData) = perps.call(
            abi.encodeWithSelector(globalPerpsMarketModuleImpl.globalCollateralValue.selector, 0)
        );
        assert(success);
        uint256 collateralValueSUSD = abi.decode(returnData, (uint256));
        states[callNum].actorStates[accountId].depositedSusdCollateral = collateralValueSUSD;

        emit DebugBeforeAfter("BEFOREAFTER #3.1");

        (success, returnData) = perps.call(
            abi.encodeWithSelector(globalPerpsMarketModuleImpl.globalCollateralValue.selector, 1)
        );
        assert(success);
        uint256 collateralValueWETH = abi.decode(returnData, (uint256));
        states[callNum].depositedWethCollateral = collateralValueWETH;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(globalPerpsMarketModuleImpl.globalCollateralValue.selector, 2)
        );
        assert(success);

        emit DebugBeforeAfter("BEFOREAFTER #3.2");

        uint256 collateralValueWBTC = abi.decode(returnData, (uint256));
        states[callNum].depositedWbtcCollateral = collateralValueWBTC;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(globalPerpsMarketModuleImpl.totalGlobalCollateralValue.selector)
        );
        assert(success);
        totalCollateralValue = abi.decode(returnData, (uint256));
        states[callNum].totalCollateralValueUsd = int256(totalCollateralValue);

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.skew.selector, 1)
        );
        assert(success);
        cache.skew = abi.decode(returnData, (int128));
        states[callNum].skew = cache.skew;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.size.selector, 2)
        );
        assert(success);
        cache.marketSize = abi.decode(returnData, (uint128));
        states[callNum].wbtcMarket.marketSize = cache.marketSize;

        emit DebugBeforeAfter("BEFOREAFTER #3.3");

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.size.selector, 1)
        );
        assert(success);
        cache.marketSize = abi.decode(returnData, (uint128));
        states[callNum].wethMarket.marketSize = cache.marketSize;

        emit DebugBeforeAfter("BEFOREAFTER #3.4");

        (success, returnData) = perps.call(
            abi.encodeWithSelector(spot.getMarketSkewScale.selector, 1)
        );
        assert(success);
        states[callNum].wethMarket.marketSkew = abi.decode(returnData, (uint128));
        (success, returnData) = perps.call(
            abi.encodeWithSelector(spot.getMarketSkewScale.selector, 1)
        );
        assert(success);
        states[callNum].wethMarket.marketSkew = abi.decode(returnData, (uint128));

        (success, returnData) = perps.call(
            abi.encodeWithSelector(spot.getMarketSkewScale.selector, 2)
        );
        assert(success);
        states[callNum].wbtcMarket.marketSkew = abi.decode(returnData, (uint128));

        // loop through deposited collaterals and sum their value

        cache.totalCollateralValueUsdGhost = 0;

        for (uint256 i = 0; i < USERS.length; i++) {
            cache.accountId = userToAccountIds[USERS[i]];
            console2.log("cache.accountId", cache.accountId);
            // SUSD
            cache.amount = int256(
                states[callNum].actorStates[cache.accountId].collateralAmountSUSD
            );
            cache.price = 1e18; // Hardcoded price for SUSD
            cache.value = (cache.price * cache.amount) / 1e18;
            cache.totalCollateralValueUsdGhost += cache.value;
            console2.log(
                " cache.totalCollateralValueUsdGhost SUSD",
                cache.totalCollateralValueUsdGhost
            );

            // WETH
            cache.amount = int256(
                states[callNum].actorStates[cache.accountId].collateralAmountWETH
            );
            cache.price = pythWrapper.getBenchmarkPrice(WETH_FEED_ID, 0);
            cache.value = (cache.price * cache.amount) / 1e18;
            cache.totalCollateralValueUsdGhost += cache.value;
            console2.log(
                " cache.totalCollateralValueUsdGhost WETH",
                cache.totalCollateralValueUsdGhost
            );

            // WBTC
            cache.amount = int256(
                states[callNum].actorStates[cache.accountId].collateralAmountWBTC
            );
            cache.price = pythWrapper.getBenchmarkPrice(WBTC_FEED_ID, 0);
            cache.value = (cache.price * cache.amount) / 1e18;
            cache.totalCollateralValueUsdGhost += cache.value;
            console2.log(
                " cache.totalCollateralValueUsdGhost WBTC",
                cache.totalCollateralValueUsdGhost
            );
        }
        console2.log(
            "cache.totalCollateralValueUsdGhost TOTAL",
            cache.totalCollateralValueUsdGhost
        );

        // Store the calculated total in the state
        states[callNum].totalCollateralValueUsdGhost = cache.totalCollateralValueUsdGhost;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketFactoryModuleImpl.minimumCredit.selector, 1)
        );

        emit DebugBeforeAfter("BEFOREAFTER #3.5");

        assert(success);
        states[callNum].minimumCredit = abi.decode(returnData, (uint256));

        emit DebugBeforeAfter("BEFOREAFTER #3.6");

        (success, returnData) = perps.staticcall(
            abi.encodeWithSelector(perpsMarketFactoryModuleImpl.utilizationRate.selector)
        );
        assert(success);

        emit DebugBeforeAfter("BEFOREAFTER #4");

        (cache.rate, cache.delegatedCollateral, cache.lockedCredit) = abi.decode(
            returnData,
            (uint256, uint256, uint256)
        );

        emit DebugBeforeAfter("BEFOREAFTER #5");

        states[callNum].utilizationRate = cache.rate;
        states[callNum].delegatedCollateral = cache.delegatedCollateral;
        states[callNum].lockedCredit = cache.lockedCredit;

        //TODO: code below returns zeros on commit order, [Revert] panic: division or modulo by zero (0x12)

        (success, returnData) = perps.staticcall(
            abi.encodeWithSelector(perpsAccountModuleImpl.getAvailableMargin.selector, accountId)
        );
        assert(success);
        cache.availableMargin = abi.decode(returnData, (int256));

        states[callNum].actorStates[accountId].availableMargin = cache.availableMargin;
        /**
          if (account.openPositionMarketIds.length() == 0) {
            return (0, 0, 0);
        }
 */
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

        emit DebugBeforeAfter("BEFOREAFTER #6");

        for (uint256 i = 0; i < USERS.length; i++) {
            cache.accountId = userToAccountIds[USERS[i]];

            (success, returnData) = perps.call(
                abi.encodeWithSelector(
                    perpsAccountModuleImpl.totalCollateralValue.selector,
                    cache.accountId
                )
            );
            assert(success);
            cache.collateralValueUsd = int256(abi.decode(returnData, (uint256)));

            cache.pricePnL = 0;
            cache.pendingFunding = 0;
            cache.marketSizeGhost = 0;

            for (uint128 marketId = 1; marketId <= 2; marketId++) {
                (success, returnData) = perps.call(
                    abi.encodeWithSelector(
                        perpsAccountModuleImpl.getOpenPosition.selector,
                        cache.accountId,
                        marketId
                    )
                );
                assert(success);
                (cache.totalPnl, cache.accruedFunding, cache.positionSize, cache.owedInterest) = abi
                    .decode(returnData, (int256, int256, int128, uint256));

                cache.pricePnL += cache.totalPnl;
                cache.pendingFunding += cache.accruedFunding;
                cache.marketSizeGhost += uint256(MathUtil.abs(cache.positionSize));

                emit DebugSize(
                    cache.positionSize,
                    USERS[i],
                    cache.accountId,
                    marketId == 1 ? "WETH pos size" : "WBTC pos size"
                );
            }

            (success, returnData) = perps.call(
                abi.encodeWithSelector(perpsAccountModuleImpl.debt.selector, cache.accountId)
            );
            assert(success);
            cache.debtUsd = abi.decode(returnData, (int256));

            cache.userReportedDebt =
                (cache.collateralValueUsd + cache.pricePnL + cache.pendingFunding) -
                cache.debtUsd;
            cache.reportedDebtGhost += cache.userReportedDebt;

            states[callNum].marketSizeGhost += cache.marketSizeGhost;
        }

        if (cache.reportedDebtGhost < 0) cache.reportedDebtGhost = 0; // Reported Debt Cannot Go Negative

        // Store the calculated values in the state
        states[callNum].reportedDebtGhost = cache.reportedDebtGhost;

        console2.log("reportedDebtGhost", states[callNum].reportedDebtGhost);
        console2.log("marketSizeGhost", states[callNum].marketSizeGhost);

        //TODO: all accounts iteration
        console2.log("===== BeforeAfter::_setActorState END ===== ");
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
