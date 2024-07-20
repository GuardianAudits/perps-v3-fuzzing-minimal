//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;
import {console2} from "lib/forge-std/src/Test.sol";
import {MockOracleManager} from "../fuzzing/mocks/MockOracleManager.sol";

contract MockPythERC7412Wrapper {
    MockOracleManager mockOracleManager;

    bool public alwaysRevert;
    int256 public price;
    mapping(bytes32 => int256) feedToPrice;

    error OracleDataRequired(bytes32 priceId, uint64 requestedTime);

    constructor(address _oracleManager) {
        mockOracleManager = MockOracleManager(_oracleManager);
    }

    function setBenchmarkPrice(bytes32 priceId, int256 _price) external {
        feedToPrice[priceId] = _price;
        mockOracleManager.changePrice(priceId, _price);
        alwaysRevert = false;
    }

    function setAlwaysRevertFlag(bool _alwaysRevert) external {
        alwaysRevert = _alwaysRevert;
    }

    function getBenchmarkPrice(
        bytes32 priceId,
        uint64 requestedTime
    ) external view returns (int256) {
        if (alwaysRevert) {
            revert OracleDataRequired(priceId, requestedTime);
        }

        return feedToPrice[priceId];
    }
}
