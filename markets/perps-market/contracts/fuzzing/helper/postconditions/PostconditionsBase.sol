// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../properties/Properties.sol";

abstract contract PostconditionsBase is Properties {
    function onSuccessInvariantsGeneral(bytes memory returnData, uint128 account) internal {
        // invariant_LIQ_01(account);
        // invariant_LIQ_02(account);
        // invariant_ORD_10();
        // invariant_ORD_11();
        // invariant_ORD_14();
        // invariant_MGN_08(); // TODO: uncomment
    }

    function onFailInvariantsGeneral(bytes memory returnData) internal {}
}
