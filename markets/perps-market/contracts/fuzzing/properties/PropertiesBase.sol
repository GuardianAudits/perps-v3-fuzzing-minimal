// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@perimetersec/fuzzlib/src/FuzzBase.sol";

import "./PropertiesDescriptions.sol";
import "../helper/BeforeAfter.sol";

abstract contract PropertiesBase is
    FuzzBase,
    BeforeAfter,
    PropertiesDescriptions
{
    function eqWithTolerance(
        uint256 a,
        uint256 b,
        uint256 maxPercentDiff,
        string memory reason
    ) internal {
        uint256 percentDiff;

        if (a == b) return;

        if (a > b) {
            percentDiff = ((a - b) * 1e18) / ((a + b) / 2);
        } else {
            percentDiff = ((b - a) * 1e18) / ((a + b) / 2);
        }

        if (percentDiff > maxPercentDiff) {
            fl.log("a>b, a: ", a);
            fl.log("a>b, b:", b);
            fl.log(
                "Percentage difference is bigger than expected",
                percentDiff
            );
            fl.t(false, reason);
        } else {
            fl.t(true, "Invariant ok, ckeched for: ");
            fl.log(reason);
            fl.log("Percentage difference: ", percentDiff);
        }
    }
}
