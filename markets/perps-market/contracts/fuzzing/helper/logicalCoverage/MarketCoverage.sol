// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@perimetersec/fuzzlib/src/FuzzBase.sol";

contract MarketCoverage is FuzzBase {
    function _logMarketInfoCoverage(
        uint256 wethLiquidationCapacity,
        uint256 wbtcLiquidationCapacity,
        uint256 wethMarketSize,
        uint256 wbtcMarketSize
    ) internal {
        _logWETHMarketCoverage(wethLiquidationCapacity, wethMarketSize);

        _logWBTCMarketCoverage(wbtcLiquidationCapacity, wbtcMarketSize);

        // Combined Market Analysis
        _logCombinedMarketAnalysis(
            wethLiquidationCapacity,
            wbtcLiquidationCapacity,
            wethMarketSize,
            wbtcMarketSize
        );
    }

    function _logWETHMarketCoverage(
        uint256 liquidationCapacity,
        uint256 marketSize
    ) internal {
        // Liquidation Capacity Coverage for WETH
        if (liquidationCapacity == 0) {
            fl.log("WETH market: No liquidation capacity");
        } else if (liquidationCapacity <= 1e18) {
            fl.log("WETH market: Low liquidation capacity (0-1)");
        } else if (liquidationCapacity <= 10e18) {
            fl.log("WETH market: Medium liquidation capacity (1-10)");
        } else if (liquidationCapacity <= 100e18) {
            fl.log("WETH market: High liquidation capacity (10-100)");
        } else {
            fl.log("WETH market: Very high liquidation capacity (>100)");
        }

        // Market Size Coverage for WETH
        if (marketSize == 0) {
            fl.log("WETH market: Empty market");
        } else if (marketSize <= 1000e18) {
            fl.log("WETH market: Small market size (0-1000)");
        } else if (marketSize <= 10000e18) {
            fl.log("WETH market: Medium market size (1000-10000)");
        } else if (marketSize <= 100000e18) {
            fl.log("WETH market: Large market size (10000-100000)");
        } else {
            fl.log("WETH market: Very large market size (>100000)");
        }
    }

    function _logWBTCMarketCoverage(
        uint256 liquidationCapacity,
        uint256 marketSize
    ) internal {
        // Liquidation Capacity Coverage for WBTC
        if (liquidationCapacity == 0) {
            fl.log("WBTC market: No liquidation capacity");
        } else if (liquidationCapacity <= 1e18) {
            fl.log("WBTC market: Low liquidation capacity (0-1)");
        } else if (liquidationCapacity <= 10e18) {
            fl.log("WBTC market: Medium liquidation capacity (1-10)");
        } else if (liquidationCapacity <= 100e18) {
            fl.log("WBTC market: High liquidation capacity (10-100)");
        } else {
            fl.log("WBTC market: Very high liquidation capacity (>100)");
        }

        // Market Size Coverage for WBTC
        if (marketSize == 0) {
            fl.log("WBTC market: Empty market");
        } else if (marketSize <= 1000e18) {
            fl.log("WBTC market: Small market size (0-1000)");
        } else if (marketSize <= 10000e18) {
            fl.log("WBTC market: Medium market size (1000-10000)");
        } else if (marketSize <= 100000e18) {
            fl.log("WBTC market: Large market size (10000-100000)");
        } else {
            fl.log("WBTC market: Very large market size (>100000)");
        }
    }

    function _logCombinedMarketAnalysis(
        uint256 wethLiquidationCapacity,
        uint256 wbtcLiquidationCapacity,
        uint256 wethMarketSize,
        uint256 wbtcMarketSize
    ) internal {
        // Compare liquidation capacities
        if (wethLiquidationCapacity > wbtcLiquidationCapacity) {
            fl.log("WETH market has higher liquidation capacity");
        } else if (wbtcLiquidationCapacity > wethLiquidationCapacity) {
            fl.log("WBTC market has higher liquidation capacity");
        } else {
            fl.log("Both markets have equal liquidation capacity");
        }

        // Compare market sizes
        if (wethMarketSize > wbtcMarketSize) {
            fl.log("WETH market is larger");
        } else if (wbtcMarketSize > wethMarketSize) {
            fl.log("WBTC market is larger");
        } else {
            fl.log("Both markets are of equal size");
        }

        // Analyze total market size
        uint256 totalMarketSize = uint256(wethMarketSize) +
            uint256(wbtcMarketSize);
        if (totalMarketSize == 0) {
            fl.log("Both markets are empty");
        } else if (totalMarketSize <= 10000e18) {
            fl.log("Small total market size across both markets");
        } else if (totalMarketSize <= 100000e18) {
            fl.log("Medium total market size across both markets");
        } else {
            fl.log("Large total market size across both markets");
        }
    }
}
