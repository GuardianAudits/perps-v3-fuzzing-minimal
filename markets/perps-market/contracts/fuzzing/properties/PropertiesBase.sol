// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@perimetersec/fuzzlib/src/FuzzBase.sol";

import "./PropertiesDescriptions.sol";
import "../helper/BeforeAfter.sol";

abstract contract PropertiesBase is FuzzBase, BeforeAfter, PropertiesDescriptions {}
