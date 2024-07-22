// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PropertiesBase.sol";
import {MathUtil} from "../../utils/MathUtil.sol";
import {console2} from "lib/forge-std/src/Test.sol";

abstract contract Properties_ORD is PropertiesBase {
    function invariant_ORD_01(uint128 account) internal {
        fl.t(
            states[0].actorStates[account].sizeDelta == 0 ||
                states[0].actorStates[account].isOrderExpired,
            ORD_01
        );
    }

    function invariant_ORD_02(uint128 account) internal {
        fl.eq(states[1].actorStates[account].sizeDelta, 0, ORD_02);
    }

    function invariant_ORD_03(uint128 account) internal {
        fl.t(!states[1].actorStates[account].isPositionLiquidatable, ORD_03);
    }

    function invariant_ORD_04(uint128 account) internal {
        fl.gt(
            states[1].actorStates[account].sUSDBalance,
            states[0].actorStates[account].sUSDBalance,
            ORD_04
        );
    }

    function invariant_ORD_05(uint128 account) internal {
        fl.gt(
            states[1].actorStates[account].sUSDBalance,
            states[0].actorStates[account].sUSDBalance,
            ORD_05
        );
    }

    function invariant_ORD_06(uint128 account, uint128 marketId) internal {
        if (marketId == 1) {
            bool positionDecreasing = MathUtil.sameSide(
                states[0].actorStates[account].wethMarket.positionSize,
                states[1].actorStates[account].wethMarket.positionSize
            ) &&
                MathUtil.abs(
                    states[1].actorStates[account].wethMarket.positionSize
                ) < //wethMarket.positionSize
                MathUtil.abs(
                    states[0].actorStates[account].wethMarket.positionSize
                );
            if (!positionDecreasing) {
                // TODO: DG review same Q abt min credit. Is it general value or per market.
                fl.t(
                    states[1].minimumCredit <=
                        states[1].delegatedCollateralValueUsd,
                    ORD_06_WETH
                );
            }
        } else if (marketId == 2) {
            bool positionDecreasing = MathUtil.sameSide(
                states[0].actorStates[account].wbtcMarket.positionSize,
                states[1].actorStates[account].wbtcMarket.positionSize
            ) &&
                MathUtil.abs(
                    states[1].actorStates[account].wbtcMarket.positionSize
                ) < //wethMarket.positionSize
                MathUtil.abs(
                    states[0].actorStates[account].wbtcMarket.positionSize
                );
            if (!positionDecreasing) {
                fl.t(
                    states[1].minimumCredit <= states[1].delegatedCollateral,
                    ORD_06_WBTC
                );
            }
        }
    }

    function invariant_ORD_07() internal {
        uint256 utilizationBefore = states[0].utilizationRate;
        uint256 utilizationAfter = states[1].utilizationRate;
        fl.log("Utilization before:", utilizationBefore);
        fl.log("Utilization after:", utilizationAfter);
        fl.t(utilizationBefore >= 0 && utilizationBefore <= 1e18, ORD_07);
        fl.t(utilizationAfter >= 0 && utilizationAfter <= 1e18, ORD_07);
    }

    function invariant_ORD_08(uint128 account) internal {
        // TODO: introduce markets
        if (
            states[1].actorStates[account].collateralAmountSUSD >=
            states[0].actorStates[account].collateralAmountSUSD
        ) {
            fl.eq(
                states[0].actorStates[account].collateralAmountWETH,
                states[1].actorStates[account].collateralAmountWETH,
                ORD_08_WETH
            );
            fl.eq(
                states[0].actorStates[account].collateralAmountWBTC,
                states[1].actorStates[account].collateralAmountWBTC,
                ORD_08_WBTC
            );
        }
    }

    event DebugSkew(int128 a, string s);
    event DebugUint(uint256 a, string s);

    function invariant_ORD_09(uint128 account, uint128 marketId) internal {
        // Upscale price to account for -8 exponent.
        //TODO: introduce markets
        bool isLong = states[0].actorStates[account].sizeDelta > 0;
        // Trader gets better price than Pyth price if skew is decreased.

        if (marketId == 1) {
            uint256 oraclePrice = uint256(
                pythWrapper.getBenchmarkPrice(WETH_PYTH_PRICE_FEED_ID, 0)
            );
            console2.log("weth pyth oracle price", oraclePrice);
            console2.log("after skew", states[1].wethMarket.marketSkew);
            console2.log("before skew", states[0].wethMarket.marketSkew);
            if (
                MathUtil.abs(states[1].wethMarket.skew) <
                MathUtil.abs(states[0].wethMarket.skew)
            ) {
                if (isLong) {
                    fl.lt(
                        states[0].actorStates[account].fillPriceWETH,
                        oraclePrice,
                        ORD_09
                    );
                } else {
                    fl.gt(
                        states[0].actorStates[account].fillPriceWETH,
                        oraclePrice,
                        ORD_09
                    );
                }
            }
        } else if (marketId == 2) {
            uint256 oraclePrice = uint256(
                pythWrapper.getBenchmarkPrice(WBTC_PYTH_PRICE_FEED_ID, 0)
            );
            console2.log("wbtc pyth oracle price", oraclePrice);
            console2.log("after skew", states[1].wbtcMarket.skew);
            console2.log("before skew", states[0].wbtcMarket.skew);
            if (
                MathUtil.abs(states[1].wbtcMarket.skew) <
                MathUtil.abs(states[0].wbtcMarket.skew)
            ) {
                if (isLong) {
                    fl.lt(
                        states[0].actorStates[account].fillPriceWBTC,
                        oraclePrice,
                        ORD_09
                    );
                } else {
                    fl.gt(
                        states[0].actorStates[account].fillPriceWBTC,
                        oraclePrice,
                        ORD_09
                    );
                }
            }
        }
    }

    function invariant_ORD_10() internal {
        // utilization rate is always between 0 and 100%
        fl.lte(states[1].utilizationRate, 1e18, ORD_10);
        fl.gte(states[1].utilizationRate, 0, ORD_10);
    }

    function invariant_ORD_11() internal {
        console2.log("reported debt", states[1].reportedDebt);
        console2.log("reportedDebtGhost", states[1].reportedDebtGhost);

        if (
            MathUtil.abs(states[1].reportedDebt - states[1].reportedDebtGhost) >
            1000
        ) {
            fl.eq(states[1].reportedDebt, states[1].reportedDebtGhost, ORD_11);
        }
    }

    function invariant_ORD_12(uint128 account) internal {
        fl.t(!states[1].actorStates[account].isMarginLiquidatable, ORD_12);
    }

    function invariant_ORD_13(uint128 account) internal {
        fl.t(!states[1].actorStates[account].isMarginLiquidatable, ORD_13);
    }

    function invariant_ORD_14() internal {
        fl.eq(
            states[1].wbtcMarket.marketSize + states[1].wethMarket.marketSize,
            states[1].marketSizeGhost,
            ORD_14
        );
    }

    function invariant_ORD_15(uint128 account) internal {
        fl.t(!states[1].actorStates[account].isPositionLiquidatable, ORD_15);
    }

    function invariant_ORD_16(uint128 account) internal {
        fl.t(!states[1].actorStates[account].isPositionLiquidatable, ORD_16);
    }

    //ORD_17 N/A no stale orders here

    function invariant_ORD_18(uint128 account, uint128 marketId) internal {
        if (states[1].actorStates[account].openPositionMarketIds.length != 0) {
            bool containsMarketId = false;
            for (
                uint i = 0;
                i < states[1].actorStates[account].openPositionMarketIds.length;
                i++
            ) {
                if (
                    states[1].actorStates[account].openPositionMarketIds[i] ==
                    marketId
                ) {
                    containsMarketId = true;
                    break;
                }
            }
            fl.t(containsMarketId, ORD_18);
        }
    }

    function invariant_ORD_19(uint128 account) internal {
        uint128[] memory accountCollateralTypes = states[1]
            .actorStates[account]
            .activeCollateralTypes;
        uint128[] memory globalCollateralTypes = states[1]
            .globalCollateralTypes;

        if (accountCollateralTypes.length != 0) {
            for (uint i = 0; i < accountCollateralTypes.length; i++) {
                uint128 collateralType = accountCollateralTypes[i];
                bool found = false;

                for (uint j = 0; j < globalCollateralTypes.length; j++) {
                    if (collateralType == globalCollateralTypes[j]) {
                        found = true;
                        break;
                    }
                }

                fl.t(found, ORD_19);
            }
        }
    }
}
