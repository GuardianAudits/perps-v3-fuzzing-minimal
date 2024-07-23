// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../properties/Properties.sol";

abstract contract PostconditionsBase is Properties {
    function onSuccessInvariantsGeneral(
        bytes memory returnData,
        uint128 account
    ) internal {
        fl.log(">>ACCOUNT FOR onSuccessInvariantsGeneral", account);
        invariant_LIQ_01(account);
        // @audit Review this assertion for perps market.
        // invariant_ORD_11();
        // invariant_MGN_08(); //TODO: percEq
        invariant_ORD_19(account);
        invariant_ORD_20();
    }

    function onFailInvariantsGeneral(bytes memory returnData) internal {}
}
