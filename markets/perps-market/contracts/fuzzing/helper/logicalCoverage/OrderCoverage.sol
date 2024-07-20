// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@perimetersec/fuzzlib/src/FuzzBase.sol";

contract OrderCoverage is FuzzBase {
    function _logOrderInfoCoverage(
        uint128 debt,
        int128 sizeDelta,
        bool isOrderExpired,
        uint256 fillPriceWETH,
        uint256 fillPriceWBTC,
        uint256 sUSDBalance
    ) internal {
        // Debt coverage
        if (debt == 0) {
            fl.log("No debt");
        } else if (debt > 0 && debt <= 100e18) {
            fl.log("Debt between 0 and 100");
        } else if (debt > 100e18 && debt <= 1000e18) {
            fl.log("Debt between 100 and 1,000");
        } else if (debt > 1000e18 && debt <= 10000e18) {
            fl.log("Debt between 1,000 and 10,000");
        } else {
            fl.log("Debt greater than 10,000");
        }

        // Size delta coverage
        if (sizeDelta == 0) {
            fl.log("No size delta");
        } else if (sizeDelta > 0) {
            if (sizeDelta <= 1e18) {
                fl.log("Positive size delta between 0 and 1");
            } else if (sizeDelta <= 10e18) {
                fl.log("Positive size delta between 1 and 10");
            } else {
                fl.log("Positive size delta greater than 10");
            }
        } else {
            if (sizeDelta >= -1e18) {
                fl.log("Negative size delta between 0 and -1");
            } else if (sizeDelta >= -10e18) {
                fl.log("Negative size delta between -1 and -10");
            } else {
                fl.log("Negative size delta less than -10");
            }
        }

        // Order expiration coverage
        if (isOrderExpired) {
            fl.log("Order is expired");
        } else {
            fl.log("Order is not expired");
        }

        // Fill price WETH coverage
        if (fillPriceWETH == 0) {
            fl.log("No WETH fill price");
        } else if (fillPriceWETH > 0 && fillPriceWETH <= 1000e18) {
            fl.log("WETH fill price between 0 and 1,000");
        } else if (fillPriceWETH > 1000e18 && fillPriceWETH <= 2000e18) {
            fl.log("WETH fill price between 1,000 and 2,000");
        } else {
            fl.log("WETH fill price greater than 2,000");
        }

        // Fill price WBTC coverage
        if (fillPriceWBTC == 0) {
            fl.log("No WBTC fill price");
        } else if (fillPriceWBTC > 0 && fillPriceWBTC <= 10000e18) {
            fl.log("WBTC fill price between 0 and 10,000");
        } else if (fillPriceWBTC > 10000e18 && fillPriceWBTC <= 20000e18) {
            fl.log("WBTC fill price between 10,000 and 20,000");
        } else {
            fl.log("WBTC fill price greater than 20,000");
        }

        // sUSD balance coverage
        if (sUSDBalance == 0) {
            fl.log("No sUSD balance");
        } else if (sUSDBalance > 0 && sUSDBalance <= 100e18) {
            fl.log("sUSD balance between 0 and 100");
        } else if (sUSDBalance > 100e18 && sUSDBalance <= 1000e18) {
            fl.log("sUSD balance between 100 and 1,000");
        } else if (sUSDBalance > 1000e18 && sUSDBalance <= 10000e18) {
            fl.log("sUSD balance between 1,000 and 10,000");
        } else {
            fl.log("sUSD balance greater than 10,000");
        }

        // Order type coverage (based on sizeDelta and debt)
        if (sizeDelta > 0 && debt > 0) {
            fl.log("Long position with debt");
        } else if (sizeDelta > 0 && debt == 0) {
            fl.log("Long position without debt");
        } else if (sizeDelta < 0 && debt > 0) {
            fl.log("Short position with debt");
        } else if (sizeDelta < 0 && debt == 0) {
            fl.log("Short position without debt");
        } else if (sizeDelta == 0 && debt > 0) {
            fl.log("No position but has debt");
        } else {
            fl.log("No position and no debt");
        }

        // Price comparison (if both prices are available)
        if (fillPriceWETH > 0 && fillPriceWBTC > 0) {
            if (fillPriceWETH > fillPriceWBTC) {
                fl.log("WETH fill price is higher than WBTC fill price");
            } else if (fillPriceWBTC > fillPriceWETH) {
                fl.log("WBTC fill price is higher than WETH fill price");
            } else {
                fl.log("WETH and WBTC fill prices are equal");
            }
        }
    }
}
