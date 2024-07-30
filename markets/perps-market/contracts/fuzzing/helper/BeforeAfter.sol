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
        uint256 delegatedCollateralValueUsd;
        uint128 currentUtilizationAccruedComputed;
        uint256 utilizationRate;
        uint256 delegatedCollateral;
        uint256 lockedCredit;
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
        uint256[] collateralIds;
        uint256 balanceOfSUSD;
        uint256 balanceOfWETH;
        uint256 balanceOfWBTC;
        uint256 collateralAmountSUSD;
        uint256 collateralAmountWETH;
        uint256 collateralAmountWBTC;
        uint256 collateralAmountHUGE;
        uint256 totalCollateralValue;
        int128 sizeDelta;
        bool isOrderExpired;
        uint256 fillPriceWETH;
        uint256 fillPriceWBTC;
        uint256 sUSDBalance;
        int256 availableMargin;
        uint256 requiredInitialMargin;
        uint256 requiredMaintenanceMargin;
        uint256 maxLiquidationReward;
        uint256 depositedWethCollateral;
        uint256 depositedSusdCollateral;
        uint128[] activeCollateralTypes;
        uint128[] openPositionMarketIds;
        PositionVars wethMarket;
        PositionVars wbtcMarket;
        bool isAccountLiquidatable;
        bool isPreviousPositionInLoss;
        int256 latestPositionPnl;
        bool isPreviousTradePositionInLoss;
        int256 previousTradePositionPnl;
    }

    // Function-specific structs
    struct LiquidationVars {
        bool isPositionLiquidatable;
        bool isMarginLiquidatable;
        uint128 debt;
        uint256 maxLiquidatableAmount;
    }

    struct CollateralVars {
        uint256[] collateralIds;
        uint256 collateralAmount;
        uint256 totalCollateralValue;
    }

    struct OrderVars {
        int128 sizeDelta;
        bool isOrderExpired;
        uint256 fillPrice;
    }

    struct PositionInfoVars {
        int256 totalPnl;
        int256 accruedFunding;
        int128 positionSize;
        uint256 owedInterest;
    }

    struct MarketInfoVars {
        uint256 liquidationCapacity;
        uint256 marketSize;
        int256 skew;
    }

    struct UtilizationVars {
        uint256 utilizationRate;
        uint256 delegatedCollateral;
        uint256 lockedCredit;
    }

    struct MarginVars {
        int256 availableMargin;
        uint256 requiredInitialMargin;
        uint256 requiredMaintenanceMargin;
    }

    struct DebtVars {
        int256 totalDebt;
        uint256 reportedDebt;
        uint256 debtCorrectionAccumulator;
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
        getGlobalCollateralValues(callNum);
        getLiquidationValues(callNum, accountId);
        getCollateralInfo(callNum, accountId);
        getOrderInfo(callNum, accountId);
        getPositionInfo(callNum, accountId);
        getMarketInfo(callNum);
        getUtilizationInfo(callNum);
        getMarginInfo(callNum, accountId);
        getDebtInfo(callNum, accountId);
        getGlobalDebt(callNum);
        getAndCalculateCollateralValues(callNum);
        checkIfAccountLiquidatable(callNum, accountId);
        getAccountBalances(callNum, accountId);

        console2.log("===== BeforeAfter::_setActorState END ===== ");
    }
    function _setActorState(
        uint8 callNum,
        uint128 accountId,
        uint128 marketId,
        address actor
    ) internal {
        console2.log("===== BeforeAfter::_setActorState START ===== ");

        _checkIfPositionWasProifitable(callNum, accountId, marketId);

        console2.log("===== BeforeAfter::_setActorState END ===== ");
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
    function resetGhostVariables(uint8 callNum) private {
        states[callNum].totalCollateralValueUsdGhost = 0;
        states[callNum].reportedDebtGhost = 0;
        states[callNum].marketSizeGhost = 0;
        states[callNum].totalDebtCalculated = 0;
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

    function getAccountBalances(uint8 callNum, uint128 accountId) private {
        states[callNum].actorStates[accountId].balanceOfWETH = wethTokenMock
            .balanceOf(accountIdToUser[accountId]);
        states[callNum].actorStates[accountId].balanceOfSUSD = sUSDTokenMock
            .balanceOf(accountIdToUser[accountId]);
        states[callNum].actorStates[accountId].balanceOfWBTC = wbtcTokenMock
            .balanceOf(accountIdToUser[accountId]);
    }

    function getLiquidationValues(uint8 callNum, uint128 accountId) private {
        LiquidationVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.canLiquidate.selector,
                accountId
            )
        );
        states[callNum]
            .actorStates[accountId]
            .isPositionLiquidatablePassing = success;
        vars.isPositionLiquidatable = abi.decode(returnData, (bool));

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.canLiquidateMarginOnly.selector,
                accountId
            )
        );
        assert(success);
        vars.isMarginLiquidatable = abi.decode(returnData, (bool));

        states[callNum].actorStates[accountId].isPositionLiquidatable = vars
            .isPositionLiquidatable;
        states[callNum].actorStates[accountId].isMarginLiquidatable = vars
            .isMarginLiquidatable;

        _logLiquidatableCoverage(
            vars.isPositionLiquidatable,
            vars.isMarginLiquidatable
        );

        _logLiquidateMarginOnlyCoverage(lcov_liquidateMarginOnlyCovered);
    }

    function getCollateralInfo(uint8 callNum, uint128 accountId) private {
        CollateralVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getAccountCollateralIds.selector,
                accountId
            )
        );
        assert(success);
        vars.collateralIds = abi.decode(returnData, (uint256[]));

        states[callNum].actorStates[accountId].collateralIds = vars
            .collateralIds;

        for (uint256 i = 0; i < 4; i++) {
            getCollateralAmount(callNum, accountId, i);
        }

        vars.totalCollateralValue = getTotalCollateralValue(accountId);
        states[callNum].actorStates[accountId].totalCollateralValue = vars
            .totalCollateralValue;

        _logCollateralIdsCoverage(vars.collateralIds);
        _logCollateralAmountsCoverage(
            states[callNum].actorStates[accountId].collateralAmountSUSD,
            states[callNum].actorStates[accountId].collateralAmountWETH,
            states[callNum].actorStates[accountId].collateralAmountWBTC,
            vars.totalCollateralValue
        );
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

    function getOrderInfo(uint8 callNum, uint128 accountId) private {
        OrderVars memory vars;

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
        AsyncOrder.Data memory order = abi.decode(
            returnData,
            (AsyncOrder.Data)
        );
        vars.sizeDelta = order.request.sizeDelta;

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.isOrderExpired.selector,
                accountId
            )
        );
        assert(success);
        vars.isOrderExpired = abi.decode(returnData, (bool));

        states[callNum].actorStates[accountId].sizeDelta = vars.sizeDelta;
        states[callNum].actorStates[accountId].isOrderExpired = vars
            .isOrderExpired;

        getOrderFees(callNum, accountId, 1, WETH_PYTH_PRICE_FEED_ID);
        getOrderFees(callNum, accountId, 2, WBTC_PYTH_PRICE_FEED_ID);

        states[callNum].actorStates[accountId].sUSDBalance = sUSDTokenMock
            .balanceOf(accountIdToUser[accountId]);

        _logOrderInfoCoverage(
            states[callNum].actorStates[accountId].debt,
            vars.sizeDelta,
            vars.isOrderExpired,
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

    function getPositionInfo(uint8 callNum, uint128 accountId) private {
        PositionInfoVars memory vars;

        getOpenPosition(callNum, accountId, 1);
        getOpenPosition(callNum, accountId, 2);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getOpenPositionMarketIds.selector,
                accountId
            )
        );
        assert(success);
        states[callNum].actorStates[accountId].openPositionMarketIds = abi
            .decode(returnData, (uint128[]));

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getGlobalCollateralTypes.selector,
                accountId
            )
        );
        assert(success);
        states[callNum].actorStates[accountId].activeCollateralTypes = abi
            .decode(returnData, (uint128[]));

        (success, returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getGlobalCollateralTypes.selector
            )
        );
        assert(success);
        states[callNum].globalCollateralTypes = abi.decode(
            returnData,
            (uint128[])
        );

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

    function getOpenPosition(
        uint8 callNum,
        uint128 accountId,
        uint128 marketId
    ) private {
        PositionInfoVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getOpenPosition.selector,
                accountId,
                marketId
            )
        );
        assert(success);
        (
            vars.totalPnl,
            vars.accruedFunding,
            vars.positionSize,
            vars.owedInterest
        ) = abi.decode(returnData, (int256, int256, int128, uint256));

        if (marketId == 1) {
            states[callNum].actorStates[accountId].wethMarket.totalPnl = vars
                .totalPnl;
            states[callNum]
                .actorStates[accountId]
                .wethMarket
                .accruedFunding = vars.accruedFunding;
            states[callNum]
                .actorStates[accountId]
                .wethMarket
                .positionSize = vars.positionSize;
            states[callNum]
                .actorStates[accountId]
                .wethMarket
                .owedInterest = vars.owedInterest;
        } else if (marketId == 2) {
            states[callNum].actorStates[accountId].wbtcMarket.totalPnl = vars
                .totalPnl;
            states[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .accruedFunding = vars.accruedFunding;
            states[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .positionSize = vars.positionSize;
            states[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .owedInterest = vars.owedInterest;
        }
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

    function getMarketInfo(uint8 callNum) private {
        MarketInfoVars memory vars;

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

    function getLiquidationCapacity(uint8 callNum, uint256 marketId) private {
        MarketInfoVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.liquidationCapacity.selector,
                marketId
            )
        );
        assert(success);
        (vars.liquidationCapacity, , ) = abi.decode(
            returnData,
            (uint256, uint256, uint256)
        );
        if (marketId == 1) {
            states[callNum].wethMarket.liquidationCapacity = vars
                .liquidationCapacity;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.liquidationCapacity = vars
                .liquidationCapacity;
        }
    }

    function getMarketSize(uint8 callNum, uint256 marketId) private {
        MarketInfoVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsMarketModuleImpl.size.selector,
                marketId
            )
        );
        assert(success);
        vars.marketSize = abi.decode(returnData, (uint256));
        if (marketId == 1) {
            states[callNum].wethMarket.marketSize = vars.marketSize;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.marketSize = vars.marketSize;
        }
    }

    function getMarketSkew(uint8 callNum, uint256 marketId) private {
        MarketInfoVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsMarketModuleImpl.skew.selector,
                marketId
            )
        );
        assert(success);
        vars.skew = abi.decode(returnData, (int256));
        if (marketId == 1) {
            states[callNum].wethMarket.skew = vars.skew;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.skew = vars.skew;
        } else if (marketId == 3) {
            states[callNum].hugeMarket.skew = vars.skew;
        }
    }
    // struct CollateralData {
    //     uint256 susdValue;
    //     uint256 wethValue;
    //     uint256 wbtcValue;
    //     uint256 totalValue;
    // }

    // function getAndCalculateCollateralValues(uint8 callNum) private {
    //     CollateralData memory globalData;
    //     CollateralData memory userTotalData;

    //     // Get global collateral values from the perps contract
    //     (bool success, bytes memory returnData) = perps.call(
    //         abi.encodeWithSelector(
    //             globalPerpsMarketModuleImpl.globalCollateralValue.selector,
    //             0
    //         )
    //     );
    //     assert(success);
    //     globalData.susdValue = abi.decode(returnData, (uint256));

    //     (success, returnData) = perps.call(
    //         abi.encodeWithSelector(
    //             globalPerpsMarketModuleImpl.globalCollateralValue.selector,
    //             1
    //         )
    //     );
    //     assert(success);
    //     globalData.wethValue = abi.decode(returnData, (uint256));

    //     (success, returnData) = perps.call(
    //         abi.encodeWithSelector(
    //             globalPerpsMarketModuleImpl.globalCollateralValue.selector,
    //             2
    //         )
    //     );
    //     assert(success);
    //     globalData.wbtcValue = abi.decode(returnData, (uint256));

    //     (success, returnData) = perps.call(
    //         abi.encodeWithSelector(
    //             globalPerpsMarketModuleImpl.totalGlobalCollateralValue.selector
    //         )
    //     );
    //     assert(success);
    //     globalData.totalValue = abi.decode(returnData, (uint256));

    //     // Calculate user totals
    //     int256 wethPrice = mockOracleManager.process(WETH_ORACLE_NODE_ID).price;
    //     int256 wbtcPrice = mockOracleManager.process(WBTC_ORACLE_NODE_ID).price;

    //     for (uint256 i = 0; i < USERS.length; i++) {
    //         uint128 accountId = userToAccountIds[USERS[i]];
    //         userTotalData.susdValue += states[callNum]
    //             .actorStates[accountId]
    //             .collateralAmountSUSD;
    //         userTotalData.wethValue += states[callNum]
    //             .actorStates[accountId]
    //             .collateralAmountWETH;
    //         userTotalData.wbtcValue += states[callNum]
    //             .actorStates[accountId]
    //             .collateralAmountWBTC;
    //     }

    //     userTotalData.totalValue =
    //         userTotalData.susdValue +
    //         ((uint256(wethPrice) * userTotalData.wethValue) / 1e18) +
    //         ((uint256(wbtcPrice) * userTotalData.wbtcValue) / 1e18);

    //     // Store results
    //     states[callNum].depositedSusdCollateral = globalData.susdValue;
    //     states[callNum].depositedWethCollateral = globalData.wethValue;
    //     states[callNum].depositedWbtcCollateral = globalData.wbtcValue;
    //     states[callNum].totalCollateralValueUsd = globalData.totalValue;
    //     states[callNum].totalCollateralValueUsdGhost = userTotalData.totalValue;

    //     states[callNum].collateralValueAllUsersSUSDCalculated = int256(
    //         userTotalData.susdValue
    //     );
    //     states[callNum].collateralValueAllUsersWETHCalculated = int256(
    //         userTotalData.wethValue
    //     );
    //     states[callNum].collateralValueAllUsersWBTCCalculated = int256(
    //         userTotalData.wbtcValue
    //     );

    //     // Logging
    //     console2.log("Global SUSD Collateral:", globalData.susdValue);
    //     console2.log("Global WETH Collateral:", globalData.wethValue);
    //     console2.log("Global WBTC Collateral:", globalData.wbtcValue);
    //     console2.log("Total Global Collateral Value:", globalData.totalValue);
    //     console2.log("Total User Collateral Value:", userTotalData.totalValue);

    //     _logGlobalCollateralValuesCoverage(
    //         globalData.susdValue,
    //         globalData.wethValue,
    //         globalData.wbtcValue,
    //         globalData.totalValue,
    //         userTotalData.totalValue,
    //         states[callNum].skew
    //     );
    // }

    function getAndCalculateCollateralValues(uint8 callNum) private {
        // User collateral values
        uint256 userTotalSusdValue = states[callNum]
            .actorStates[ACCOUNTS[0]]
            .collateralAmountSUSD +
            states[callNum].actorStates[ACCOUNTS[1]].collateralAmountSUSD +
            states[callNum].actorStates[ACCOUNTS[2]].collateralAmountSUSD;

        uint256 userTotalWethValue = states[callNum]
            .actorStates[ACCOUNTS[0]]
            .collateralAmountWETH +
            states[callNum].actorStates[ACCOUNTS[1]].collateralAmountWETH +
            states[callNum].actorStates[ACCOUNTS[2]].collateralAmountWETH;

        uint256 userTotalWbtcValue = states[callNum]
            .actorStates[ACCOUNTS[0]]
            .collateralAmountWBTC +
            states[callNum].actorStates[ACCOUNTS[1]].collateralAmountWBTC +
            states[callNum].actorStates[ACCOUNTS[2]].collateralAmountWBTC;

        // Get prices
        int256 wethPrice = mockOracleManager.getPrice(WETH_ORACLE_NODE_ID);
        int256 wbtcPrice = mockOracleManager.getPrice(WBTC_ORACLE_NODE_ID);

        // Calculate total user collateral value
        uint256 userTotalValue = userTotalSusdValue +
            ((uint256(wethPrice) * userTotalWethValue) / 1e18) +
            ((uint256(wbtcPrice) * userTotalWbtcValue) / 1e18);

        states[callNum].totalCollateralValueUsdGhost = userTotalValue;

        states[callNum].collateralValueAllUsersSUSDCalculated = int256(
            userTotalSusdValue
        );
        states[callNum].collateralValueAllUsersWETHCalculated = int256(
            userTotalWethValue
        );
        states[callNum].collateralValueAllUsersWBTCCalculated = int256(
            userTotalWbtcValue
        );
    }
    function getUtilizationInfo(uint8 callNum) private {
        UtilizationVars memory vars;

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
        (
            vars.utilizationRate,
            vars.delegatedCollateral,
            vars.lockedCredit
        ) = abi.decode(returnData, (uint256, uint256, uint256));
        states[callNum].utilizationRate = vars.utilizationRate;
        states[callNum].delegatedCollateral = vars.delegatedCollateral;
        states[callNum].lockedCredit = vars.lockedCredit;

        _logUtilizationInfoCoverage(
            states[callNum].minimumCredit,
            vars.utilizationRate,
            vars.delegatedCollateral,
            vars.lockedCredit
        );
    }

    function getMarginInfo(uint8 callNum, uint128 accountId) private {
        MarginVars memory vars;

        (bool success, bytes memory returnData) = perps.staticcall(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getAvailableMargin.selector,
                accountId
            )
        );
        assert(success);
        vars.availableMargin = abi.decode(returnData, (int256));
        states[callNum].actorStates[accountId].availableMargin = vars
            .availableMargin;

        (success, returnData) = perps.staticcall(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getRequiredMargins.selector,
                accountId
            )
        );
        assert(success);
        (vars.requiredInitialMargin, vars.requiredMaintenanceMargin, ) = abi
            .decode(returnData, (uint256, uint256, uint256));
        states[callNum].actorStates[accountId].requiredInitialMargin = vars
            .requiredInitialMargin;
        states[callNum].actorStates[accountId].requiredMaintenanceMargin = vars
            .requiredMaintenanceMargin;

        _logMarginInfoCoverage(
            vars.availableMargin,
            vars.requiredInitialMargin,
            vars.requiredMaintenanceMargin,
            states[callNum].actorStates[accountId].maxLiquidationReward
        );
    }

    function getDebtInfo(uint8 callNum, uint128 accountId) private {
        DebtVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getGlobalTotalAccountsDebt.selector
            )
        );
        assert(success);
        vars.totalDebt = abi.decode(returnData, (int256));
        states[callNum].totalDebt = vars.totalDebt;

        getReportedDebt(callNum, 1);
        getReportedDebt(callNum, 2);
        getMarketDebtCorrectionAccumulator(callNum, 1);
        getMarketDebtCorrectionAccumulator(callNum, 2);
    }

    function getReportedDebt(uint8 callNum, uint128 marketId) private {
        DebtVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.reportedDebt.selector,
                marketId
            )
        );
        assert(success);
        vars.reportedDebt = abi.decode(returnData, (uint256));

        if (marketId == 1) {
            states[callNum].wethMarket.reportedDebt = vars.reportedDebt;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.reportedDebt = vars.reportedDebt;
        }
    }

    function getMarketDebtCorrectionAccumulator(
        uint8 callNum,
        uint128 marketId
    ) private {
        DebtVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.getDebtCorrectionAccumulator.selector,
                marketId
            )
        );
        assert(success);
        vars.debtCorrectionAccumulator = abi.decode(returnData, (uint256));

        if (marketId == 1) {
            states[callNum].wethMarket.debtCorrectionAccumulator = vars
                .debtCorrectionAccumulator;
        } else if (marketId == 2) {
            states[callNum].wbtcMarket.debtCorrectionAccumulator = vars
                .debtCorrectionAccumulator;
        }
    }

    function _checkIfPositionWasProifitable(
        uint8 callNum,
        uint128 accountId,
        uint128 marketId
    ) internal {
        console2.log("checkIfPositionWasProifitable::accountId", accountId);
        console2.log("checkIfPositionWasProifitable::marketId", marketId);
        PositionInfoVars memory vars;

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getOpenPosition.selector,
                accountId,
                marketId
            )
        );
        assert(success);
        (
            vars.totalPnl,
            vars.accruedFunding,
            vars.positionSize,
            vars.owedInterest
        ) = abi.decode(returnData, (int256, int256, int128, uint256));

        if (marketId == 1) {
            console2.log("Market: WETH");
            positionStates[callNum]
                .actorStates[accountId]
                .previousTradePositionPnl = positionStates[callNum]
                .actorStates[accountId]
                .wethMarket
                .totalPnl;
            positionStates[callNum]
                .actorStates[accountId]
                .wethMarket
                .totalPnl = vars.totalPnl;
            positionStates[callNum]
                .actorStates[accountId]
                .wethMarket
                .positionSize = vars.positionSize;
        } else if (marketId == 2) {
            console2.log("Market: WBTC");
            positionStates[callNum]
                .actorStates[accountId]
                .previousTradePositionPnl = positionStates[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .totalPnl;
            positionStates[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .totalPnl = vars.totalPnl;
            positionStates[callNum]
                .actorStates[accountId]
                .wbtcMarket
                .positionSize = vars.positionSize;
        } else {
            console2.log("Invalid marketId", marketId);
            revert("Invalid marketId");
        }

        positionStates[callNum]
            .actorStates[accountId]
            .isPreviousPositionInLoss = vars.totalPnl < 0;
        positionStates[callNum]
            .actorStates[accountId]
            .isPreviousTradePositionInLoss =
            positionStates[callNum]
                .actorStates[accountId]
                .previousTradePositionPnl <
            0;
        positionStates[callNum].actorStates[accountId].latestPositionPnl = vars
            .totalPnl;

        console2.log(
            "checkIfPositionWasProifitable::isPreviousPositionInLoss",
            positionStates[callNum]
                .actorStates[accountId]
                .isPreviousPositionInLoss
        );
        console2.log(
            "checkIfPositionWasProifitable::isPreviousTradePositionInLoss",
            positionStates[callNum]
                .actorStates[accountId]
                .isPreviousTradePositionInLoss
        );
        console2.log(
            "checkIfPositionWasProifitable::previousTradePositionPnl",
            positionStates[callNum]
                .actorStates[accountId]
                .previousTradePositionPnl
        );
        console2.log(
            "checkIfPositionWasProifitable::latestPositionPnl",
            positionStates[callNum].actorStates[accountId].latestPositionPnl
        );
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
