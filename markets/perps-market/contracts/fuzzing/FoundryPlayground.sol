pragma solidity >=0.8.11 <0.9.0;

import {AsyncOrder} from "../storage/AsyncOrder.sol";

import "./FuzzModules.sol";

contract FoundryPlayground is FuzzModules {
    function setUp() public {
        isFoundry = true; //NESSESARY FOR FOUNDRY TESTS
        setup();
        setupActors();
        deposit(1, 0, 100e18);
        //depositing usd for settlement reward
        // deposit(1, 1, 100e18);
        // deposit(1, 2, 100e18);
    }

    function test_deposit_withdraw_HUGE() public {
        deposit(1, 3, 500e30);
        withdraw(1, 3, 40e30);
        deposit(1, 3, 1e30);
        fuzz_withdrawAllCollateral(1, false, false, true);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.getCollateralAmount.selector,
                1,
                3
            )
        );
        assert(success);
        uint256 amountOfHuge = abi.decode(returnData, (uint256));

        console2.log(
            "Bool if true",
            amountOfHuge % (10 ** (hugePrecisionTokenMock.decimals() - 18)) != 0
        );
    }

    function test_withdrawSUSD() public {
        withdraw(userToAccountIds[USER1], 0, -100e18);
    }

    function test_prank() public {
        console2.log("msg.sender", msg.sender);
        vm.prank(USER1);
        wethTokenMock.mint(USER1, 111);
        console2.log("msg.sender", msg.sender);
        assert(false);
    }
    function test_assertion_failed() public {
        assert(false);
    }

    function test_testLensOrderExpired() public {
        vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        vm.prank(USER1);
        fuzz_commitOrder(2e18, type(uint256).max);

        vm.warp(block.timestamp + 1000000);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                mockLensModuleImpl.isOrderExpired.selector,
                1
            )
        );
        assert(success);
        assert(abi.decode(returnData, (bool)));
    }

    function test_delegateCollateral() public {
        uint256 currentCreditCapacity = v3Mock.creditCapacity();
        console2.log("Current Credit Capacity:", currentCreditCapacity);

        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.minimumCredit.selector,
                2
            )
        );
        assert(success);
        uint128 minimumMarketCreditCapacity = abi.decode(returnData, (uint128));
        console2.log(
            "Minimum Market Credit Capacity:",
            minimumMarketCreditCapacity
        );

        fuzz_delegateCollateral(
            1, // uint128 accountId,
            2, // uint128 poolId,
            3, // uint256 collateralIndex,  marketId = collateralTokenIndex % 2 == 0 ? 1 : 2;
            1000, //uint256 newCollateralAmountD18,
            1 // uint leverage
        );
    }

    function test_modifyCollateral() public {
        deposit(1, 0, 100e18);
        deposit(1, 1, 110e18);
        deposit(1, 2, 120e18);
    }

    function test_settleOrder() public {
        vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 1);
        vm.prank(USER1);
        fuzz_commitOrder(-2e18, type(uint256).max - 1); //-1 will be weth market
        vm.prank(USER1);
        fuzz_settleOrder();
    }

    function test_order_liquidatePosition() public {
        vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        vm.prank(USER1);
        fuzz_commitOrder(2e18, type(uint256).max); //TODO: margin ratio recheck
        vm.prank(USER1);
        fuzz_settleOrder();
        fuzz_crashWBTCPythPrice(20);
        vm.prank(USER1);
        fuzz_liquidatePosition();
    }

    function test_order_liquidateFlagged() public {
        vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        vm.prank(USER1);
        fuzz_commitOrder(2e18, type(uint256).max);
        vm.prank(USER1);
        fuzz_settleOrder();
        fuzz_crashWBTCPythPrice(20);
        vm.prank(USER1);
        fuzz_liquidateFlagged(100);
    }

    function test_order_liquidateFlaggedAccounts() public {
        vm.prank(USER1); //using start prank to make all pranks inside all modules here
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        vm.prank(USER1);
        fuzz_commitOrder(2e18, type(uint256).max);
        vm.prank(USER1);
        fuzz_settleOrder();
        //fuzz_crashWBTCPythPrice();
        vm.prank(USER1);
        fuzz_liquidateFlaggedAccounts(100);
    }

    function test_fuzz_order() public {
        //this works
        vm.prank(USER1); //using start prank to make all pranks inside all modules here
        fuzz_mintUSDToSynthetix(100_000_000_000e18);

        vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        vm.prank(USER1);
        fuzz_commitOrder(2e18, type(uint256).max);
        vm.prank(USER1);
        fuzz_settleOrder();
        // // for (uint i; i < 2; ++i) {
        // fuzz_changeWBTCPythPrice(999);
        // // }
        // vm.prank(USER1);
        // fuzz_commitOrder(-2e18, 5);
        // vm.prank(USER1);
        // fuzz_settleOrder();
        // fuzz_crashWBTCPythPrice(20);

        // fuzz_liquidateMarginOnly();
    }

    function test_fuzz_guided_createDebt_LiquidateMarginOnly() public {
        fuzz_modifyCollateral(1e18, 2);
        fuzz_modifyCollateral(1e18, 1);
        fuzz_commitOrder(2e18, type(uint256).max);
        fuzz_settleOrder();
        fuzz_guided_createDebt_LiquidateMarginOnly(
            false,
            53730897479171415898043834651593372745878916885015083884090641902428996104110
        );
        // fuzz_guided_createDebt_LiquidateMarginOnly(true, 1e18);
    }

    function test_changePythPrice() public {
        //fuzz_crashWETHPythPrice();
    }

    function test_order() public {
        commit_order();
        vm.warp(block.timestamp + 5);
        pythWrapper.setBenchmarkPrice(WBTC_FEED_ID, 3000e18);
        settle_order();
        // pythWrapper.setBenchmarkPrice(WBTC_FEED_ID, 1e18);
        // mockOracleManager.changePrice(WBTC_ORACLE_NODE_ID, 1e10);
        // liquidate(uint128(1));
    }
    function liquidate(uint accountId) internal {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                liquidationModuleImpl.liquidate.selector,
                accountId
            )
        );
        if (!success) {
            if (returnData.length > 0) {
                string memory errorMessage = abi.decode(returnData, (string));
                revert(errorMessage);
            } else {
                revert("Call to perps contract failed");
            }
        }
    }
    function settle_order() internal {
        vm.prank(USER1);
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                AsyncOrderSettlementPythModule.settleOrder.selector,
                1
            )
        );
        if (!success) {
            if (returnData.length > 0) {
                string memory errorMessage = abi.decode(returnData, (string));
                revert(errorMessage);
            } else {
                revert("Call to perps contract failed");
            }
        }
    }
    function commit_order() internal {
        AsyncOrder.OrderCommitmentRequest memory commitment = AsyncOrder
            .OrderCommitmentRequest({
                marketId: 2,
                accountId: 1,
                sizeDelta: int128(1e6),
                settlementStrategyId: 0,
                acceptablePrice: type(uint256).max,
                trackingCode: bytes32(0),
                referrer: address(0)
            });
        vm.prank(USER1);
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                asyncOrderModuleImpl.commitOrder.selector,
                commitment
            )
        );
        if (!success) {
            if (returnData.length > 0) {
                string memory errorMessage = abi.decode(returnData, (string));
                revert(errorMessage);
            } else {
                revert("Call to perps contract failed");
            }
        }
    }
    function test_deposit_withdraw_SNX() public {
        deposit(1, 0, 1000);
        withdraw(1, 0, -100);
    }
    function test_deposit_withdraw_WETH() public {
        deposit(1, 1, 1000);
        withdraw(1, 1, -100);
    }
    function test_deposit_withdraw_WBTC() public {
        deposit(1, 2, 1000);
        withdraw(1, 2, -100);
    }
    function deposit(
        uint128 accountId,
        uint128 collateralId,
        int delta
    ) internal {
        address user;
        if (accountId == 1) {
            user = USER1;
        } else if (accountId == 2) {
            user = USER2;
        } else {
            user = USER3;
        }
        vm.prank(user);
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.modifyCollateral.selector,
                accountId,
                collateralId,
                delta
            )
        );
        if (!success) {
            if (returnData.length > 0) {
                string memory errorMessage = abi.decode(returnData, (string));
                revert(errorMessage);
            } else {
                revert("Call to perps contract failed");
            }
        }
    }
    function withdraw(
        uint128 accountId,
        uint128 collateralId,
        int delta
    ) internal {
        address user;
        if (accountId == 1) {
            user = USER1;
        } else if (accountId == 2) {
            user = USER2;
        } else {
            user = USER3;
        }
        vm.prank(user);
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                perpsAccountModuleImpl.modifyCollateral.selector,
                accountId,
                collateralId,
                delta
            )
        );
        if (!success) {
            if (returnData.length > 0) {
                string memory errorMessage = abi.decode(returnData, (string));
                revert(errorMessage);
            } else {
                revert("Call to perps contract failed");
            }
        }
    }

    function test_falsified_1() public {
        vm.prank(USER3);
        fuzz_modifyCollateral(
            41375159011652481857230801695092970356520661981917901182765302721749,
            1014
        );
    }

    function test_ORD_21() public {
        vm.roll(block.number + 45852);
        vm.warp(block.timestamp + 1);
        fuzz_cancelOrder(255); 
        vm.roll(block.number + 11826);
        vm.warp(block.timestamp + 5);
        fuzz_guided_createDebt_LiquidateMarginOnly(true,32340893082257289989694766967862054800338950119547607012085591980478505381479);

    }
}
