// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "../FuzzSetup.sol";
import {AsyncOrder} from "../../storage/AsyncOrder.sol";
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
        int128 skew;
        uint128 marketSize;
        uint256 liquidationCapacity;
        uint256 minimumCredit;
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
        // IPerpMarketFactoryModule.UtilizationDigest utilizationDigest; //using rate
        uint256 utilizationRate; //perpsMarketFactoryModuleImpl.utilizationRate
        uint256 delegatedCollateral; //perpsMarketFactoryModuleImpl.utilizationRate
        uint256 lockedCredit; //perpsMarketFactoryModuleImpl.utilizationRate
        int256 reportedDebt;
        int256 reportedDebtGhost;
        int256 totalCollateralValueUsdGhost;
    }

    struct ActorStates {
        bool isPositionLiquidatable;
        bool isPositionLiquidatablePassing;
        bool isMarginLiquidatable;
        // uint256 liquidationKeeperFee;
        uint128 debt;
        uint256[] collateralIds; //perpsAccountModuleImpl.getAccountCollateralIds
        uint256 collateralAmountSUSD; //perpsAccountModuleImpl.getCollateralAmount
        uint256 collateralAmountWETH; //perpsAccountModuleImpl.getCollateralAmount
        uint256 collateralAmountWBTC; //perpsAccountModuleImpl.getCollateralAmount
        uint256 totalCollateralValue; //perpsAccountModuleImpl.totalCollateralValue
        // uint256 wethCollateralValue;
        int128 sizeDelta;
        // uint256 fillPriceWETH;
        // uint256 fillPriceWBTC;
        // address flaggedBy;
        uint256 sUSDBalance;
        //*
        // Margin.MarginValues marginDigest;
        int256 availableMargin; //perpsAccountModuleImpl.getAvailableMargin
        uint256 requiredInitialMargin; //perpsAccountModuleImpl.getRequiredMargins
        uint256 requiredMaintenanceMargin; //perpsAccountModuleImpl.getRequiredMargins
        uint256 marginKeeperFee; //perpsAccountModuleImpl.getRequiredMargins
        // IPerpAccountModule.PositionDigest positionDigest; returns position data above
        uint256 depositedWethCollateral;
        uint256 depositedSusdCollateral;
        PositionVars wethMarket; //TODO:rename to position
        PositionVars wbtcMarket;
    }

    struct ReportedDebtVars {
        int256 collateralValueUsd;
        int256 pricePnL;
        int256 pendingFunding;
        int256 pendingUtilization;
        int256 debtUsd;
    }

    struct TotalCollateralVars {
        address collateralToken;
        int256 amount;
        bytes32 nodeId;
        int256 price;
        int256 value;
    }

    struct StackCache {
        uint256 capacity;
        uint256 maxLiquidationInWindow;
        uint256 latestLiquidationTimestamp;
        int256 totalPnl;
        int256 accruedFunding;
        int128 positionSize;
        uint256 owedInterest;
        int128 marketSkew;
        uint128 marketSize;
        uint256 rate;
        uint256 delegatedCollateral;
        uint256 lockedCredit;
        int256 availableMargin;
        uint256 requiredInitialMargin;
        uint256 requiredMaintenanceMargin;
        uint256 maxLiquidationReward;
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

        // (success, returnData) = perps.call(
        //     abi.encodeWithSelector(
        //         asyncOrderModuleImpl.computeOrderFeesWithPrice.selector,
        //         1, // marketId,
        //         states[callNum].actorStates[accountId].sizeDelta,
        //         price
        //     )
        // );
        // assert(success);
        // (uint256 orderFeesWETH, uint256 fillPriceWETH) = abi.decode(returnData, (uint256, uint256));
        // states[callNum].actorStates[accountId].fillPriceWETH = fillPriceWETH;

        // (success, returnData) = perps.call(
        //     abi.encodeWithSelector(
        //         asyncOrderModuleImpl.computeOrderFeesWithPrice.selector,
        //         2,
        //         states[callNum].actorStates[accountId].sizeDelta,
        //         price
        //     )
        // );
        // assert(success);
        // (uint256 orderFeesWBTC, uint256 fillPriceWBTC) = abi.decode(returnData, (uint256, uint256));
        // states[callNum].actorStates[accountId].fillPriceWBTC = fillPriceWBTC;

        //no flags in perps
        //TODO: check if flaggedAccounts could help

        states[callNum].actorStates[accountId].sUSDBalance = sUSDTokenMock.balanceOf(actor);

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsAccountModuleImpl.getOpenPosition.selector, accountId, 1)
        );
        assert(success);
        (cache.totalPnl, cache.accruedFunding, cache.positionSize, cache.owedInterest) = abi.decode(
            returnData,
            (int256, int256, int128, uint256)
        );

        states[callNum].actorStates[accountId].wethMarket.totalPnl = cache.totalPnl;
        states[callNum].actorStates[accountId].wethMarket.accruedFunding = cache.accruedFunding;
        states[callNum].actorStates[accountId].wethMarket.positionSize = cache.positionSize;
        states[callNum].actorStates[accountId].wethMarket.owedInterest = cache.owedInterest;

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

        (success, returnData) = perps.call(
            abi.encodeWithSelector(globalPerpsMarketModuleImpl.globalCollateralValue.selector, 0)
        );
        assert(success);
        uint256 collateralValueSUSD = abi.decode(returnData, (uint256));
        states[callNum].actorStates[accountId].depositedSusdCollateral = collateralValueSUSD;

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
        uint256 collateralValueWBTC = abi.decode(returnData, (uint256));
        states[callNum].depositedWbtcCollateral = collateralValueWBTC;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(globalPerpsMarketModuleImpl.totalGlobalCollateralValue.selector)
        );
        assert(success);
        totalCollateralValue = abi.decode(returnData, (uint256));
        states[callNum].totalCollateralValueUsd = int256(totalCollateralValue);

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.skew.selector, 2)
        );
        assert(success);
        cache.marketSkew = abi.decode(returnData, (int128));
        states[callNum].wbtcMarket.skew = cache.marketSkew;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.size.selector, 2)
        );
        assert(success);
        cache.marketSize = abi.decode(returnData, (uint128));
        states[callNum].wbtcMarket.marketSize = cache.marketSize;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.skew.selector, 1)
        );
        assert(success);
        cache.marketSkew = abi.decode(returnData, (int128));
        states[callNum].wethMarket.skew = cache.marketSkew;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketModuleImpl.size.selector, 1)
        );
        assert(success);
        cache.marketSize = abi.decode(returnData, (uint128));
        states[callNum].wethMarket.marketSize = cache.marketSize;

        states[callNum].totalCollateralValueUsdGhost = 0; // zero the ghost variable to not continuously accumulate on it

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketFactoryModuleImpl.minimumCredit.selector, 1)
        );
        assert(success);
        states[callNum].wethMarket.minimumCredit = abi.decode(returnData, (uint256));

        (success, returnData) = perps.call(
            abi.encodeWithSelector(perpsMarketFactoryModuleImpl.minimumCredit.selector, 2)
        );
        assert(success);
        states[callNum].wbtcMarket.minimumCredit = abi.decode(returnData, (uint256));

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

        //TODO: code below returns zeros on commit order, [Revert] panic: division or modulo by zero (0x12)

        // (success, returnData) = perps.staticcall(
        //     abi.encodeWithSelector(perpsAccountModuleImpl.getAvailableMargin.selector, accountId)
        // );
        // assert(success);
        // cache.availableMargin = abi.decode(returnData, (int256));

        // states[callNum].actorStates[accountId].availableMargin = cache.availableMargin;
        /**
          if (account.openPositionMarketIds.length() == 0) {
            return (0, 0, 0);
        }
 */
        // (success, returnData) = perps.staticcall(
        //     abi.encodeWithSelector(perpsAccountModuleImpl.getRequiredMargins.selector, accountId)
        // );
        // assert(success);

        // (
        //     cache.requiredInitialMargin,
        //     cache.requiredMaintenanceMargin,
        //     cache.maxLiquidationReward
        // ) = abi.decode(returnData, (uint256, uint256, uint256));

        // states[callNum].actorStates[accountId].requiredInitialMargin = cache.requiredInitialMargin;
        // states[callNum].actorStates[accountId].requiredMaintenanceMargin = cache
        //     .requiredMaintenanceMargin;
        // states[callNum].actorStates[accountId].marginKeeperFee = cache.maxLiquidationReward;

        states[callNum].reportedDebtGhost = 0; // set previously calculated value to 0 to not affect new calculation
        states[callNum].marketSizeGhost = 0;

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
