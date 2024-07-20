// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FuzzLiquidationModule.sol";
import "./FuzzOrderModule.sol";
import "./FuzzAdmin.sol";
import "./FuzzPerpsAccountModule.sol";

contract Fuzz is FuzzLiquidationModule, FuzzPerpsAccountModule, FuzzOrderModule, FuzzAdmin {
    constructor() payable {
        setup();
        setupActors();
    }
}
