//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {Account, AccountRBAC} from "@synthetixio/main/contracts/storage/Account.sol";

// solhint-disable-next-line no-empty-blocks
contract MockModule {
    function createAccount(uint128 id, address owner) external {
        Account.create(id, owner);
    }

    function grantPermission(uint128 accountId, bytes32 permission, address user) external {
        Account.Data storage account = Account.load(accountId);
        AccountRBAC.grantPermission(account.rbac, permission, user);
    }
}
