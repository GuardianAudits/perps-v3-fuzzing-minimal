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

    function test_openAndClose() public {
        vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 1);
        vm.prank(USER1);
        fuzz_commitOrder(-2e18, type(uint256).max - 1); //-1 will be weth market
        vm.prank(USER1);
        fuzz_settleOrder();
        vm.prank(USER1);
        fuzz_commitOrder(2e18, type(uint256).max - 1); //-1 will be weth market
        vm.prank(USER1);
        fuzz_settleOrder();
    }

    function test_openAndCloseTwoPositionsWIthLoss() public {
        //loss comes form fees

        fuzz_mintUSDToSynthetix(100_000_000_000e18);

        fuzz_modifyCollateral(11110e18, 0);

        fuzz_commitOrder(2.22e18, type(uint256).max - 1); //-1 will be weth market
        fuzz_settleOrder();
        fuzz_crashWETHPythPrice(uint(1));

        fuzz_commitOrder(-2.22e18, type(uint256).max - 1); //-1 will be weth market
        fuzz_settleOrder();

        fuzz_modifyCollateral(10100e18, 0);

        fuzz_commitOrder(2.33e18, type(uint256).max); //wbtc
        fuzz_settleOrder();

        fuzz_commitOrder(-2.33e18, type(uint256).max); //wbtc
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

    function test_order_liquidateFlaggedFunction() public {
        vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        vm.prank(USER1);
        fuzz_commitOrder(20e18, type(uint256).max);
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

    function test_MGN_14() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 43180);
        try this.fuzz_crashWBTCPythPrice(60368187887740273779520851036367321390742330372111243410017965485225816409222) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 59552);
        try this.targetInterfaces() {} catch {}

        try this.fuzz_pumpWETHPythPrice(10400920) {} catch {}

        try this.fuzz_settleOrder() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 5952);
        try this.failed() {} catch {}

        try this.fuzz_liquidateFlaggedAccounts(54) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 590);
        try this.fuzz_liquidateMarginOnly() {} catch {}

        try this.fuzz_modifyCollateral(7363886252298912951297268819470124426459998075572683640558215609191109221168,36060378883672883844) {} catch {}

        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 32776);
        try this.failed() {} catch {}

        try this.repayDebt() {} catch {}

        try this.pendingOrder(254864682208477713788650096748232259748) {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 225);
        try this.repayDebt() {} catch {}

        try this.fuzz_liquidateFlagged(16) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 53349);
        try this.fuzz_changeWETHPythPrice(1285495787) {} catch {}

        try this.excludeContracts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 49415);
        try this.fuzz_crashWBTCPythPrice(40734345885457213119587725476776602361710619297559342637786566930942934196174) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 35248);
        // try this.collateralToMarketId(0xffffffff) {} catch {}

        try this.fuzz_commitOrder(45527665955789711570906065755761038313,0) {} catch {}

        try this.excludeSelectors() {} catch {}

        vm.warp(block.timestamp + 2);
        vm.roll(block.number + 38350);
        try this.fuzz_changeWETHPythPrice(164129134689884637) {} catch {}

        try this.targetSelectors() {} catch {}

        try this.fuzz_changeWBTCPythPrice(703) {} catch {}

        try this.fuzz_settleOrder() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 23275);
        try this.failed() {} catch {}

        try this.IS_TEST() {} catch {}

        try this.targetSenders() {} catch {}

        try this.fuzz_settleOrder() {} catch {}

        try this.fuzz_liquidatePosition() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 2512);
        // try this.collateralToMarketId(0xffffffff) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 59981);
        try this.fuzz_burnUSDFromSynthetix(69440312566769276623656011396831292783790727085490337084095597749272364534186) {} catch {}

        try this.fuzz_crashWBTCPythPrice(33474750363803198344703969225256527259022938577339749068987358902924311968844) {} catch {}

        try this.fuzz_payDebt(328273681046912410412101207159872402337) {} catch {}

        try this.fuzz_commitOrder(86168858261284524850319675772111529712,2423707) {} catch {}

        try this.repayDebt() {} catch {}

        try this.fuzz_modifyCollateral(15430920056894041623138793344739737515016944957914741277770872442158975318435,36060378883672883844) {} catch {}

        try this.fuzz_modifyCollateral(15430920056894041623138793344739737515016944957914741277770872442158975318435,36060378883672883844) {} catch {}

        try this.fuzz_crashWBTCPythPrice(104728133708937779018501638906324747851300398287592565595978335268451929896653) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 45819);
        try this.fuzz_pumpWETHPythPrice(256332019) {} catch {}

        try this.fuzz_modifyCollateral(35,13161757840859343235923202888453968634670567318907731003551582133953012971661) {} catch {}

        try this.fuzz_modifyCollateral(22866954023517326881472454420837192006879627097854062968841109005214028865838,21758050889834850033820492102659170992600571097412026316956767264376619351359) {} catch {}

        vm.warp(block.timestamp + 2);
        vm.roll(block.number + 31318);
        try this.excludeArtifacts() {} catch {}

        try this.fuzz_pumpWETHPythPrice(1524785992) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 15368);
        try this.targetInterfaces() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 24311);
        try this.fuzz_settleOrder() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 3708);
        try this.fuzz_changeOracleManagerPrice(0,7519350156025721105513033945595310101117735264990167366435493668905295328501) {} catch {}

        // try this.collateralToMarketId(0x0) {} catch {}

        try this.fuzz_delegateCollateral(74925526633849638937062738874433663672,314018504,78785864899989875006334211634987353900540908220055761376259547605655821385692,27430329213400711167317844260663557624057715998269514346455789332778464393757,5948350862628443382883182303845845051077729108099372676306581706617715600343) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 4462);
        try this.targetSenders() {} catch {}

        try this.failed() {} catch {}

        try this.targetArtifacts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 27608);
        try this.fuzz_pumpWBTCPythPrice(1524785993) {} catch {}

        fuzz_guided_createDebt_LiquidateMarginOnly(false,10254914090907667362931365709060444715882551265141187039062566737611087896158);

    }
}
