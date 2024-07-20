// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FuzzModules.sol";

contract Fuzz is FuzzModules {
    constructor() payable {
        setup();
        setupActors();
    }
}
