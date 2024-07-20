// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FuzzLiquidationModule.sol";
import "./FuzzOrderModule.sol";
import "./FuzzAdmin.sol";
import "./FuzzPerpsAccountModule.sol";

contract FuzzModules is
    FuzzLiquidationModule,
    FuzzPerpsAccountModule,
    FuzzOrderModule,
    FuzzAdmin
{
    function fuzz_guided_createDebt() public setCurrentActor {
        // guidedDone = true;
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getCollateralAmount.selector,
                userToAccountIds[currentActor],
                2
            )
        );
        assert(success);
        uint256 amountWBTC = abi.decode(returnData, (uint256));
        require(amountWBTC > 0, "User needs some collateral");
        fuzz_commitOrder(int128(uint128(amountWBTC) * 2), type(uint256).max);
        fuzz_settleOrder();
        fuzz_crashWBTCPythPrice(1);
        fuzz_commitOrder((int128(uint128(amountWBTC)) * -1), 5);
        fuzz_settleOrder();
        fuzz_crashWBTCPythPrice(10);
        fuzz_liquidateMarginOnly();
    }
}
