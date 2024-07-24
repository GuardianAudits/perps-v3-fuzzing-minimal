// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PropertiesBase.sol";
import {console2} from "lib/forge-std/src/Test.sol";

abstract contract Properties_LIQ is PropertiesBase {
    function invariant_LIQ_01(uint128 account) internal {
        fl.log("ACCOUNT LIQ_01:", account);
        fl.t(
            states[0].actorStates[account].isPositionLiquidatablePassing,
            LIQ_01
        );
        fl.t(
            states[1].actorStates[account].isPositionLiquidatablePassing,
            LIQ_01
        );
    }

    //LIQ_02 N/A no flaggedBy

    function invariant_LIQ_03() internal {
        console2.log(
            "WETH Liquidation Capacity (Before):",
            states[0].wethMarket.liquidationCapacity
        );
        console2.log(
            "WETH Liquidation Capacity (After):",
            states[1].wethMarket.liquidationCapacity
        );

        console2.log(
            "WBTC Liquidation Capacity (Before):",
            states[0].wbtcMarket.liquidationCapacity
        );
        console2.log(
            "WBTC Liquidation Capacity (After):",
            states[1].wbtcMarket.liquidationCapacity
        );
        bool wethCapacityChanged = states[1].wethMarket.liquidationCapacity !=
            states[0].wethMarket.liquidationCapacity;
        bool wbtcCapacityChanged = states[1].wbtcMarket.liquidationCapacity !=
            states[0].wbtcMarket.liquidationCapacity;

        console2.log("WBTC Capacity Changed:", wbtcCapacityChanged);
        console2.log("WETH Capacity Changed:", wethCapacityChanged);

        // Check if neither changed and was not zero
        if (!wethCapacityChanged && !wbtcCapacityChanged) {
            fl.t(
                states[0].wethMarket.liquidationCapacity ==
                    states[1].wethMarket.liquidationCapacity &&
                    states[0].wbtcMarket.liquidationCapacity ==
                    states[1].wbtcMarket.liquidationCapacity,
                "LIQ_03: At least one market should have zero initial capacity if unchanged"
            );
        }

        // Check WETH market
        if (wethCapacityChanged) {
            if (states[0].wethMarket.liquidationCapacity != 0) {
                fl.lt(
                    states[1].wethMarket.liquidationCapacity,
                    states[0].wethMarket.liquidationCapacity,
                    "LIQ_03: WETH capacity should decrease"
                );
            } else {
                fl.eq(
                    states[1].wethMarket.liquidationCapacity,
                    states[0].wethMarket.liquidationCapacity,
                    "LIQ_03: WETH capacity should remain zero"
                );
            }
        }

        // Check WBTC market
        if (wbtcCapacityChanged) {
            if (states[0].wbtcMarket.liquidationCapacity != 0) {
                fl.lt(
                    states[1].wbtcMarket.liquidationCapacity,
                    states[0].wbtcMarket.liquidationCapacity,
                    "LIQ_03: WBTC capacity should decrease"
                );
            } else {
                fl.eq(
                    states[1].wbtcMarket.liquidationCapacity,
                    states[0].wbtcMarket.liquidationCapacity,
                    "LIQ_03: WBTC capacity should remain zero"
                );
            }
        }
    }

    //LIQ_04 N/A no flaggedBy
    //LIQ_05 N/A no flaggedBy
    //LIQ_06 N/A no flaggedBy
    //LIQ_07 N/A no flaggedBy

    function invariant_LIQ_08() internal {
        fl.t(
            states[0].delegatedCollateralValueUsd >= states[0].minimumCredit,
            LIQ_08
        );
    }

    function invariant_LIQ_09(uint128 account) internal {
        if (
            states[1].actorStates[account].wethMarket.positionSize == 0 &&
            states[1].actorStates[account].wbtcMarket.positionSize == 0
        ) {
            fl.t(states[1].actorStates[account].availableMargin == 0, LIQ_09);
        }
    }

    //LIQ_10 N/A no flaggedBy

    function invariant_LIQ_11(uint128 account) internal {
        if (
            states[1].actorStates[account].wethMarket.positionSize == 0 &&
            states[1].actorStates[account].wbtcMarket.positionSize == 0
        ) {
            fl.log(
                "Margin before:",
                states[0].actorStates[account].availableMargin
            );
            fl.log(
                "Margin after:",
                states[1].actorStates[account].availableMargin
            );
            // if position was fully liquidated, market collateral should be decreased by user's margin amount
            fl.eq(
                states[0].totalCollateralValueUsd -
                    states[1].totalCollateralValueUsd,
                int256(states[0].actorStates[account].totalCollateralValue),
                // int256(MathUtil.abs(states[0].actorStates[account].availableMargin)),
                LIQ_11
            );
        }
    }

    //LIQ_12 N/A no flaggedBy
    //LIQ_13 N/A no flaggedBy
    //LIQ_14 N/A no flaggedBy

    function invariant_LIQ_15(uint128 account) internal {
        fl.gte(
            states[0].actorStates[account].totalCollateralValue -
                states[1].actorStates[account].totalCollateralValue,
            states[0].actorStates[account].maxLiquidationReward,
            LIQ_15
        );
    }

    function invariant_LIQ_16() internal {
        bool wethConditionMet = (states[0]
            .wethMarket
            .debtCorrectionAccumulator >
            states[1].wethMarket.debtCorrectionAccumulator) &&
            (states[0].wethMarket.reportedDebt >
                states[1].wethMarket.reportedDebt);

        bool wbtcConditionMet = (states[0]
            .wbtcMarket
            .debtCorrectionAccumulator >
            states[1].wbtcMarket.debtCorrectionAccumulator) &&
            (states[0].wbtcMarket.reportedDebt >
                states[1].wbtcMarket.reportedDebt);

        fl.t(
            (wethConditionMet || wbtcConditionMet) ||
                (wethConditionMet && wbtcConditionMet),
            LIQ_16
        );
    }

    function invariant_LIQ_17(uint128 account) internal {
        if (states[0].actorStates[account].isAccountLiquidatable) {
            fl.eq(
                states[0].actorStates[account].totalCollateralValue,
                0,
                LIQ_17
            );
            fl.eq(states[0].actorStates[account].debt, 0, LIQ_17);
        }
        if (states[1].actorStates[account].isAccountLiquidatable) {
            fl.eq(
                states[1].actorStates[account].totalCollateralValue,
                0,
                LIQ_17
            );
            fl.eq(states[1].actorStates[account].debt, 0, LIQ_17);
        }
    }
}
