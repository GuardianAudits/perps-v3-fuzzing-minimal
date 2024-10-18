// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {MockSynthetixV3} from "./MockSynthetixV3.sol";
import {PerpsMarketFactoryModule} from "../../modules/PerpsMarketFactoryModule.sol";
import {console2} from "lib/forge-std/src/Test.sol";

contract MockVaultModule {
    MockSynthetixV3 internal v3Mock;
    PerpsMarketFactoryModule internal perpMarketFactoryModuleImpl;
    address internal perps;

    constructor(MockSynthetixV3 _v3Mock, address _perps) {
        v3Mock = _v3Mock;
        perps = _perps;
    }

    function setPerpMarketFactoryModuleImpl(
        PerpsMarketFactoryModule _perpMarketFactoryModuleImpl
    ) external {
        perpMarketFactoryModuleImpl = _perpMarketFactoryModuleImpl;
    }

    function delegateCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newCollateralAmountD18,
        uint256 leverage,
        uint128 marketId
    ) external {
        uint256 currentCreditCapacity = v3Mock.creditCapacity();
        newCollateralAmountD18 = newCollateralAmountD18 % 10_000_000 ether;

        bool increase;
        // simplifying collateral delegation system from vault by increasing if adding more than current credit capacity and decreasing if less
        if (newCollateralAmountD18 > currentCreditCapacity) {
            increase = true;
            v3Mock.updateCreditCapacity(newCollateralAmountD18, increase);
        } else {
            // if market is below minimumCredit, LPs are blocked from withdrawals
            (bool success, bytes memory returnData) = perps.call(
                abi.encodeWithSelector(perpMarketFactoryModuleImpl.minimumCredit.selector, marketId)
            );
            assert(success);
            uint128 minimumMarketCreditCapacity = abi.decode(returnData, (uint128));
            // console2.log(
            //     "delegateCollateral::minimumMarketCreditCapacity",
            //     minimumMarketCreditCapacity
            // );
            require(currentCreditCapacity > minimumMarketCreditCapacity, "isCapacityLocked");

            increase = false;
            v3Mock.updateCreditCapacity(newCollateralAmountD18, increase);
        }
    }
}
