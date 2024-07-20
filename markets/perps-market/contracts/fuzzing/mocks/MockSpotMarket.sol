// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "./MockSynthetixV3.sol";
import "./MockOracleManager.sol";
import {SafeCastI256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

contract MockSpotMarket {
    using SafeCastI256 for int256;

    enum TransactionType {
        NULL, // reserved for 0 (default value)
        BUY,
        SELL,
        ASYNC_BUY,
        ASYNC_SELL,
        WRAP,
        UNWRAP
    }

    enum PriceTolerance {
        DEFAULT,
        STRICT
    }

    MockSynthetixV3 v3Mock;
    MockOracleManager mockOracleManager;
    address wethTokenMock;
    address wbtcTokenMock;

    bytes32 WETH_ORACLE_NODE_ID;
    bytes32 WBTC_ORACLE_NODE_ID;
    uint WETH_MARKET_SKEW_SCALE;
    uint WBTC_MARKET_SKEW_SCALE;

    constructor(
        MockSynthetixV3 _v3Mock,
        MockOracleManager _mockOracleManager,
        address _weth,
        uint _wethMarketSkewScale,
        address _wbtc,
        uint _wbtcMarketSkewScale,
        bytes32 _wethOracleNodeId,
        bytes32 _wbtcOracleNodeId
    ) {
        v3Mock = _v3Mock;
        mockOracleManager = _mockOracleManager;
        wethTokenMock = _weth;
        WETH_MARKET_SKEW_SCALE = _wethMarketSkewScale;

        wbtcTokenMock = _wbtc;
        WBTC_MARKET_SKEW_SCALE = _wbtcMarketSkewScale;

        WETH_ORACLE_NODE_ID = _wethOracleNodeId;
        WBTC_ORACLE_NODE_ID = _wbtcOracleNodeId;
    }

    mapping(uint128 marketId => address synthAddress) public synth;

    function setSynthForMarketId(
        uint128[] memory marketIds,
        address[] memory synthAddresses
    ) public {
        require(
            marketIds.length == synthAddresses.length,
            "Input arrays must have the same length"
        );
        for (uint i = 0; i < marketIds.length; i++) {
            synth[marketIds[i]] = synthAddresses[i];
        }
    }

    function getSynth(uint128 marketId) public view returns (address synthAddress) {
        return synth[marketId];
    }

    function getMarketSkewScale(uint128 synthMarketId) external view returns (uint128 skewScale) {
        if (getSynth(synthMarketId) == address(wethTokenMock)) {
            return uint128(WETH_MARKET_SKEW_SCALE);
        }
        if (getSynth(synthMarketId) == address(wbtcTokenMock)) {
            return uint128(WBTC_MARKET_SKEW_SCALE);
        }
    }

    function indexPrice(
        uint128 marketId,
        uint128 transactionType,
        PriceTolerance priceTolerance
    ) public returns (uint256) {
        bytes32 nodeid;

        require(marketId <= 2, "Only 2 markets was implemented");

        TransactionType txnType = loadValidTransactionType(transactionType);

        if (marketId == 1) {
            nodeid = WETH_ORACLE_NODE_ID;
        } else if (marketId == 2) {
            nodeid = WBTC_ORACLE_NODE_ID;
        }

        return mockOracleManager.process(nodeid).price.toUint();

        // return Price.getCurrentPrice(marketId, txnType, priceTolerance);
    }

    function loadValidTransactionType(uint128 txnType) internal pure returns (TransactionType) {
        // solhint-disable-next-line numcast/safe-cast
        uint128 txnTypeMax = uint128(TransactionType.UNWRAP);
        if (txnType > txnTypeMax) {
            revert("Invalid transaction type");
        }
        return TransactionType(txnType);
    }
}
