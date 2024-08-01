// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

abstract contract PreconditionsAdmin is PreconditionsBase {
    struct ChangePythPriceParams {
        int256 newPrice;
        bytes32 id;
    }
    function mintUSDToSynthetixPreconditions(
        uint256 amount
    ) internal returns (uint256) {
        uint256 currentBalance = sUSDTokenMock.balanceOf(address(v3Mock));
        if (currentBalance == 0) return amount;
        return
            fl.clamp(
                amount,
                1,
                (currentBalance * UINT_MAX_SYNTHETIX_USD_CHANGE_BP) /
                    UINT_ONE_HUNDRED_BP
            );
    }

    function burnUSDFromSynthetixPreconditions(
        uint256 amount
    ) internal returns (uint256) {
        uint256 currentBalance = sUSDTokenMock.balanceOf(address(v3Mock));
        return
            fl.clamp(
                amount,
                1,
                (currentBalance * UINT_MAX_SYNTHETIX_USD_CHANGE_BP) /
                    UINT_ONE_HUNDRED_BP
            );
    }
    event DebugPricePre(int256 p, string s);

    function changeOracleManagerPricePreconditions(
        uint256 nodeIndex,
        int256 newPrice
    ) internal returns (int256 clampedPrice, bytes32 nodeId) {
        // clamp nodeId to one of the active collaterals, ignores sUSD node to keep it constant
        nodeId = _getRandomNodeId(nodeIndex);

        int256 currentPrice = mockOracleManager.process(nodeId).price;

        int256 minBound = (currentPrice *
            (INT_ONE_HUNDRED_BP - INT_MAX_CHANGE_BP)) / INT_ONE_HUNDRED_BP; // -20%
        int256 maxBound = (currentPrice *
            (INT_ONE_HUNDRED_BP + INT_MAX_CHANGE_BP)) / INT_ONE_HUNDRED_BP; // +20%

        if (minBound < 500e18) {
            minBound = 500e18; // min ETH price $500
        }

        if (maxBound < minBound) {
            maxBound = minBound;
        }

        clampedPrice = fl.clamp(newPrice, minBound, maxBound);
    }

    function changeWETHPythPricePreconditions(
        int64 newPrice
    ) internal returns (ChangePythPriceParams memory) {
        int256 currentPrice = pythWrapper.getBenchmarkPrice(
            WETH_FEED_ID,
            0 //uint64 requestedTime, irrelevant for mock
        );

        int256 minBound = (currentPrice *
            (INT_ONE_HUNDRED_BP - INT_MAX_CHANGE_BP)) / INT_ONE_HUNDRED_BP; // -20%
        int256 maxBound = (currentPrice *
            (INT_ONE_HUNDRED_BP + INT_MAX_CHANGE_BP)) / INT_ONE_HUNDRED_BP; // +20%

        if (minBound < 500e18) {
            minBound = 500e18; // min ETH price $500
        }

        if (maxBound < minBound) {
            maxBound = minBound;
        }

        int clampedPrice = fl.clamp(newPrice, minBound, maxBound);

        fl.log("changeWETHPythPricePreconditions::newPrice", clampedPrice);

        return
            ChangePythPriceParams({newPrice: clampedPrice, id: WETH_FEED_ID});
    }

    function changeWBTCPythPricePreconditions(
        int128 newPrice
    ) internal returns (ChangePythPriceParams memory) {
        int256 currentPrice = pythWrapper.getBenchmarkPrice(WBTC_FEED_ID, 0);
        emit DebugPricing(currentPrice, "CURRENT PRICE");

        int256 minBound = (currentPrice *
            (INT_ONE_HUNDRED_BP - INT_MAX_CHANGE_BP)) / INT_ONE_HUNDRED_BP; // -20%
        int256 maxBound = (currentPrice *
            (INT_ONE_HUNDRED_BP + INT_MAX_CHANGE_BP)) / INT_ONE_HUNDRED_BP; // +20%

        if (minBound < 500e18) {
            minBound = 500e18; // min WBTC price $500
        }

        if (maxBound < minBound) {
            maxBound = minBound;
        }

        int clampedPrice = fl.clamp(newPrice, minBound, maxBound);

        fl.log("changeWBTCPythPricePreconditions::newPrice", clampedPrice);

        return
            ChangePythPriceParams({newPrice: clampedPrice, id: WBTC_FEED_ID});
    }

    function crashWETHPythPricePreconditions()
        internal
        returns (ChangePythPriceParams memory)
    {
        int256 currentPrice = pythWrapper.getBenchmarkPrice(WETH_FEED_ID, 0);

        int256 newPrice = (currentPrice *
            (INT_ONE_HUNDRED_BP - INT_MAX_CHANGE_BP)) / INT_ONE_HUNDRED_BP;
        int256 clampedPrice = newPrice < int(500e18) ? int(500e18) : newPrice;

        return
            ChangePythPriceParams({newPrice: clampedPrice, id: WETH_FEED_ID});
    }

    function pumpWETHPythPricePreconditions()
        internal
        returns (ChangePythPriceParams memory)
    {
        int256 currentPrice = pythWrapper.getBenchmarkPrice(
            WETH_FEED_ID,
            0 //uint64 requestedTime, irrelevant for mock
        );

        return
            ChangePythPriceParams({
                newPrice: int256(
                    (currentPrice * (INT_ONE_HUNDRED_BP + INT_MAX_CHANGE_BP)) /
                        INT_ONE_HUNDRED_BP
                ),
                id: WETH_FEED_ID
            });
    }

    event DebugPricing(int256 p, string s);
    function crashWBTCPythPricePreconditions()
        internal
        returns (ChangePythPriceParams memory)
    {
        int256 currentPrice = pythWrapper.getBenchmarkPrice(WBTC_FEED_ID, 0);

        int256 newPrice = (currentPrice *
            (INT_ONE_HUNDRED_BP - INT_MAX_CHANGE_BP)) / INT_ONE_HUNDRED_BP;
        int256 clampedPrice = newPrice < int(500e18) ? int(500e18) : newPrice;

        return
            ChangePythPriceParams({newPrice: clampedPrice, id: WBTC_FEED_ID});
    }

    function pumpWBTCPythPricePreconditions()
        internal
        returns (ChangePythPriceParams memory)
    {
        int256 currentPrice = pythWrapper.getBenchmarkPrice(
            WBTC_FEED_ID,
            0 //uint64 requestedTime, irrelevant for mock
        );

        return
            ChangePythPriceParams({
                newPrice: int256(
                    (currentPrice * (INT_ONE_HUNDRED_BP + INT_MAX_CHANGE_BP)) /
                        INT_ONE_HUNDRED_BP
                ),
                id: WBTC_FEED_ID
            });
    }

    function delegateCollateralPreconditions(
        uint256 newCollateralAmountD18,
        uint256 collateralTokenIndex
    )
        internal
        returns (
            uint256 clampedNewCollateralAmountD18,
            address collateralToken,
            uint128 marketId
        )
    {
        clampedNewCollateralAmountD18 = fl.clamp(
            newCollateralAmountD18,
            1,
            100_000_000
        );
        collateralToken = _getRandomCollateralToken(collateralTokenIndex);
        marketId = collateralTokenIndex % 2 == 0 ? 1 : 2;
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? y : x;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? y : x;
    }
}
