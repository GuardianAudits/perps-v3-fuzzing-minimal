pragma solidity >=0.8.11 <0.9.0;

import {AsyncOrder} from "../storage/AsyncOrder.sol";

import "./FuzzModules.sol";

contract FoundryPlayground is FuzzModules {
    function setUp() public {
        isFoundry = true; //NESSESARY FOR FOUNDRY TESTS
        setup();
        setupActors();
        // vm.prank(USER1);
        // deposit(1, 0, 100e18);
        //depositing usd for settlement reward
        // vm.prank(USER1);
        // deposit(1, 1, 100e18);
        // vm.prank(USER1);
        // deposit(1, 2, 100e18);
        vm.warp(1524785992); //@giraffe solution on beforeafter underflow
    }

    function test_guidedMarginOnly() public {
        // uint withdrawableUsd = v3Mock.getWithdrawableMarketUsd(0); //any market id
        // v3Mock.withdrawMarketUsd(0, address(1), withdrawableUsd);

        fuzz_guided_createDebt_LiquidateMarginOnly(false, 1e18);
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
        // vm.prank(USER1);
        wethTokenMock.mint(USER1, 111);
        console2.log("msg.sender", msg.sender);
        assert(false);
    }
    function test_assertion_failed() public {
        assert(false);
    }

    function test_testLensOrderExpired() public {
        // vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        // vm.prank(USER1);
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
        // vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        // vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 1);
        // vm.prank(USER1);
        fuzz_commitOrder(-2e18, type(uint256).max - 1); //-1 will be weth market
        // vm.prank(USER1);
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

        fuzz_modifyCollateral(1e18, 1); //weth

        fuzz_commitOrder(2.22e18, type(uint256).max - 1); //-1 will be weth market
        fuzz_settleOrder();
        fuzz_crashWETHPythPrice(uint(1)); //20%

        fuzz_commitOrder(-2.22e18, type(uint256).max - 1); //-1 will be weth market
        fuzz_settleOrder();

        fuzz_modifyCollateral(10100e18, 0);

        fuzz_commitOrder(2.33e18, type(uint256).max); //wbtc
        fuzz_settleOrder();

        //debt = 0 at this stage
    }

    function test_order_liquidatePosition() public {
        vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);

        fuzz_pumpWETHPythPrice(20);

        fuzz_modifyCollateral(1e18, 1);

        fuzz_commitOrder(20e18, type(uint256).max - 1);
        fuzz_settleOrder();

        fuzz_crashWETHPythPrice(30);
        fuzz_liquidatePosition();
    }

    function test_order_liquidateFlagged() public {
        // vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        // vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        // vm.prank(USER1);
        fuzz_commitOrder(20e18, type(uint256).max);
        // vm.prank(USER1);
        fuzz_crashWBTCPythPrice(20);
        // vm.prank(USER1);
        fuzz_liquidateFlagged(100);
    }

    function test_order_liquidateFlaggedAccounts() public {
        // vm.prank(USER1);
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        // vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        // vm.prank(USER1);
        fuzz_commitOrder(2e18, type(uint256).max);
        // vm.prank(USER1);
        fuzz_settleOrder();
        //fuzz_crashWBTCPythPrice();
        // vm.prank(USER1);
        fuzz_liquidateFlaggedAccounts(100);
    }

    function test_fuzz_order() public {
        //this works
        // vm.prank(USER1); //using start prank to make all pranks inside all modules here
        fuzz_mintUSDToSynthetix(100_000_000_000e18);

        // vm.prank(USER1);
        fuzz_modifyCollateral(1e18, 2);
        // vm.prank(USER1);
        fuzz_commitOrder(2e18, type(uint256).max);
        // vm.prank(USER1);
        fuzz_settleOrder();
        // // for (uint i; i < 2; ++i) {
        // fuzz_changeWBTCPythPrice(999);
        // // }
        // // vm.prank(USER1);
        // fuzz_commitOrder(-2e18, 5);
        // // vm.prank(USER1);
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
        // vm.prank(USER1);
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
        // vm.prank(USER1);
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

    function test_falsified_1() public {
        // vm.prank(USER3);
        fuzz_modifyCollateral(
            41375159011652481857230801695092970356520661981917901182765302721749,
            1014
        );
    }

    function test_replay_guidedMarginOnly() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 5053);
        try this.fuzz_changeWBTCPythPrice(4280455364831454581) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 34272);
        try
            this.fuzz_guided_createDebt_LiquidateMarginOnly(
                true,
                30954749420015391918139466440851848790163633299071895031681992968603483332913
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 19333);
        try this.excludeArtifacts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 24311);
        try this.fuzz_changeWBTCPythPrice(4280455364831454581) {} catch {}

        try
            this.fuzz_pumpWBTCPythPrice(
                4571378123040129835110645501447096099757817388479875675538670709315270443873
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 24987);
        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 4223);
        try this.excludeSelectors() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 1088);
        try this.excludeSelectors() {} catch {}

        try this.targetArtifacts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 25535);
        try
            this.fuzz_crashWBTCPythPrice(
                23216544756795111064671052892044071812121785505344308683573734109174097626271
            )
        {} catch {}

        try this.targetInterfaces() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 4896);
        try
            this.fuzz_pumpWBTCPythPrice(
                4571378123040129835110645501447096099757817388479875675538670709315270443873
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 58783);
        try this.targetArtifacts() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 36859);
        try this.failed() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 32147);
        try this.excludeSelectors() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 46422);
        try
            this.fuzz_modifyCollateral(
                49702006450953861765807903644386942596705006307479003070109120124712674327224,
                1524785993
            )
        {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 5786);
        try this.fuzz_settleOrder() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 30304);
        try
            this.fuzz_delegateCollateral(
                1524785993,
                0,
                86713579207806114606671108161500018359076792467074454731219611294456891961036,
                1524785991,
                1524785991
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 5023);
        try
            this.fuzz_crashWETHPythPrice(
                27791911391501575981142706174694744561875260745923521918881244428685164396544
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 50499);
        try
            this.fuzz_crashWETHPythPrice(
                27791911391501575981142706174694744561875260745923521918881244428685164396544
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 11826);
        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 2);
        vm.roll(block.number + 30256);
        try this.fuzz_liquidateFlagged(26) {} catch {}

        vm.warp(block.timestamp + 4);
        vm.roll(block.number + 4896);
        try this.fuzz_liquidateFlagged(55) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 41290);
        try
            this.fuzz_guided_createDebt_LiquidateMarginOnly(true, 4370001)
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 45852);
        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 19933);
        try this.failed() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 59552);
        try this.fuzz_changeWETHPythPrice(1524785993) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 36859);
        try this.fuzz_settleOrder() {} catch {}

        vm.warp(block.timestamp + 2);
        vm.roll(block.number + 3661);
        try
            this.pendingOrder(201468923201268763578963306507310472582)
        {} catch {}

        try this.IS_TEST() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 46422);

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 24987);
        try this.fuzz_liquidatePosition() {} catch {}

        try this.fuzz_guided_depositAndShort() {} catch {}

        try this.pendingOrder(527) {} catch {}

        try
            this.fuzz_crashWBTCPythPrice(
                73767554418199339812106075053837917778102426611481698007305348546559953757341
            )
        {} catch {}

        vm.warp(block.timestamp + 6);
        vm.roll(block.number + 20349);
        try this.fuzz_pumpWETHPythPrice(513) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 9920);
        try this.excludeContracts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 33357);
        try
            this.fuzz_pumpWETHPythPrice(
                18550952495227114971864363557780808188744923943598095365325468250271597804530
            )
        {} catch {}

        try this.fuzz_changeOracleManagerPrice(4370001, 1524785993) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 60364);
        try this.repayDebt() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 23403);
        try this.IS_TEST() {} catch {}

        vm.warp(block.timestamp + 6);
        vm.roll(block.number + 45852);
        try this.IS_TEST() {} catch {}

        try this.fuzz_changeWBTCPythPrice(-9223372036854775808) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 561);
        try this.fuzz_liquidateFlaggedAccounts(253) {} catch {}

        try this.fuzz_liquidatePosition() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 35248);
        try
            this.fuzz_pumpWBTCPythPrice(
                21443253488308386919818604701031834188266622639471657377774134086704501932199
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 32);
        try
            this.fuzz_delegateCollateral(
                330924488573917606084908576629834616816,
                196076158967676270537707503622353966090,
                5963535451332192165248380555010570991972943249917332641975986078000899566176,
                4370000,
                0
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 60267);
        try this.fuzz_liquidatePosition() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 20243);
        try this.targetInterfaces() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 2511);
        try
            this.fuzz_changeOracleManagerPrice(
                4370001,
                2785246858395475934513824290946353863510055321045186888325621967884044575369
            )
        {} catch {}

        fuzz_guided_createDebt_LiquidateMarginOnly(false, 4370001);
    }

    function test_MGN_14() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 43180);
        try
            this.fuzz_crashWBTCPythPrice(
                60368187887740273779520851036367321390742330372111243410017965485225816409222
            )
        {} catch {}

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

        try
            this.fuzz_modifyCollateral(
                7363886252298912951297268819470124426459998075572683640558215609191109221168,
                36060378883672883844
            )
        {} catch {}

        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 32776);
        try this.failed() {} catch {}

        try this.repayDebt() {} catch {}

        try
            this.pendingOrder(254864682208477713788650096748232259748)
        {} catch {}

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
        try
            this.fuzz_crashWBTCPythPrice(
                40734345885457213119587725476776602361710619297559342637786566930942934196174
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 35248);
        // try this.collateralToMarketId(0xffffffff) {} catch {}

        try
            this.fuzz_commitOrder(45527665955789711570906065755761038313, 0)
        {} catch {}

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

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 2512);
        // try this.collateralToMarketId(0xffffffff) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 59981);
        try
            this.fuzz_burnUSDFromSynthetix(
                69440312566769276623656011396831292783790727085490337084095597749272364534186
            )
        {} catch {}

        try
            this.fuzz_crashWBTCPythPrice(
                33474750363803198344703969225256527259022938577339749068987358902924311968844
            )
        {} catch {}

        try
            this.fuzz_payDebt(328273681046912410412101207159872402337)
        {} catch {}

        try
            this.fuzz_commitOrder(
                86168858261284524850319675772111529712,
                2423707
            )
        {} catch {}

        try this.repayDebt() {} catch {}

        try
            this.fuzz_modifyCollateral(
                15430920056894041623138793344739737515016944957914741277770872442158975318435,
                36060378883672883844
            )
        {} catch {}

        try
            this.fuzz_modifyCollateral(
                15430920056894041623138793344739737515016944957914741277770872442158975318435,
                36060378883672883844
            )
        {} catch {}

        try
            this.fuzz_crashWBTCPythPrice(
                104728133708937779018501638906324747851300398287592565595978335268451929896653
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 45819);
        try this.fuzz_pumpWETHPythPrice(256332019) {} catch {}

        try
            this.fuzz_modifyCollateral(
                35,
                13161757840859343235923202888453968634670567318907731003551582133953012971661
            )
        {} catch {}

        try
            this.fuzz_modifyCollateral(
                22866954023517326881472454420837192006879627097854062968841109005214028865838,
                21758050889834850033820492102659170992600571097412026316956767264376619351359
            )
        {} catch {}

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
        try
            this.fuzz_changeOracleManagerPrice(
                0,
                7519350156025721105513033945595310101117735264990167366435493668905295328501
            )
        {} catch {}

        // try this.collateralToMarketId(0x0) {} catch {}

        try
            this.fuzz_delegateCollateral(
                74925526633849638937062738874433663672,
                314018504,
                78785864899989875006334211634987353900540908220055761376259547605655821385692,
                27430329213400711167317844260663557624057715998269514346455789332778464393757,
                5948350862628443382883182303845845051077729108099372676306581706617715600343
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 4462);
        try this.targetSenders() {} catch {}

        try this.failed() {} catch {}

        try this.targetArtifacts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 27608);
        try this.fuzz_pumpWBTCPythPrice(1524785993) {} catch {}

        fuzz_guided_createDebt_LiquidateMarginOnly(
            false,
            10254914090907667362931365709060444715882551265141187039062566737611087896158
        );
    }

    function test_replay() public {
        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 34272);
        try
            this.fuzz_burnUSDFromSynthetix(
                45000205579593422793971688701070747844673326857311391567008757040412281816834
            )
        {} catch {}

        vm.warp(block.timestamp + 4);
        vm.roll(block.number + 11064);
        try this.fuzz_crashWETHPythPrice(1524785991) {} catch {}

        try this.fuzz_liquidateMarginOnly() {} catch {}

        try this.fuzz_liquidateMarginOnly() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 32147);
        try this.repayDebt() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 60248);
        try this.targetArtifactSelectors() {} catch {}

        try this.targetSelectors() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 4896);
        try this.fuzz_mintUSDToSynthetix(0) {} catch {}

        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 13250);
        try this.targetSelectors() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 2526);
        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 11905);
        try
            this.fuzz_delegateCollateral(
                36828625693275696640120913861754809315,
                73245070668037295087441342590085061706,
                33783191400100172597863373117419391094053153243159976520254267842424207912643,
                112075327461987802550655256594673494575300711805717915312458092882191714386119,
                0
            )
        {} catch {}

        try this.fuzz_liquidateFlagged(169) {} catch {}

        try this.fuzz_crashWETHPythPrice(0) {} catch {}

        try
            this.fuzz_mintUSDToSynthetix(
                105801033546897551406530986109799743100112340916191615231272548264611594088362
            )
        {} catch {}

        try this.fuzz_crashWETHPythPrice(1524785992) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 32147);
        try this.targetArtifacts() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 23403);
        try
            this.fuzz_modifyCollateral(
                26290151398335042387584962512529249871203077404871763965134854535792069774266,
                80108504713470209914278951554916148943418012408393476250048930893710949609029
            )
        {} catch {}

        try
            this.fuzz_modifyCollateral(
                4370001,
                115792089237316195423570985008687907853269984665640564039457584007913129639932
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 4223);
        try
            this.fuzz_pumpWBTCPythPrice(
                115792089237316195423570985008687907853269984665640564039457584007913129639934
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 30042);
        try this.fuzz_liquidatePosition() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 740);
        try this.failed() {} catch {}

        vm.warp(block.timestamp + 4);
        vm.roll(block.number + 32767);
        try
            this.fuzz_burnUSDFromSynthetix(
                49813101531550216653332734469256659982470549350278407082068826429681070746900
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 134);
        try this.excludeSenders() {} catch {}

        try this.fuzz_liquidateFlaggedAccounts(168) {} catch {}

        try this.excludeArtifacts() {} catch {}

        try
            this.pendingOrder(266016537906820860850809730220579711148)
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 9920);
        try
            this.fuzz_payDebt(30970891527207320847500865352762569102)
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 57086);
        try
            this.fuzz_crashWETHPythPrice(
                77275034715495547752772962276639361295404132448683641556340984031581954863903
            )
        {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 45852);
        try
            this.fuzz_mintUSDToSynthetix(
                33146731348473438563520614482308509989229457387041916782028583601242359215163
            )
        {} catch {}

        try this.repayDebt() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 55538);
        try this.fuzz_cancelOrder(22) {} catch {}

        try this.fuzz_liquidatePosition() {} catch {}

        try this.targetArtifacts() {} catch {}

        vm.warp(block.timestamp + 2);
        vm.roll(block.number + 28541);
        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 8447);
        try
            this.fuzz_modifyCollateral(
                31341995297815370267175638658422425120244910099266197972292868266856641310131,
                94684470418779396919350158519226463755402058532465052869684989328848394048684
            )
        {} catch {}

        try
            this.fuzz_burnUSDFromSynthetix(
                58789454961237064847440741021415772932101969288821307333169837999726616708072
            )
        {} catch {}

        try this.fuzz_liquidatePosition() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 50499);
        try
            this.fuzz_changeOracleManagerPrice(
                115762427260727798208690557192022021927864149519498486708240255418676164598250,
                4369999
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 42101);
        try
            this.fuzz_crashWBTCPythPrice(
                54269568995447413382124210873534963627508767645902639017203379785952909532480
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 53349);
        try
            this.fuzz_payDebt(73757399643513383729588220264614614358)
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 45852);
        try this.targetInterfaces() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 13618);
        try
            this.fuzz_commitOrder(
                127704448971332881237578559069068356573,
                95322973884720292370317183118268634231737990320981720582307741081757144152871
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 54155);
        try this.targetContracts() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 23653);
        try this.IS_TEST() {} catch {}

        try this.fuzz_pumpWBTCPythPrice(4369999) {} catch {}

        try this.excludeArtifacts() {} catch {}

        vm.warp(block.timestamp + 6);
        vm.roll(block.number + 37725);
        try this.IS_TEST() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 42595);
        try this.fuzz_changeWETHPythPrice(5356475) {} catch {}

        try this.targetArtifactSelectors() {} catch {}

        try this.pendingOrder(0) {} catch {}

        try this.fuzz_liquidatePosition() {} catch {}

        try
            this.fuzz_burnUSDFromSynthetix(
                58789454961237064847440741021415772932101969288821307333169837999726616708072
            )
        {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 38100);
        try this.fuzz_liquidatePosition() {} catch {}

        try this.fuzz_changeWETHPythPrice(391779850034471797) {} catch {}

        try this.failed() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 30011);
        try this.IS_TEST() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 11905);
        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 42595);
        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 4);
        vm.roll(block.number + 7323);
        try this.targetSenders() {} catch {}

        try this.fuzz_settleOrder() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 58302);
        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 6);
        vm.roll(block.number + 30784);
        try this.failed() {} catch {}

        try
            this.fuzz_mintUSDToSynthetix(
                104377844713112429794676960515618392400013305950017995254558655826380442538697
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 45261);
        try this.targetSelectors() {} catch {}

        try
            this.fuzz_delegateCollateral(
                47,
                2206704,
                4369999,
                115792089237316195423570985008687907853269984665640564039457584007913129639935,
                4370000
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 11942);
        try this.fuzz_changeWBTCPythPrice(1524785993) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 58783);
        try this.fuzz_cancelOrder(46) {} catch {}

        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 2);
        vm.roll(block.number + 16089);
        try
            this.fuzz_guided_createDebt_LiquidateMarginOnly(
                false,
                14819910726712391989948254493261783883223370044539668440567400733936624935966
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 53011);
        try
            this.fuzz_delegateCollateral(
                1524785992,
                1524785991,
                115792089237316195423570985008687907853269984665640564039457584007913129639935,
                67588973153477190165880986117772338943086972654623411984221504480324212478346,
                62793409920333674322019637477378748203176706303444023314516059109468465661766
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 35200);
        try
            this.fuzz_guided_createDebt_LiquidateMarginOnly(false, 1524785992)
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 15369);
        try this.fuzz_liquidateFlagged(255) {} catch {}

        try this.fuzz_crashWBTCPythPrice(4370001) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 20398);
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 27724);
        try this.fuzz_changeWBTCPythPrice(203278) {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 59981);
        try this.fuzz_liquidateMarginOnly() {} catch {}

        try this.fuzz_crashWETHPythPrice(674) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 30784);
        try this.targetArtifacts() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 32737);
        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 2497);
        try this.targetInterfaces() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 561);
        fuzz_payDebt(884059082);

        console2.log("======== HERE1");
    }
}
