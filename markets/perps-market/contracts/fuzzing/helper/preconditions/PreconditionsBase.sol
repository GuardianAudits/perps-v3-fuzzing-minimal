// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../util/FunctionCalls.sol";
import "../BeforeAfter.sol";

abstract contract PreconditionsBase is FunctionCalls, BeforeAfter {
    modifier setCurrentActor() {
        // if (_setActor) {
        //     currentActor = checkCaller.checkCaller();
        // }
        // if (isFoundry) {
        //     // fl.log("IS FOUNDRY"); <--this emit break vm.prank()
        //     if (_setActor) {
        //         currentActor = checkCaller.checkCaller();
        //     }
        // } else {
        //     fl.log("NOT IS FOUNDRY");

        if (_setActor) {
            // require(guidedDone);
            currentActor = USERS[block.timestamp % (USERS.length)];
            // currentActor = msg.sender;
            fl.log("================================");
            fl.log("CURRENT MSG>SENDRR:", msg.sender);
            vm.prank(currentActor);
        }
        // }
        _;
    }
}
