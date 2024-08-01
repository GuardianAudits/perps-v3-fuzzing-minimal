// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@perimetersec/fuzzlib/src/FuzzBase.sol";

contract LiquidationCoverage is FuzzBase {
    function _logLiquidateMarginOnlyCoverage(
        uint lcov_liquidateMarginOnlyCovered
    ) internal {
        if (lcov_liquidateMarginOnlyCovered == 1) {
            fl.log("Hit MarginOnly once");
        } else if (
            lcov_liquidateMarginOnlyCovered > 1 &&
            lcov_liquidateMarginOnlyCovered < 10
        ) {
            fl.log("Hit MarginOnly up to 10 times");
        } else if (lcov_liquidateMarginOnlyCovered > 10) {
            fl.log("Hit MarginOnly more than 10 times");
        }
    }

    function _logLiquidatableCoverage(
        bool isPositionLiquidatable,
        bool isMarginLiquidatable
    ) internal {
        if (isPositionLiquidatable && isMarginLiquidatable) {
            fl.log("Both position and margin are liquidatable");
        } else if (isPositionLiquidatable) {
            fl.log("Only position is liquidatable");
        } else if (isMarginLiquidatable) {
            fl.log("Only margin is liquidatable");
        } else {
            fl.log("Neither position nor margin is liquidatable");
        }
    }

    function _logCollateralIdsCoverage(
        uint256[] memory collateralIds
    ) internal {
        if (collateralIds.length == 0) {
            fl.log("No collateral IDs");
        } else if (collateralIds.length == 1) {
            fl.log("One collateral ID");
        } else if (collateralIds.length == 2) {
            fl.log("Two collateral IDs");
        } else if (collateralIds.length == 3) {
            fl.log("Three collateral IDs");
        } else {
            fl.log("More than three collateral IDs");
        }

        for (uint256 i = 0; i < collateralIds.length; i++) {
            if (collateralIds[i] == 0) {
                fl.log("Collateral ID 0 (SUSD) present");
            } else if (collateralIds[i] == 1) {
                fl.log("Collateral ID 1 (WETH) present");
            } else if (collateralIds[i] == 2) {
                fl.log("Collateral ID 2 (WBTC) present");
            } else {
                fl.log("Unknown collateral ID present");
            }
        }
    }

    function _logCollateralAmountsCoverage(
        uint256 susdAmount,
        uint256 wethAmount,
        uint256 wbtcAmount,
        uint256 totalValue
    ) internal {
        // SUSD coverage
        if (susdAmount == 0) {
            fl.log("No SUSD collateral");
        } else if (susdAmount > 0 && susdAmount <= 100e18) {
            fl.log("SUSD collateral between 0 and 100");
        } else if (susdAmount > 100e18 && susdAmount <= 1000e18) {
            fl.log("SUSD collateral between 100 and 1,000");
        } else if (susdAmount > 1000e18 && susdAmount <= 10000e18) {
            fl.log("SUSD collateral between 1,000 and 10,000");
        } else {
            fl.log("SUSD collateral greater than 10,000");
        }

        // WETH coverage
        if (wethAmount == 0) {
            fl.log("No WETH collateral");
        } else if (wethAmount > 0 && wethAmount <= 1e18) {
            fl.log("WETH collateral between 0 and 1");
        } else if (wethAmount > 1e18 && wethAmount <= 10e18) {
            fl.log("WETH collateral between 1 and 10");
        } else if (wethAmount > 10e18 && wethAmount <= 100e18) {
            fl.log("WETH collateral between 10 and 100");
        } else {
            fl.log("WETH collateral greater than 100");
        }

        // WBTC coverage (assuming 8 decimal places)
        if (wbtcAmount == 0) {
            fl.log("No WBTC collateral");
        } else if (wbtcAmount > 0 && wbtcAmount <= 1e18) {
            fl.log("WBTC collateral between 0 and 1");
        } else if (wbtcAmount > 1e8 && wbtcAmount <= 10e18) {
            fl.log("WBTC collateral between 1 and 10");
        } else if (wbtcAmount > 10e8 && wbtcAmount <= 100e18) {
            fl.log("WBTC collateral between 10 and 100");
        } else {
            fl.log("WBTC collateral greater than 100");
        }

        // Total collateral value coverage
        if (totalValue == 0) {
            fl.log("Total collateral value is zero");
        } else if (totalValue > 0 && totalValue <= 100e18) {
            fl.log("Total collateral value between 0 and 100 ETH");
        } else if (totalValue > 100e18 && totalValue <= 1000e18) {
            fl.log("Total collateral value between 100 and 1,000 ETH");
        } else if (totalValue > 1000e18 && totalValue <= 10000e18) {
            fl.log("Total collateral value between 1,000 and 10,000 ETH");
        } else if (totalValue > 10000e18 && totalValue <= 100000e18) {
            fl.log("Total collateral value between 10,000 and 100,000 ETH");
        } else {
            fl.log("Total collateral value greater than 100,000 ETH");
        }

        // Composition coverage
        if (susdAmount > 0 && wethAmount > 0 && wbtcAmount > 0) {
            fl.log("All three collateral types present");
        } else if (susdAmount > 0 && wethAmount > 0) {
            fl.log("SUSD and WETH collateral present");
        } else if (susdAmount > 0 && wbtcAmount > 0) {
            fl.log("SUSD and WBTC collateral present");
        } else if (wethAmount > 0 && wbtcAmount > 0) {
            fl.log("WETH and WBTC collateral present");
        } else if (susdAmount > 0) {
            fl.log("Only SUSD collateral present");
        } else if (wethAmount > 0) {
            fl.log("Only WETH collateral present");
        } else if (wbtcAmount > 0) {
            fl.log("Only WBTC collateral present");
        } else {
            fl.log("No collateral present");
        }

        // Dominant collateral type
        if (susdAmount > wethAmount && susdAmount > wbtcAmount) {
            fl.log("SUSD is the dominant collateral type");
        } else if (wethAmount > susdAmount && wethAmount > wbtcAmount) {
            fl.log("WETH is the dominant collateral type");
        } else if (wbtcAmount > susdAmount && wbtcAmount > wethAmount) {
            fl.log("WBTC is the dominant collateral type");
        } else {
            fl.log("No single dominant collateral type");
        }
    }
}
