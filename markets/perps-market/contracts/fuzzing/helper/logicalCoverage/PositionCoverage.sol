// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@perimetersec/fuzzlib/src/FuzzBase.sol";

contract PositionCoverage is FuzzBase {
    function _logPositionInfoCoverage(
        int256 wethTotalPnl,
        int256 wethAccruedFunding,
        int128 wethPositionSize,
        uint256 wethOwedInterest,
        int256 wbtcTotalPnl,
        int256 wbtcAccruedFunding,
        int128 wbtcPositionSize,
        uint256 wbtcOwedInterest
    ) internal {
        // WETH market coverage
        _logWethMarketCoverage(
            wethTotalPnl,
            wethAccruedFunding,
            wethPositionSize,
            wethOwedInterest
        );

        // WBTC market coverage
        _logWbtcMarketCoverage(
            wbtcTotalPnl,
            wbtcAccruedFunding,
            wbtcPositionSize,
            wbtcOwedInterest
        );

        // Combined market analysis
        _logCombinedMarketAnalysis(
            wethPositionSize,
            wbtcPositionSize,
            wethTotalPnl,
            wbtcTotalPnl,
            wethOwedInterest,
            wbtcOwedInterest
        );
    }

    function _logWethMarketCoverage(
        int256 totalPnl,
        int256 accruedFunding,
        int128 positionSize,
        uint256 owedInterest
    ) internal {
        // WETH Position size coverage
        if (positionSize == 0) {
            fl.log("WETH market: No open position");
        } else if (positionSize > 0) {
            if (positionSize <= 0.1e18) {
                fl.log("WETH market: Long position between 0 and 0.1");
            } else if (positionSize <= 1e18) {
                fl.log("WETH market: Long position between 0.1 and 1");
            } else if (positionSize <= 10e18) {
                fl.log("WETH market: Long position between 1 and 10");
            } else if (positionSize <= 100e18) {
                fl.log("WETH market: Long position between 10 and 100");
            } else {
                fl.log("WETH market: Long position greater than 100");
            }
        } else {
            if (positionSize >= -0.1e18) {
                fl.log("WETH market: Short position between 0 and -0.1");
            } else if (positionSize >= -1e18) {
                fl.log("WETH market: Short position between -0.1 and -1");
            } else if (positionSize >= -10e18) {
                fl.log("WETH market: Short position between -1 and -10");
            } else if (positionSize >= -100e18) {
                fl.log("WETH market: Short position between -10 and -100");
            } else {
                fl.log("WETH market: Short position less than -100");
            }
        }

        // WETH Total PnL coverage
        if (totalPnl == 0) {
            fl.log("WETH market: Zero PnL");
        } else if (totalPnl > 0) {
            if (totalPnl <= 0.1e18) {
                fl.log("WETH market: Profit between 0 and 0.1");
            } else if (totalPnl <= 1e18) {
                fl.log("WETH market: Profit between 0.1 and 1");
            } else if (totalPnl <= 10e18) {
                fl.log("WETH market: Profit between 1 and 10");
            } else if (totalPnl <= 100e18) {
                fl.log("WETH market: Profit between 10 and 100");
            } else {
                fl.log("WETH market: Profit greater than 100");
            }
        } else {
            if (totalPnl >= -0.1e18) {
                fl.log("WETH market: Loss between 0 and -0.1");
            } else if (totalPnl >= -1e18) {
                fl.log("WETH market: Loss between -0.1 and -1");
            } else if (totalPnl >= -10e18) {
                fl.log("WETH market: Loss between -1 and -10");
            } else if (totalPnl >= -100e18) {
                fl.log("WETH market: Loss between -10 and -100");
            } else {
                fl.log("WETH market: Loss less than -100");
            }
        }

        // WETH Accrued funding coverage
        if (accruedFunding == 0) {
            fl.log("WETH market: No accrued funding");
        } else if (accruedFunding > 0) {
            if (accruedFunding <= 0.01e18) {
                fl.log("WETH market: Positive accrued funding between 0 and 0.01");
            } else if (accruedFunding <= 0.1e18) {
                fl.log("WETH market: Positive accrued funding between 0.01 and 0.1");
            } else if (accruedFunding <= 1e18) {
                fl.log("WETH market: Positive accrued funding between 0.1 and 1");
            } else {
                fl.log("WETH market: Positive accrued funding greater than 1");
            }
        } else {
            if (accruedFunding >= -0.01e18) {
                fl.log("WETH market: Negative accrued funding between 0 and -0.01");
            } else if (accruedFunding >= -0.1e18) {
                fl.log("WETH market: Negative accrued funding between -0.01 and -0.1");
            } else if (accruedFunding >= -1e18) {
                fl.log("WETH market: Negative accrued funding between -0.1 and -1");
            } else {
                fl.log("WETH market: Negative accrued funding less than -1");
            }
        }

        // WETH Owed interest coverage
        if (owedInterest == 0) {
            fl.log("WETH market: No owed interest");
        } else if (owedInterest <= 0.01e18) {
            fl.log("WETH market: Owed interest between 0 and 0.01");
        } else if (owedInterest <= 0.1e18) {
            fl.log("WETH market: Owed interest between 0.01 and 0.1");
        } else if (owedInterest <= 1e18) {
            fl.log("WETH market: Owed interest between 0.1 and 1");
        } else if (owedInterest <= 10e18) {
            fl.log("WETH market: Owed interest between 1 and 10");
        } else {
            fl.log("WETH market: Owed interest greater than 10");
        }
    }

    function _logWbtcMarketCoverage(
        int256 totalPnl,
        int256 accruedFunding,
        int128 positionSize,
        uint256 owedInterest
    ) internal {
        // WBTC Position size coverage
        if (positionSize == 0) {
            fl.log("WBTC market: No open position");
        } else if (positionSize > 0) {
            if (positionSize <= 0.01e8) {
                fl.log("WBTC market: Long position between 0 and 0.01");
            } else if (positionSize <= 0.1e8) {
                fl.log("WBTC market: Long position between 0.01 and 0.1");
            } else if (positionSize <= 1e8) {
                fl.log("WBTC market: Long position between 0.1 and 1");
            } else if (positionSize <= 10e8) {
                fl.log("WBTC market: Long position between 1 and 10");
            } else {
                fl.log("WBTC market: Long position greater than 10");
            }
        } else {
            if (positionSize >= -0.01e8) {
                fl.log("WBTC market: Short position between 0 and -0.01");
            } else if (positionSize >= -0.1e8) {
                fl.log("WBTC market: Short position between -0.01 and -0.1");
            } else if (positionSize >= -1e8) {
                fl.log("WBTC market: Short position between -0.1 and -1");
            } else if (positionSize >= -10e8) {
                fl.log("WBTC market: Short position between -1 and -10");
            } else {
                fl.log("WBTC market: Short position less than -10");
            }
        }

        // WBTC Total PnL coverage
        if (totalPnl == 0) {
            fl.log("WBTC market: Zero PnL");
        } else if (totalPnl > 0) {
            if (totalPnl <= 0.01e8) {
                fl.log("WBTC market: Profit between 0 and 0.01");
            } else if (totalPnl <= 0.1e8) {
                fl.log("WBTC market: Profit between 0.01 and 0.1");
            } else if (totalPnl <= 1e8) {
                fl.log("WBTC market: Profit between 0.1 and 1");
            } else if (totalPnl <= 10e8) {
                fl.log("WBTC market: Profit between 1 and 10");
            } else {
                fl.log("WBTC market: Profit greater than 10");
            }
        } else {
            if (totalPnl >= -0.01e8) {
                fl.log("WBTC market: Loss between 0 and -0.01");
            } else if (totalPnl >= -0.1e8) {
                fl.log("WBTC market: Loss between -0.01 and -0.1");
            } else if (totalPnl >= -1e8) {
                fl.log("WBTC market: Loss between -0.1 and -1");
            } else if (totalPnl >= -10e8) {
                fl.log("WBTC market: Loss between -1 and -10");
            } else {
                fl.log("WBTC market: Loss less than -10");
            }
        }

        // WBTC Accrued funding coverage
        if (accruedFunding == 0) {
            fl.log("WBTC market: No accrued funding");
        } else if (accruedFunding > 0) {
            if (accruedFunding <= 0.001e8) {
                fl.log("WBTC market: Positive accrued funding between 0 and 0.001");
            } else if (accruedFunding <= 0.01e8) {
                fl.log("WBTC market: Positive accrued funding between 0.001 and 0.01");
            } else if (accruedFunding <= 0.1e8) {
                fl.log("WBTC market: Positive accrued funding between 0.01 and 0.1");
            } else {
                fl.log("WBTC market: Positive accrued funding greater than 0.1");
            }
        } else {
            if (accruedFunding >= -0.001e8) {
                fl.log("WBTC market: Negative accrued funding between 0 and -0.001");
            } else if (accruedFunding >= -0.01e8) {
                fl.log("WBTC market: Negative accrued funding between -0.001 and -0.01");
            } else if (accruedFunding >= -0.1e8) {
                fl.log("WBTC market: Negative accrued funding between -0.01 and -0.1");
            } else {
                fl.log("WBTC market: Negative accrued funding less than -0.1");
            }
        }

        // WBTC Owed interest coverage
        if (owedInterest == 0) {
            fl.log("WBTC market: No owed interest");
        } else if (owedInterest <= 0.001e8) {
            fl.log("WBTC market: Owed interest between 0 and 0.001");
        } else if (owedInterest <= 0.01e8) {
            fl.log("WBTC market: Owed interest between 0.001 and 0.01");
        } else if (owedInterest <= 0.1e8) {
            fl.log("WBTC market: Owed interest between 0.01 and 0.1");
        } else if (owedInterest <= 1e8) {
            fl.log("WBTC market: Owed interest between 0.1 and 1");
        } else {
            fl.log("WBTC market: Owed interest greater than 1");
        }
    }

    function _logCombinedMarketAnalysis(
        int128 wethPositionSize,
        int128 wbtcPositionSize,
        int256 wethTotalPnl,
        int256 wbtcTotalPnl,
        uint256 wethOwedInterest,
        uint256 wbtcOwedInterest
    ) internal {
        if (wethPositionSize != 0 && wbtcPositionSize != 0) {
            fl.log("Positions open in both WETH and WBTC markets");
            if (
                (wethPositionSize > 0 && wbtcPositionSize > 0) ||
                (wethPositionSize < 0 && wbtcPositionSize < 0)
            ) {
                fl.log("Both positions are in the same direction");
            } else {
                fl.log("Positions are in opposite directions");
            }
        } else if (wethPositionSize != 0) {
            fl.log("Position open only in WETH market");
        } else if (wbtcPositionSize != 0) {
            fl.log("Position open only in WBTC market");
        } else {
            fl.log("No open positions in either market");
        }

        // Total PnL analysis
        int256 totalPnl = wethTotalPnl + wbtcTotalPnl;
        if (totalPnl > 0) {
            fl.log("Overall position is profitable");
            if (wethTotalPnl > 0 && wbtcTotalPnl > 0) {
                fl.log("Both markets are profitable");
            } else {
                fl.log("One market is profitable, the other is at a loss");
            }
        } else if (totalPnl < 0) {
            fl.log("Overall position is at a loss");
            if (wethTotalPnl < 0 && wbtcTotalPnl < 0) {
                fl.log("Both markets are at a loss");
            } else {
                fl.log("One market is at a loss, the other is profitable");
            }
        } else {
            fl.log("Overall position has zero PnL");
        }

        // Total owed interest analysis
        // Total owed interest analysis
        uint256 totalOwedInterest = wethOwedInterest + wbtcOwedInterest;
        if (totalOwedInterest == 0) {
            fl.log("No owed interest in either market");
        } else {
            fl.log("Owed interest present");
            if (wethOwedInterest > 0 && wbtcOwedInterest > 0) {
                fl.log("Both markets have owed interest");
            } else if (wethOwedInterest > 0) {
                fl.log("Only WETH market has owed interest");
            } else {
                fl.log("Only WBTC market has owed interest");
            }

            if (totalOwedInterest <= 0.01e18) {
                fl.log("Total owed interest between 0 and 0.01");
            } else if (totalOwedInterest <= 0.1e18) {
                fl.log("Total owed interest between 0.01 and 0.1");
            } else if (totalOwedInterest <= 1e18) {
                fl.log("Total owed interest between 0.1 and 1");
            } else if (totalOwedInterest <= 10e18) {
                fl.log("Total owed interest between 1 and 10");
            } else {
                fl.log("Total owed interest greater than 10");
            }

            if (wethOwedInterest > wbtcOwedInterest) {
                fl.log("WETH market has higher owed interest");
            } else if (wbtcOwedInterest > wethOwedInterest) {
                fl.log("WBTC market has higher owed interest");
            } else {
                fl.log("Both markets have equal owed interest");
            }
        }

        // Position size comparison
        if (wethPositionSize != 0 && wbtcPositionSize != 0) {
            if (abs(wethPositionSize) > abs(wbtcPositionSize)) {
                fl.log("WETH position size is larger");
            } else if (abs(wbtcPositionSize) > abs(wethPositionSize)) {
                fl.log("WBTC position size is larger");
            } else {
                fl.log("Both positions have equal size");
            }
        }

        // PnL comparison
        if (wethTotalPnl != 0 || wbtcTotalPnl != 0) {
            if (wethTotalPnl > wbtcTotalPnl) {
                fl.log("WETH market has higher PnL");
            } else if (wbtcTotalPnl > wethTotalPnl) {
                fl.log("WBTC market has higher PnL");
            } else {
                fl.log("Both markets have equal PnL");
            }
        }

        // Overall market status
        if (wethPositionSize == 0 && wbtcPositionSize == 0 && totalOwedInterest == 0) {
            fl.log("No active positions or owed interest in either market");
        } else if (wethPositionSize != 0 || wbtcPositionSize != 0) {
            if (totalPnl > 0 && totalOwedInterest == 0) {
                fl.log("Profitable position(s) with no owed interest");
            } else if (totalPnl > 0 && totalOwedInterest > 0) {
                fl.log("Profitable position(s) with owed interest");
            } else if (totalPnl < 0 && totalOwedInterest == 0) {
                fl.log("Loss-making position(s) with no owed interest");
            } else if (totalPnl < 0 && totalOwedInterest > 0) {
                fl.log("Loss-making position(s) with owed interest");
            } else if (totalPnl == 0 && totalOwedInterest > 0) {
                fl.log("Neutral position(s) with owed interest");
            } else {
                fl.log("Neutral position(s) with no owed interest");
            }
        } else {
            fl.log("No active positions but owed interest present");
        }
    }

    // Helper function to get absolute value of int128
    function abs(int128 x) private pure returns (int128) {
        return x >= 0 ? x : -x;
    }
}
