// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

abstract contract PostconditionsAdmin is PostconditionsBase {
    /// NOTE: changes chainlink price to correspond to pyth price
    function changePythPricePostconditions(
        bytes32 nodeId,
        int256 newPrice
    ) internal {
        int256 newPriceWithPrecision = int256(newPrice); //TODO: recheck //* 1e10; // account for 1e18 precision in chainlink oracle
        bytes32 chainlinkNodeId = oracleNodes[nodeId];

        bool isIncrease = newPrice % 2 == 0;

        // only change the chainlink oracle price for index tokens
        if (chainlinkNodeId != bytes32(0)) {
            int256 newPriceWithVariance;
            int256 priceDivergenceBps = fl.clamp(
                newPrice,
                0,
                PRICE_DIVERGENCE_BPS_256
            );
            if (isIncrease) {
                newPriceWithVariance =
                    (newPrice * (priceDivergenceBps + INT_ONE_HUNDRED_BP)) /
                    INT_ONE_HUNDRED_BP;
            } else {
                newPriceWithVariance =
                    (newPrice * (INT_ONE_HUNDRED_BP - priceDivergenceBps)) /
                    INT_ONE_HUNDRED_BP;
            }
            mockOracleManager.changePrice(
                chainlinkNodeId,
                newPriceWithVariance
            );
        }
    }

    /// @notice changes pyth price to correspond to chainlink price
    function changeOracleManagerPricePostconditions(
        bytes32 nodeId,
        int256 newPrice
    ) internal {
        bytes32 pythNodeId = oracleNodes[nodeId];

        bool isIncrease = newPrice % 2 == 0;

        // only change the pyth oracle price for index tokens
        if (pythNodeId != bytes32(0)) {
            int256 newPriceWithVariance;
            int256 priceDivergenceBps = fl.clamp(
                newPrice,
                0,
                PRICE_DIVERGENCE_BPS_256
            );
            if (isIncrease) {
                newPriceWithVariance =
                    (newPrice * (priceDivergenceBps + INT_ONE_HUNDRED_BP)) /
                    INT_ONE_HUNDRED_BP;
            } else {
                newPriceWithVariance =
                    (newPrice * (INT_ONE_HUNDRED_BP - priceDivergenceBps)) /
                    INT_ONE_HUNDRED_BP;
            }
            mockPyth.changePrice(pythNodeId, int64(newPriceWithVariance));
            pythWrapper.setBenchmarkPrice(pythNodeId, newPriceWithVariance);
        }
    }
}
