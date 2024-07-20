// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../util/FunctionCalls.sol";
import "../BeforeAfter.sol";

abstract contract PreconditionsBase is FunctionCalls, BeforeAfter {
    modifier setCurrentActor() {
        if (_setActor) {
            currentActor = msg.sender;
        }
        _;
    }
}
