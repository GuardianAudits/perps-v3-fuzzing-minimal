//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {Account, AccountRBAC} from "@synthetixio/main/contracts/storage/Account.sol";
import {INodeModule, NodeOutput} from "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import {console2} from "lib/forge-std/src/Test.sol";
interface IMockOracleManager {
    function changePrice(bytes32 nodeId, int256 newPrice) external;

    function process(bytes32 nodeId) external returns (NodeOutput.Data memory node);
}

// solhint-disable-next-line no-empty-blocks
contract MockOracleManager {
    mapping(bytes32 nodeId => NodeOutput.Data) nodes;
    bytes32[] public activeNodes;

    constructor(bytes32[] memory nodeIds, int256[] memory prices) {
        // initialize price for the nodeIds passed in
        for (uint256 i; i < nodeIds.length; i++) {
            nodes[nodeIds[i]] = NodeOutput.Data({
                price: prices[i],
                timestamp: block.timestamp,
                __slotAvailableForFutureUse1: 0,
                __slotAvailableForFutureUse2: 0
            });
            activeNodes.push(nodeIds[i]);
        }
    }

    function getActiveNodesLength() public view returns (uint256) {
        return activeNodes.length;
    }

    function changePrice(bytes32 nodeId, int256 newPrice) external {
        nodes[nodeId].price = newPrice;
    }

    function process(bytes32 nodeId) external view returns (NodeOutput.Data memory node) {
        return nodes[nodeId];
    }

    function processWithRuntime(
        bytes32 nodeId,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) external view returns (NodeOutput.Data memory node) {
        return nodes[nodeId];
    }
}
