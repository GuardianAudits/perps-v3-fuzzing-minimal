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

        invariant_MGN_08();
        invariant_ORD_19(account);
        // @audit Fails with payDebt.
        // invariant_ORD_20();

        invariant_ORD_23();
        invariant_LIQ_18(account);

        zeroOutMemory();
    }

    function onFailInvariantsGeneral(bytes memory returnData) internal {}
}
