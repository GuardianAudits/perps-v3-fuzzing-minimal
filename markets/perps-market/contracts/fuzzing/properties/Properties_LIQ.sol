// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PropertiesBase.sol";
import {console2} from "lib/forge-std/src/Test.sol";
import {MathUtil} from "../../utils/MathUtil.sol";

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

    function invariant_LIQ_02() internal {
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
                "LIQ_02: At least one market should have zero initial capacity if unchanged"
            );
        }

        // Check WETH market
        if (wethCapacityChanged) {
            if (states[0].wethMarket.liquidationCapacity != 0) {
                fl.lt(
                    states[1].wethMarket.liquidationCapacity,
                    states[0].wethMarket.liquidationCapacity,
                    "LIQ_02: WETH capacity should decrease"
                );
            } else {
                fl.eq(
                    states[1].wethMarket.liquidationCapacity,
                    states[0].wethMarket.liquidationCapacity,
                    "LIQ_02: WETH capacity should remain zero"
                );
            }
        }

        // Check WBTC market
        if (wbtcCapacityChanged) {
            if (states[0].wbtcMarket.liquidationCapacity != 0) {
                fl.lt(
                    states[1].wbtcMarket.liquidationCapacity,
                    states[0].wbtcMarket.liquidationCapacity,
                    "LIQ_02: WBTC capacity should decrease"
                );
            } else {
                fl.eq(
                    states[1].wbtcMarket.liquidationCapacity,
                    states[0].wbtcMarket.liquidationCapacity,
                    "LIQ_02: WBTC capacity should remain zero"
                );
            }
        }
    }

    function invariant_LIQ_03() internal {
        fl.t(
            states[0].delegatedCollateralValueUsd >= states[0].minimumCredit,
            LIQ_03
        );
    }

    function invariant_LIQ_04(uint128 account) internal {
        if (
            states[1].actorStates[account].wethMarket.positionSize == 0 &&
            states[1].actorStates[account].wbtcMarket.positionSize == 0
        ) {
            fl.t(states[1].actorStates[account].availableMargin == 0, LIQ_04);
        }
    }

    function invariant_LIQ_05(uint128 account) internal {
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
            eqWithToleranceWei(
                uint(
                    states[0].totalCollateralValueUsd -
                        states[1].totalCollateralValueUsd
                ),
                uint(
                    int256(states[0].actorStates[account].totalCollateralValue)
                ),
                1, //1 wei difference is tolerable
                LIQ_05
            );
        }
    }

    function invariant_LIQ_06(uint128 account) internal {
        fl.gte(
            states[0].actorStates[account].totalCollateralValue -
                states[1].actorStates[account].totalCollateralValue,
            states[0].actorStates[account].maxLiquidationReward,
            LIQ_06
        );
    }

    function invariant_LIQ_07(uint128 account) internal {
        if (states[0].actorStates[account].isAccountLiquidatable) {
            fl.eq(
                states[0].actorStates[account].totalCollateralValue,
                0,
                LIQ_07
            );
            fl.eq(states[0].actorStates[account].debt, 0, LIQ_07);
        }
        if (states[1].actorStates[account].isAccountLiquidatable) {
            fl.eq(
                states[1].actorStates[account].totalCollateralValue,
                0,
                LIQ_07
            );
            fl.eq(states[1].actorStates[account].debt, 0, LIQ_07);
        }
    }

    function invariant_LIQ_08(uint128 account) internal {
        console2.log("account", account);

        if (states[0].actorStates[account].wethMarket.positionSize > 0) {
            console2.log(
                "states[0].actorStates[account].wethMarket.maxLiquidatableAmount",
                states[0].actorStates[account].wethMarket.maxLiquidatableAmount
            );
            console2.log(
                "states[0].actorStates[account].wethMarket.positionSize",
                states[0].actorStates[account].wethMarket.positionSize
            );
            fl.lte(
                states[0].actorStates[account].wethMarket.maxLiquidatableAmount,
                uint256(
                    MathUtil.abs(
                        states[0].actorStates[account].wethMarket.positionSize
                    )
                ),
                LIQ_08
            );
        }

        if (states[1].actorStates[account].wethMarket.positionSize > 0) {
            console2.log(
                "states[1].actorStates[account].wethMarket.maxLiquidatableAmount",
                states[1].actorStates[account].wethMarket.maxLiquidatableAmount
            );
            console2.log(
                "states[1].actorStates[account].wethMarket.positionSize",
                states[1].actorStates[account].wethMarket.positionSize
            );
            fl.lte(
                states[1].actorStates[account].wethMarket.maxLiquidatableAmount,
                uint256(
                    MathUtil.abs(
                        states[1].actorStates[account].wethMarket.positionSize
                    )
                ),
                LIQ_08
            );
        }

        if (states[0].actorStates[account].wbtcMarket.positionSize > 0) {
            console2.log(
                "states[0].actorStates[account].wbtcMarket.maxLiquidatableAmount",
                states[0].actorStates[account].wbtcMarket.maxLiquidatableAmount
            );
            console2.log(
                "states[0].actorStates[account].wbtcMarket.positionSize",
                states[0].actorStates[account].wbtcMarket.positionSize
            );
            fl.lte(
                states[0].actorStates[account].wbtcMarket.maxLiquidatableAmount,
                uint256(
                    MathUtil.abs(
                        states[0].actorStates[account].wbtcMarket.positionSize
                    )
                ),
                LIQ_08
            );
        }

        if (states[1].actorStates[account].wbtcMarket.positionSize > 0) {
            console2.log(
                "states[1].actorStates[account].wbtcMarket.maxLiquidatableAmount",
                states[1].actorStates[account].wbtcMarket.maxLiquidatableAmount
            );
            console2.log(
                "states[1].actorStates[account].wbtcMarket.positionSize",
                states[1].actorStates[account].wbtcMarket.positionSize
            );
            fl.lte(
                states[1].actorStates[account].wbtcMarket.maxLiquidatableAmount,
                uint256(
                    MathUtil.abs(
                        states[1].actorStates[account].wbtcMarket.positionSize
                    )
                ),
                LIQ_08
            );
        }
    }

    function invariant_LIQ_09(
        bool firstLiquidationAttempt,
        address liquidator
    ) internal {
        if (!firstLiquidationAttempt) {
            console2.log(
                "Invariant liq 19 user debug",
                userToAccountIds[liquidator]
            );
            fl.eq(
                states[0]
                    .actorStates[userToAccountIds[liquidator]]
                    .balanceOfSUSD,
                states[1]
                    .actorStates[userToAccountIds[liquidator]]
                    .balanceOfSUSD,
                LIQ_09
            );
            fl.eq(
                states[0]
                    .actorStates[userToAccountIds[liquidator]]
                    .balanceOfWETH,
                states[1]
                    .actorStates[userToAccountIds[liquidator]]
                    .balanceOfWETH,
                LIQ_09
            );
            fl.eq(
                states[0]
                    .actorStates[userToAccountIds[liquidator]]
                    .balanceOfWBTC,
                states[1]
                    .actorStates[userToAccountIds[liquidator]]
                    .balanceOfWBTC,
                LIQ_09
            );
        }
    }
}
