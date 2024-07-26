// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@perimetersec/fuzzlib/src/FuzzBase.sol";

contract GlobalCoverage is FuzzBase {
    function _logGlobalCollateralValuesCoverage(
        uint256 depositedSusdCollateral,
        uint256 depositedWethCollateral,
        uint256 depositedWbtcCollateral,
        uint256 totalCollateralValueUsd,
        uint256 totalCollateralValueUsdGhost,
        int128 skew
    ) internal {
        _logSusdCollateralCoverage(depositedSusdCollateral);
        _logWethCollateralCoverage(depositedWethCollateral);
        _logWbtcCollateralCoverage(depositedWbtcCollateral);
        _logTotalCollateralValueCoverage(
            totalCollateralValueUsd,
            totalCollateralValueUsdGhost
        );
        _logSkewCoverage(skew);
    }

    function _logSusdCollateralCoverage(
        uint256 depositedSusdCollateral
    ) internal {
        if (depositedSusdCollateral == 0) {
            fl.log("No SUSD collateral deposited");
        } else if (depositedSusdCollateral <= 1000e18) {
            fl.log("Low SUSD collateral (0-1000)");
        } else if (depositedSusdCollateral <= 10000e18) {
            fl.log("Medium SUSD collateral (1000-10000)");
        } else if (depositedSusdCollateral <= 100000e18) {
            fl.log("High SUSD collateral (10000-100000)");
        } else {
            fl.log("Very high SUSD collateral (>100000)");
        }
    }

    function _logWethCollateralCoverage(
        uint256 depositedWethCollateral
    ) internal {
        if (depositedWethCollateral == 0) {
            fl.log("No WETH collateral deposited");
        } else if (depositedWethCollateral <= 10e18) {
            fl.log("Low WETH collateral (0-10)");
        } else if (depositedWethCollateral <= 100e18) {
            fl.log("Medium WETH collateral (10-100)");
        } else if (depositedWethCollateral <= 1000e18) {
            fl.log("High WETH collateral (100-1000)");
        } else {
            fl.log("Very high WETH collateral (>1000)");
        }
    }

    function _logWbtcCollateralCoverage(
        uint256 depositedWbtcCollateral
    ) internal {
        if (depositedWbtcCollateral == 0) {
            fl.log("No WBTC collateral deposited");
        } else if (depositedWbtcCollateral <= 1e8) {
            fl.log("Low WBTC collateral (0-1)");
        } else if (depositedWbtcCollateral <= 10e8) {
            fl.log("Medium WBTC collateral (1-10)");
        } else if (depositedWbtcCollateral <= 100e8) {
            fl.log("High WBTC collateral (10-100)");
        } else {
            fl.log("Very high WBTC collateral (>100)");
        }
    }

    function _logTotalCollateralValueCoverage(
        uint256 totalCollateralValueUsd,
        uint256 totalCollateralValueUsdGhost
    ) internal {
        if (totalCollateralValueUsd == 0) {
            fl.log("No total collateral value");
        } else if (totalCollateralValueUsd <= 10000e18) {
            fl.log("Low total collateral value (0-10000)");
        } else if (totalCollateralValueUsd <= 100000e18) {
            fl.log("Medium total collateral value (10000-100000)");
        } else if (totalCollateralValueUsd <= 1000000e18) {
            fl.log("High total collateral value (100000-1000000)");
        } else {
            fl.log("Very high total collateral value (>1000000)");
        }

        if (totalCollateralValueUsd == totalCollateralValueUsdGhost) {
            fl.log("Total collateral value matches ghost value");
        } else if (totalCollateralValueUsd > totalCollateralValueUsdGhost) {
            fl.log("Total collateral value higher than ghost value");
        } else {
            fl.log("Total collateral value lower than ghost value");
        }
    }

    function _logSkewCoverage(int128 skew) internal {
        if (skew == 0) {
            fl.log("No market skew");
        } else if (skew > 0) {
            if (skew <= 1000e18) {
                fl.log("Small positive market skew (0-1000)");
            } else if (skew <= 10000e18) {
                fl.log("Medium positive market skew (1000-10000)");
            } else {
                fl.log("Large positive market skew (>10000)");
            }
        } else {
            if (skew >= -1000e18) {
                fl.log("Small negative market skew (0 to -1000)");
            } else if (skew >= -10000e18) {
                fl.log("Medium negative market skew (-1000 to -10000)");
            } else {
                fl.log("Large negative market skew (<-10000)");
            }
        }
    }
    function _logUtilizationInfoCoverage(
        uint256 minimumCredit,
        uint256 utilizationRate,
        uint256 delegatedCollateral,
        uint256 lockedCredit
    ) internal {
        // Minimum Credit Coverage
        if (minimumCredit == 0) {
            fl.log("No minimum credit set");
        } else if (minimumCredit <= 1000e18) {
            fl.log("Low minimum credit (0-1000)");
        } else if (minimumCredit <= 10000e18) {
            fl.log("Medium minimum credit (1000-10000)");
        } else {
            fl.log("High minimum credit (>10000)");
        }

        // Utilization Rate Coverage
        if (utilizationRate == 0) {
            fl.log("No utilization");
        } else if (utilizationRate <= 2000) {
            // Assuming utilization rate is in basis points (0.01% = 1)
            fl.log("Low utilization rate (0-20%)");
        } else if (utilizationRate <= 5000) {
            fl.log("Medium utilization rate (20-50%)");
        } else if (utilizationRate <= 8000) {
            fl.log("High utilization rate (50-80%)");
        } else {
            fl.log("Very high utilization rate (>80%)");
        }

        // Delegated Collateral Coverage
        if (delegatedCollateral == 0) {
            fl.log("No delegated collateral");
        } else if (delegatedCollateral <= 1000e18) {
            fl.log("Low delegated collateral (0-1000)");
        } else if (delegatedCollateral <= 10000e18) {
            fl.log("Medium delegated collateral (1000-10000)");
        } else {
            fl.log("High delegated collateral (>10000)");
        }

        // Locked Credit Coverage
        if (lockedCredit == 0) {
            fl.log("No locked credit");
        } else if (lockedCredit <= 1000e18) {
            fl.log("Low locked credit (0-1000)");
        } else if (lockedCredit <= 10000e18) {
            fl.log("Medium locked credit (1000-10000)");
        } else {
            fl.log("High locked credit (>10000)");
        }

        // Relationship between delegated collateral and locked credit
        if (delegatedCollateral > lockedCredit) {
            fl.log("Delegated collateral exceeds locked credit");
        } else if (delegatedCollateral < lockedCredit) {
            fl.log("Locked credit exceeds delegated collateral");
        } else {
            fl.log("Delegated collateral equals locked credit");
        }
    }

    function _logMarginInfoCoverage(
        int256 availableMargin,
        uint256 requiredInitialMargin,
        uint256 requiredMaintenanceMargin,
        uint256 maxLiquidationReward
    ) internal {
        // Available Margin Coverage
        if (availableMargin < 0) {
            fl.log("Negative available margin");
        } else if (availableMargin == 0) {
            fl.log("Zero available margin");
        } else if (availableMargin <= 1000e18) {
            fl.log("Low available margin (0-1000)");
        } else if (availableMargin <= 10000e18) {
            fl.log("Medium available margin (1000-10000)");
        } else {
            fl.log("High available margin (>10000)");
        }

        // Required Initial Margin Coverage
        if (requiredInitialMargin == 0) {
            fl.log("No required initial margin");
        } else if (requiredInitialMargin <= 1000e18) {
            fl.log("Low required initial margin (0-1000)");
        } else if (requiredInitialMargin <= 10000e18) {
            fl.log("Medium required initial margin (1000-10000)");
        } else {
            fl.log("High required initial margin (>10000)");
        }

        // Required Maintenance Margin Coverage
        if (requiredMaintenanceMargin == 0) {
            fl.log("No required maintenance margin");
        } else if (requiredMaintenanceMargin <= 500e18) {
            fl.log("Low required maintenance margin (0-500)");
        } else if (requiredMaintenanceMargin <= 5000e18) {
            fl.log("Medium required maintenance margin (500-5000)");
        } else {
            fl.log("High required maintenance margin (>5000)");
        }

        // Max Liquidation Reward Coverage
        if (maxLiquidationReward == 0) {
            fl.log("No max liquidation reward");
        } else if (maxLiquidationReward <= 10e18) {
            fl.log("Low max liquidation reward (0-10)");
        } else if (maxLiquidationReward <= 100e18) {
            fl.log("Medium max liquidation reward (10-100)");
        } else {
            fl.log("High max liquidation reward (>100)");
        }

        // Relationship between margins
        if (int256(requiredInitialMargin) > availableMargin) {
            fl.log("Available margin below required initial margin");
        } else if (int256(requiredMaintenanceMargin) > availableMargin) {
            fl.log("Available margin below required maintenance margin");
        } else {
            fl.log("Available margin above both required margins");
        }
    }

    function _logReportedDebtGhostCoverage(
        int256 reportedDebtGhost,
        uint256 marketSizeGhost
    ) internal {
        // Reported Debt Ghost Coverage
        if (reportedDebtGhost == 0) {
            fl.log("No reported debt ghost");
        } else if (reportedDebtGhost > 0) {
            if (reportedDebtGhost <= 1000e18) {
                fl.log("Low positive reported debt ghost (0-1000)");
            } else if (reportedDebtGhost <= 10000e18) {
                fl.log("Medium positive reported debt ghost (1000-10000)");
            } else {
                fl.log("High positive reported debt ghost (>10000)");
            }
        } else {
            if (reportedDebtGhost >= -1000e18) {
                fl.log("Low negative reported debt ghost (0 to -1000)");
            } else if (reportedDebtGhost >= -10000e18) {
                fl.log("Medium negative reported debt ghost (-1000 to -10000)");
            } else {
                fl.log("High negative reported debt ghost (<-10000)");
            }
        }

        // Market Size Ghost Coverage
        if (marketSizeGhost == 0) {
            fl.log("No market size ghost");
        } else if (marketSizeGhost <= 1000e18) {
            fl.log("Low market size ghost (0-1000)");
        } else if (marketSizeGhost <= 10000e18) {
            fl.log("Medium market size ghost (1000-10000)");
        } else {
            fl.log("High market size ghost (>10000)");
        }

        // Relationship between reported debt ghost and market size ghost
        if (abs(reportedDebtGhost) > int256(marketSizeGhost)) {
            fl.log("Absolute reported debt ghost exceeds market size ghost");
        } else {
            fl.log(
                "Market size ghost exceeds or equals absolute reported debt ghost"
            );
        }
    }
    // Helper function to get absolute value of int256
    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}
