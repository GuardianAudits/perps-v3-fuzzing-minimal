// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Properties_ORD.sol";
import "./Properties_LIQ.sol";
import "./Properties_MGN.sol";

abstract contract Properties is Properties_ORD, Properties_MGN, Properties_LIQ {}
