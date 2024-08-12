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

    function test_ORD_19() public {
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        fuzz_modifyCollateral(1e18, 1);

        //before pnl = 0
        //before pos = 0
        fuzz_commitOrder(2e18, type(uint256).max - 1); //-1 will be weth market
        fuzz_settleOrder();
        // //after pnl = -6
        // //after pos = 2000

        fuzz_modifyCollateral(10100e18, 0);

        // //before pnl = 0
        // //before pos = 0
        fuzz_commitOrder(2.33e18, type(uint256).max); //wbtc
        fuzz_settleOrder();
    }

    function test_openAndCloseTwoPositionsWIthLoss_ORD22() public {
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
        fuzz_liquidatePosition();
    }

    function test_order_liquidateFlagged() public {
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        fuzz_modifyCollateral(1e18, 2);
        fuzz_commitOrder(20e18, type(uint256).max);
        fuzz_settleOrder();
        fuzz_crashWBTCPythPrice(20);
        fuzz_liquidateFlagged(100);
    }

    // function draft_liq_ord_21() public {
    //      //reported debt
    //     // liquidate ->
    //     // hit liq window maximum ->
    //     // time passes ->
    //     // price moves ->
    //     // reportedDebt != collateral + pnl.
    //     //sh
    //     // it would require a scenario of
    //     vm.prank(USER1);
    //     fuzz_mintUSDToSynthetix(100_000_000_000e18);

    //     fuzz_pumpWETHPythPrice(20);

    //     fuzz_modifyCollateral(1e18, 1);

    //     fuzz_commitOrder(20e18, type(uint256).max - 1);
    //     fuzz_settleOrder();

    //     fuzz_crashWETHPythPrice(5);
    //     fuzz_liquidatePosition();
    //     fuzz_crashWETHPythPrice(1);
    //     //_after + invariant //@giraffe here we checking ORD_21
    //     //reported debt
    //     (bool success, bytes memory returnData) = perps.call(
    //         abi.encodeWithSelector(
    //             perpsMarketFactoryModuleImpl.reportedDebt.selector,
    //             1
    //         )
    //     );
    //     assert(success);
    //     uint beforeDebt = abi.decode(returnData, (uint256));
    //     console2.log("beforeDebt", beforeDebt);
    //     fuzz_liquidateFlagged(100);

    //     (bool success, bytes memory returnData) = perps.call(
    //         abi.encodeWithSelector(
    //             perpsMarketFactoryModuleImpl.reportedDebt.selector,
    //             1
    //         )
    //     );
    //     assert(success);
    //     uint afterDebt = abi.decode(returnData, (uint256));
    //     console2.log("afterDebt", afterDebt);

    // }

    function test_order_liquidateFlaggedAccounts() public {
        fuzz_mintUSDToSynthetix(100_000_000_000e18);
        fuzz_modifyCollateral(1e18, 2);
        fuzz_commitOrder(2e18, type(uint256).max);
        fuzz_settleOrder();
        fuzz_crashWBTCPythPrice(20);
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

    function test_ORD_16() public {
        fuzz_guided_depositAndShort();
        fuzz_settleOrder();
        fuzz_guided_depositAndShort();
        fuzz_settleOrder();
        fuzz_pumpWETHPythPrice(
            82352903850381545875167988573535174057100332746199847668449058337
        );
        fuzz_liquidateFlagged(0);
    }

    function test_shortWBTC() public {
        fuzz_guided_depositAndShortWBTC();
        fuzz_settleOrder();
        fuzz_guided_depositAndShortWBTC();
        fuzz_settleOrder();
    }

    function test_replay_LIQ16() public {
        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 14246);
        try this.fuzz_crashWBTCPythPrice(8272663) {} catch {}

        try
            this.fuzz_changeOracleManagerPrice(
                5876995114192504108114557442559075274233847232337755884555805112560331383974,
                20374593907295150528490908016128133617111158061146294585622734675020521622889
            )
        {} catch {}

        try this.fuzz_crashWBTCPythPrice(3801989) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 11942);
        try this.fuzz_guided_depositAndShortWBTC() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 31807);
        try this.repayDebt() {} catch {}

        try this.fuzz_settleOrder() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 58783);
        try this.targetSenders() {} catch {}

        try this.fuzz_guided_depositAndShort() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 60);
        try this.excludeSenders() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 33218);
        vm.warp(block.timestamp + 10);
        vm.roll(block.number + 69950);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 35731);
        try this.fuzz_cancelOrder(5) {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 49415);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 60364);
        try this.fuzz_cancelOrder(44) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 15607);
        try this.pendingOrder(1256657410) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 4223);
        try this.fuzz_guided_depositAndShort() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 15764);
        try this.IS_TEST() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 27404);
        try
            this.fuzz_modifyCollateral(
                8542833558636987789308118644925683403792117600965309022390609468528741291235,
                1676809
            )
        {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 38350);
        try this.fuzz_crashWBTCPythPrice(55) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 5023);
        try
            this.fuzz_commitOrder(
                3153,
                19404086526591562380684914545785193691637301789324297873349688953609032224
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 60364);
        try this.fuzz_crashWETHPythPrice(172660010) {} catch {}

        fuzz_liquidatePosition();
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

        try this.fuzz_liquidatePosition() {} catch {}

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

    function test_ORD_18() public {
        //  *wait* Time delay: 2 seconds Block delay: 3
        vm.warp(block.timestamp + 2);
        vm.roll(block.number + 3);
        fuzz_guided_depositAndShort();
        fuzz_cancelOrder(0);
        fuzz_settleOrder();
    }

    function test_MGN_08() public {
        try this.targetContracts() {} catch {}

        try this.excludeArtifacts() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 52331);
        try this.excludeArtifacts() {} catch {}

        try
            this.pendingOrder(214287796030402947727426544725022203104)
        {} catch {}

        try
            this.fuzz_payDebt(128354471236838546871697598878614575996)
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 13100);

        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 35200);

        try this.excludeContracts() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 34720);
        try this.targetInterfaces() {} catch {}

        vm.warp(block.timestamp + 6);
        vm.roll(block.number + 13928);
        try this.pendingOrder(2541897861) {} catch {}

        vm.warp(block.timestamp + 4);
        vm.roll(block.number + 47075);
        try this.fuzz_cancelOrder(243) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 30784);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 10158);
        try this.targetArtifactSelectors() {} catch {}

        try this.fuzz_payDebt(4369999) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 5023);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 12155);
        // try this.fuzz_changeWETHPythPrice(10636261954290471496977424074956230848709081310768360796372110293158335144948) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 42595);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 24311);
        try this.targetArtifactSelectors() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 57086);
        try
            this.fuzz_pumpWETHPythPrice(
                4483620328855303094470149414702153581938704238923537833778918805266589838192
            )
        {} catch {}

        try
            this.fuzz_burnUSDFromSynthetix(
                51978725119979516310380084262403014497549784881740951640043242924742048186009
            )
        {} catch {}

        try this.excludeArtifacts() {} catch {}

        try this.fuzz_payDebt(4370000) {} catch {}

        try this.IS_TEST() {} catch {}

        vm.warp(block.timestamp + 4);
        vm.roll(block.number + 12053);
        try
            this.fuzz_pumpWETHPythPrice(
                57881106071855846508961237091619114449106847265532603503188584961426569220050
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 54155);
        try this.repayDebt() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 30256);
        try this.excludeArtifacts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 23978);
        try this.excludeSenders() {} catch {}

        try this.targetArtifacts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 26285);
        try this.fuzz_changeWBTCPythPrice(4370000) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 30304);
        try this.excludeSelectors() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 20070);
        try this.fuzz_mintUSDToSynthetix(4370000) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 30784);
        try this.fuzz_guided_createDebt_LiquidateMarginOnly(true, 0) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 57086);
        try this.fuzz_cancelOrder(67) {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 5237);
        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 6721);
        try
            this.fuzz_delegateCollateral(
                4369999,
                1524785993,
                1524785993,
                62818061388295607208165346735794823292442871658757766994584960565562405544343,
                4370000
            )
        {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 12493);
        try this.fuzz_liquidateFlagged(47) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 11942);

        try this.fuzz_liquidatePosition() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 30011);
        try
            this.fuzz_crashWETHPythPrice(
                3384311717577629014095999329592389476318589900033263442720613258630492251344
            )
        {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 2526);
        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 15005);
        try this.excludeSelectors() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 23722);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 47075);
        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 30011);
        try this.fuzz_burnUSDFromSynthetix(0) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 127);
        try this.excludeSelectors() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 24311);
        try this.targetSelectors() {} catch {}

        try
            this.fuzz_guided_createDebt_LiquidateMarginOnly(
                false,
                11167667902276408224730562216929677101514325461329936881433630288680895358749
            )
        {} catch {}

        vm.warp(block.timestamp + 6);
        vm.roll(block.number + 15005);
        try
            this.fuzz_guided_createDebt_LiquidateMarginOnly(
                true,
                12650908807397575775097778642268497213383900757161717685745018070990260653039
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 54155);
        try this.IS_TEST() {} catch {}

        vm.warp(block.timestamp + 6);
        vm.roll(block.number + 59981);
        try this.fuzz_liquidateFlaggedAccounts(252) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 59982);
        try this.targetSenders() {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 53593);
        try
            this.fuzz_crashWETHPythPrice(
                19445979271211552026393762153068637348871782583200450729535479179963
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 32);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 5952);
        try
            this.fuzz_pumpWETHPythPrice(
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 42229);
        try this.fuzz_liquidateFlaggedAccounts(145) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 7323);
        try this.fuzz_changeWBTCPythPrice(1524785992) {} catch {}

        try
            this.fuzz_pumpWETHPythPrice(
                115455222081581466560662936016781449048188058971967711045082786856763288682493
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 46422);
        try
            this.fuzz_guided_createDebt_LiquidateMarginOnly(
                true,
                55262479342812091384886880778795658276242523769116954278288293698392236065192
            )
        {} catch {}

        try this.targetContracts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 23885);
        try
            this.fuzz_pumpWETHPythPrice(
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 5053);
        // try this.fuzz_changeWETHPythPrice(-18446744073709551616) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 27404);
        try
            this.fuzz_payDebt(128354471236838546871697598878614575996)
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 3661);
        try this.fuzz_settleOrder() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 53451);
        try this.fuzz_liquidateFlaggedAccounts(18) {} catch {}

        try this.fuzz_liquidateMarginOnly() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1088);
        try this.fuzz_liquidateMarginOnly() {} catch {}

        try this.excludeSenders() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 33389);
        try this.fuzz_liquidateMarginOnly() {} catch {}

        try this.excludeSelectors() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 34720);
        try this.fuzz_cancelOrder(255) {} catch {}

        try this.fuzz_liquidateFlaggedAccounts(164) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 15005);
        try
            this.fuzz_delegateCollateral(
                4369999,
                222184078082960036510249747402455690044,
                12363880754773229893861596779428693668172735971754208246649894137510809891579,
                61283307733705928599294133957445110220249428009377408892359924365738394683447,
                90273455696721862018034964254304874431945974501155260272400615066703053274163
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 21179);
        try this.excludeArtifacts() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 57886);
        try
            this.fuzz_payDebt(128354471236838546871697598878614575996)
        {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 5237);
        try
            this.fuzz_burnUSDFromSynthetix(
                6921200522935427282462348915319132641639072858525405344222022284229439482331
            )
        {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 2497);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 45261);
        try this.fuzz_crashWBTCPythPrice(1524785991) {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 31232);
        try this.fuzz_changeWETHPythPrice(1524785991) {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 23885);
        try
            this.fuzz_pumpWETHPythPrice(
                102684582203599779126993990852225264517714905074500961846362724029724275704408
            )
        {} catch {}

        vm.warp(block.timestamp + 5);
        vm.roll(block.number + 800);
        try this.fuzz_liquidateMarginOnly() {} catch {}

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 22909);
        try this.fuzz_liquidatePosition() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 42595);
        try this.excludeSelectors() {} catch {}

        try this.fuzz_liquidateMarginOnly() {} catch {}

        try this.targetSelectors() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 38482);
        try this.fuzz_crashWBTCPythPrice(1524785991) {} catch {}

        vm.warp(block.timestamp + 2);
        vm.roll(block.number + 9920);
        try this.fuzz_liquidatePosition() {} catch {}

        try this.fuzz_changeWBTCPythPrice(1524785993) {} catch {}

        try this.excludeSelectors() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1126);
        try this.targetContracts() {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 59552);
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1123);
        try
            this.fuzz_changeOracleManagerPrice(
                16108137129675985311765539543168960949469269880673140394029440390106972248901,
                4370000
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 43566);
        try this.fuzz_crashWBTCPythPrice(479) {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 22909);
        fuzz_guided_depositAndShort();
    }

    function test_replay_ORD_06() public {
    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 30784);
    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 47075);

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 1984);
    try this.fuzz_liquidateFlagged(255) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 57086);
    try this.targetSelectors() {} catch {}

    try this.pendingOrder(4370001) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 18429);
    try this.fuzz_crashWBTCPythPrice(97763304270169842022958351549980933720889961422771233997648021739730454106449) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 23885);
    try this.fuzz_mintUSDToSynthetix(31004824895038848336123351504674218067884513431535398913320363972500139349820) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 33357);
    try this.repayDebt() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 9920);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 20330);
    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 4223);
    try this.excludeSenders() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 53401);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 31855);
    try this.fuzz_pumpWBTCPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639935) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 5237);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 1123);
    try this.fuzz_liquidateFlagged(211) {} catch {}

    try this.excludeArtifacts() {} catch {}

    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 30784);
    try this.fuzz_settleOrder() {} catch {}

    try this.pendingOrder(45715921897694382444837919847477853615) {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 20423);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 39065);
    try this.repayDebt() {} catch {}

    try this.fuzz_crashWBTCPythPrice(1959666828) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 5053);

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 31232);
    try this.fuzz_delegateCollateral(73586105389871065024309079169377356925,340282366920938463463374607431768211451,111952024884698670749200360103275750182492020591309667656863879809313317970969,49433747785885920535123841528702349708876198341732947037937772595870572133380,13734365721825661575792644612234278803374276684009917589832307629388212446829) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 23978);

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 27404);
    try this.fuzz_changeWBTCPythPrice(1524785993) {} catch {}

    vm.warp(block.timestamp + 10);
    vm.roll(block.number + 34833);

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 3661);
    try this.fuzz_payDebt(340282366920938463463374607431768211455) {} catch {}

    try this.IS_TEST() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 20544);
    try this.excludeArtifacts() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 46422);
    try this.fuzz_cancelOrder(79) {} catch {}

    vm.warp(block.timestamp + 8);
    vm.roll(block.number + 4461);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 42101);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 32767);
    try this.targetInterfaces() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 48838);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 1984);
    try this.fuzz_liquidateFlagged(131) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 38100);

    try this.fuzz_pumpWBTCPythPrice(654) {} catch {}

    try this.targetInterfaces() {} catch {}

    try this.fuzz_liquidateFlaggedAccounts(231) {} catch {}

    vm.warp(block.timestamp + 6);
    vm.roll(block.number + 71856);

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 45819);
    try this.pendingOrder(149053997303307659174860200904428968983) {} catch {}

    try this.fuzz_payDebt(4370001) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 25914);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 24311);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 7323);
    try this.fuzz_changeWBTCPythPrice(163488184649764530612029207895290063304) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 19933);
    try this.targetInterfaces() {} catch {}

    try this.fuzz_delegateCollateral(324881726920680743875558567520921699364,299378364212346172418018372495486214463,1524785993,34,104848205247731826170569411881375073004423659710533487115435099019864391055697) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 11905);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 27404);
    try this.fuzz_pumpWBTCPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639935) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 2511);
    try this.targetContracts() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 16089);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 53166);
    try this.fuzz_cancelOrder(255) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 15005);

    try this.failed() {} catch {}

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 15005);

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 60267);
    try this.fuzz_crashWETHPythPrice(4369999) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 59983);
    try this.fuzz_crashWBTCPythPrice(0) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 1984);

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 27404);
    try this.fuzz_pumpWETHPythPrice(90517771028406769566162170133318295582510779081549214498240890628029059331102) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 11942);
    try this.targetArtifacts() {} catch {}

    fuzz_settleOrder();

}

function test_replay_ORD_03() public {

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 30784);
    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 47075);

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 1984);
    try this.fuzz_liquidateFlagged(255) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 57086);
    try this.targetSelectors() {} catch {}

    try this.pendingOrder(4370001) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 18429);
    try this.fuzz_crashWBTCPythPrice(97763304270169842022958351549980933720889961422771233997648021739730454106449) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 23885);
    try this.fuzz_mintUSDToSynthetix(31004824895038848336123351504674218067884513431535398913320363972500139349820) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 33357);
    try this.repayDebt() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 9920);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 20330);
    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 4223);
    try this.excludeSenders() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 53401);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 31855);
    try this.fuzz_pumpWBTCPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639935) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 5237);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 1123);
    try this.fuzz_liquidateFlagged(211) {} catch {}

    try this.excludeArtifacts() {} catch {}

    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 30784);
    try this.fuzz_settleOrder() {} catch {}

    try this.pendingOrder(45715921897694382444837919847477853615) {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 20423);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 39065);
    try this.repayDebt() {} catch {}

    try this.fuzz_crashWBTCPythPrice(1959666828) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 5053);

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 31232);
    try this.fuzz_delegateCollateral(73586105389871065024309079169377356925,340282366920938463463374607431768211451,111952024884698670749200360103275750182492020591309667656863879809313317970969,49433747785885920535123841528702349708876198341732947037937772595870572133380,13734365721825661575792644612234278803374276684009917589832307629388212446829) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 23978);

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 27404);
    try this.fuzz_changeWBTCPythPrice(1524785993) {} catch {}

    vm.warp(block.timestamp + 10);
    vm.roll(block.number + 34833);

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 3661);
    try this.fuzz_payDebt(340282366920938463463374607431768211455) {} catch {}

    try this.IS_TEST() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 20544);
    try this.excludeArtifacts() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 46422);
    try this.fuzz_cancelOrder(79) {} catch {}

    vm.warp(block.timestamp + 8);
    vm.roll(block.number + 4461);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 42101);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 32767);
    try this.targetInterfaces() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 48838);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 1984);
    try this.fuzz_liquidateFlagged(131) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 38100);

    try this.fuzz_pumpWBTCPythPrice(654) {} catch {}

    try this.targetInterfaces() {} catch {}

    try this.fuzz_liquidateFlaggedAccounts(231) {} catch {}

    vm.warp(block.timestamp + 6);
    vm.roll(block.number + 71856);

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 45819);
    try this.pendingOrder(149053997303307659174860200904428968983) {} catch {}

    try this.fuzz_payDebt(4370001) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 25914);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 24311);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 7323);
    try this.fuzz_changeWBTCPythPrice(163488184649764530612029207895290063304) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 19933);
    try this.targetInterfaces() {} catch {}

    try this.fuzz_delegateCollateral(324881726920680743875558567520921699364,299378364212346172418018372495486214463,1524785993,34,104848205247731826170569411881375073004423659710533487115435099019864391055697) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 11905);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 27404);
    try this.fuzz_pumpWBTCPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639935) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 2511);
    try this.targetContracts() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 16089);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 53166);
    try this.fuzz_cancelOrder(255) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 15005);

    try this.failed() {} catch {}

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 15005);

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 60267);
    try this.fuzz_crashWETHPythPrice(4369999) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 59983);
    try this.fuzz_crashWBTCPythPrice(0) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 1984);

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 27404);
    try this.fuzz_pumpWETHPythPrice(90517771028406769566162170133318295582510779081549214498240890628029059331102) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 11942);
    try this.targetArtifacts() {} catch {}

    fuzz_settleOrder();

}

function test_replay_1() public {
    try this.fuzz_mintUSDToSynthetix(302184340354016905372) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 32);
    try this.failed() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 362);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 1009);
    try this.IS_TEST() {} catch {}

    try this.fuzz_guided_depositAndShort() {} catch {}

    try this.fuzz_cancelOrder(217) {} catch {}

    try this.fuzz_settleOrder() {} catch {}

    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 8712);
    try this.fuzz_changeWBTCPythPrice(2535184543385746566613620113005445917) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 23653);
    try this.fuzz_crashWETHPythPrice(62943733531385890727537375521146766412812133556959884117353897448008177959488) {} catch {}

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 40523);
    try this.fuzz_guided_depositAndShort() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 11942);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 255);
    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 2088);
    try this.targetContracts() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 5936);
    try this.targetSelectors() {} catch {}

    fuzz_guided_createDebt_LiquidateMarginOnly(false,-688258361913379627464109897885261016325269002827329341759227599313197376555);

}

function test_replay_2() public {
    vm.warp(block.timestamp + 6);
    vm.roll(block.number + 2512);
    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 646);
    try this.excludeSenders() {} catch {}

    try this.fuzz_mintUSDToSynthetix(1053370359952318891024) {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 30042);
    try this.fuzz_changeWETHPythPrice(-1844674407370955162) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 59983);
    try this.fuzz_crashWBTCPythPrice(13213962371358619255748321043984948384775961621107331590340878566917360285016) {} catch {}

    try this.targetSelectors() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 2512);
    try this.fuzz_mintUSDToSynthetix(0) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 42101);
    try this.fuzz_changeOracleManagerPrice(109591890307729417781552227773032467187977639613988525917770060277695092099290,-57896044618658097711785492504343953926634992332820282019728792003956564819968) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 32);
    try this.failed() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 53011);
    try this.targetContracts() {} catch {}

    try this.fuzz_payDebt(33373309752447458665137362338795803888) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 35200);
    try this.fuzz_burnUSDFromSynthetix(7082710733011350402678381743339822417442319384945245245511628362945276209889) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 32);
    try this.excludeSelectors() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 42229);
    try this.failed() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 11349);
    try this.fuzz_cancelOrder(255) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 4896);
    try this.pendingOrder(292469035542172425704976889468993127817) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 2512);
    try this.fuzz_guided_createDebt_LiquidateMarginOnly(true,57896044618658097711785492504343953926634992332820282019728792003956564819967) {} catch {}

    try this.targetSelectors() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 1123);
    try this.fuzz_delegateCollateral(299305813485026008891114182059725427505,340282366920938463463374607431768211455,1524785992,33971728550465428007114855385970183771523417823234634630862907328456601492221,4370001) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 34499);
    try this.targetContracts() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 1984);
    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 2511);
    try this.IS_TEST() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 11826);
    try this.fuzz_guided_createDebt_LiquidateMarginOnly(true,4370001) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 59981);
    try this.fuzz_settleOrder() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 12053);
    try this.IS_TEST() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 12493);
    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 59983);
    try this.excludeSenders() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 11614);
    try this.fuzz_crashWBTCPythPrice(13772941003530045764428119458433173853840205867961955647032860787574170765570) {} catch {}

    try this.fuzz_changeOracleManagerPrice(68543532988399466453610197693480161420536710096061819657639739358648259587606,-57896044618658097711785492504343953926634992332820282019728792003956564819968) {} catch {}

    try this.repayDebt() {} catch {}

    try this.excludeContracts() {} catch {}

    try this.targetContracts() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 30011);
    try this.fuzz_pumpWBTCPythPrice(33243220162798298012979977388527548965241018119881429067304196241711874825860) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 2526);
    try this.repayDebt() {} catch {}

    try this.fuzz_commitOrder(-170141183460469231731687303715884105728,1524785993) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 51197);
    try this.fuzz_pumpWBTCPythPrice(1524785992) {} catch {}

    try this.repayDebt() {} catch {}

    try this.fuzz_guided_createDebt_LiquidateMarginOnly(true,35570742530225601178609) {} catch {}

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 42101);
    try this.targetContracts() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 32147);
    try this.fuzz_changeWETHPythPrice(9031994711711275165) {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 4223);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 60267);
    try this.fuzz_crashWBTCPythPrice(1524785991) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 127);
    try this.fuzz_changeWETHPythPrice(855648597860229939) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 32767);
    try this.fuzz_pumpWETHPythPrice(7235805) {} catch {}

    try this.fuzz_mintUSDToSynthetix(76509814715751641452887817845634907473764967081414554754577429503922034250987) {} catch {}

    try this.excludeContracts() {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 16505);
    try this.targetSenders() {} catch {}

    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 11349);
    try this.excludeArtifacts() {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 12155);
    try this.fuzz_guided_depositAndShort() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 4462);
    try this.repayDebt() {} catch {}

    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 20421);
    try this.pendingOrder(1524785991) {} catch {}

    vm.warp(block.timestamp + 6);
    vm.roll(block.number + 45852);
    try this.fuzz_crashWBTCPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639931) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 33357);
    try this.targetInterfaces() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 51417);
    try this.fuzz_pumpWETHPythPrice(17240179605690149668548869295881664145874253435648968247716565698064348102428) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 384);
    try this.fuzz_crashWETHPythPrice(7236857) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 1123);
    try this.fuzz_changeOracleManagerPrice(68543532988399466453610197693480161420536710096061819657639739358648259587606,-57896044618658097711785492504343953926634992332820282019728792003956564819968) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 24311);
    try this.repayDebt() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 53349);
    try this.fuzz_liquidateFlagged(0) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 50499);
    try this.fuzz_pumpWETHPythPrice(4369999) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 54809);
    try this.fuzz_guided_createDebt_LiquidateMarginOnly(false,49807959642801416320228675332378762857025516297956882136175948639702532331720) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 33357);
    try this.fuzz_cancelOrder(251) {} catch {}

    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 5952);
    try this.failed() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 8447);
    try this.pendingOrder(4370000) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 31232);
    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 36859);
    try this.fuzz_settleOrder() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 23885);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 23653);
    try this.fuzz_liquidatePosition() {} catch {}

    vm.warp(block.timestamp + 6);
    vm.roll(block.number + 23885);
    try this.fuzz_cancelOrder(85) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 2511);
    try this.fuzz_delegateCollateral(4370000,4369999,75907220432724368803198130479570811972721266124871267762641649299410894970149,4370000,1524785992) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 44774);
    try this.fuzz_cancelOrder(79) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 34720);
    try this.fuzz_commitOrder(4369999,374) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 23653);
    try this.fuzz_guided_createDebt_LiquidateMarginOnly(false,5851488736995640996587196612000124804499569175716855462416963819403253196834) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 55996);
    try this.excludeArtifacts() {} catch {}

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 53562);
    try this.targetSenders() {} catch {}

    try this.fuzz_settleOrder() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 38100);
    try this.fuzz_payDebt(1524785992) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 1123);
    try this.fuzz_delegateCollateral(8951754419206282287830289011282125904,177294568814184838831556898465195374600,115792089237316195423570985008687907853269984665640564039457584007913129639935,4370001,4370001) {} catch {}

    try this.fuzz_changeOracleManagerPrice(68543532988399466453610197693480161420536710096061819657639739358648259587606,-57896044618658097711785492504343953926634992332820282019728792003956564819968) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 35200);
    try this.fuzz_burnUSDFromSynthetix(1524785991) {} catch {}

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 1088);
    try this.fuzz_liquidatePosition() {} catch {}

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 23885);
    try this.fuzz_pumpWETHPythPrice(99483987058280629765642907709389824007688524678081592057539731843845477843352) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 6234);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 6);
    vm.roll(block.number + 42595);
    try this.pendingOrder(14708830571884307050047444771388765287) {} catch {}

    try this.fuzz_liquidateFlagged(255) {} catch {}

    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 54155);
    try this.repayDebt() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 4223);
    try this.fuzz_changeWETHPythPrice(9223372036854775624) {} catch {}

    vm.warp(block.timestamp + 6);
    vm.roll(block.number + 24311);
    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 1123);
    try this.fuzz_settleOrder() {} catch {}

    try this.fuzz_liquidateMarginOnly() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 27404);
    try this.fuzz_pumpWETHPythPrice(411) {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 561);
    try this.fuzz_liquidatePosition() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 53349);
    try this.fuzz_changeOracleManagerPrice(71859239788906947362098768199103329501679156948949186863095893819681569553719,381285189) {} catch {}

    try this.fuzz_pumpWETHPythPrice(115792089237316195423570985008687907853269984665640564039457584007913129639932) {} catch {}

    fuzz_liquidatePosition();

}

function test_replay_3() public {

    try this.fuzz_guided_depositAndShort() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 60054);
    try this.fuzz_mintUSDToSynthetix(438001259193840493379947231778625579016462228119637906734679540436265922125) {} catch {}

    try this.fuzz_cancelOrder(0) {} catch {}

    try this.fuzz_liquidateFlagged(11) {} catch {}

    try this.pendingOrder(51877116554379493986134066429081221062) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 130);
    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 22909);
    try this.fuzz_guided_depositAndShortWBTC() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 561);

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 13140);
    try this.failed() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 15607);

    try this.excludeSenders() {} catch {}

    try this.fuzz_settleOrder() {} catch {}

    try this.fuzz_commitOrder(14614177305909271056140552492186005659,12721204243872848967917537612231287894852946851224718147797556450121235004515) {} catch {}

    try this.fuzz_settleOrder() {} catch {}

    try this.targetContracts() {} catch {}

    try this.pendingOrder(66814797889663324868866780748783410) {} catch {}

    try this.fuzz_pumpWETHPythPrice(22) {} catch {}

    try this.fuzz_pumpWBTCPythPrice(8443035976361093256510680899946151228936309536033254709106122953671052751024) {} catch {}

    try this.fuzz_liquidateFlaggedAccounts(15) {} catch {}

    try this.targetContracts() {} catch {}

    try this.targetArtifacts() {} catch {}

    fuzz_cancelOrder(4);

}

function test_replay_ORD_11() public {
    vm.warp(block.timestamp + 4);
    vm.roll(block.number + 7554);
    try this.targetSenders() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 23978);
    try this.fuzz_mintUSDToSynthetix(44512326140755938837471604097781613970919783210940354976799759187887441995030) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 1088);
    try this.fuzz_pumpWBTCPythPrice(290399458) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 60248);
    try this.fuzz_guided_depositAndShort() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 24311);
    try this.fuzz_payDebt(15542871232916297858979876351085780588) {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 30011);
    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 53451);
    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 4223);

    try this.fuzz_liquidateFlaggedAccounts(68) {} catch {}

    try this.fuzz_modifyCollateral(4369999,115792089237316195423570985008687907853269984665640564039457584007913129639932) {} catch {}

    try this.pendingOrder(79511705124259338158861746078780582003) {} catch {}

    try this.IS_TEST() {} catch {}

    try this.fuzz_liquidateFlaggedAccounts(12) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 12493);

    try this.fuzz_settleOrder() {} catch {}

    try this.fuzz_cancelOrder(1) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 23653);
    try this.fuzz_pumpWETHPythPrice(712) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 9247);
    try this.fuzz_liquidateFlagged(37) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 33357);
    try this.fuzz_pumpWETHPythPrice(48989836385110917501810429311434116749358808480950517272197543295197818783730) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 21514);
    try this.excludeContracts() {} catch {}

    try this.fuzz_changeWETHPythPrice(772) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 2143);
    try this.targetSelectors() {} catch {}

    try this.excludeArtifacts() {} catch {}

    vm.warp(block.timestamp + 2);
    vm.roll(block.number + 5754);
    try this.fuzz_guided_depositAndShort() {} catch {}

    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 9966);
    try this.targetSelectors() {} catch {}

    vm.warp(block.timestamp + 5);
    vm.roll(block.number + 834);
    try this.fuzz_liquidateFlagged(12) {} catch {}

    try this.fuzz_delegateCollateral(1524785992,303826957011959888453374201252020363465,3708653709488768623246230057685857076992372786105501136551013843585008823551,30400941437646695825202161979155047473141937138863293561269294534129880227630,377717999039000373186817408183203376402220484888931941093888422570538357224) {} catch {}

    try this.targetSelectors() {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 69960);

    try this.repayDebt() {} catch {}

    try this.excludeArtifacts() {} catch {}

    try this.fuzz_settleOrder() {} catch {}

    try this.fuzz_pumpWETHPythPrice(2) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 60054);
    try this.fuzz_liquidateFlagged(5) {} catch {}

    vm.warp(block.timestamp + 1);
    vm.roll(block.number + 589);
    try this.targetArtifactSelectors() {} catch {}

    vm.warp(block.timestamp + 3);
    vm.roll(block.number + 8447);
    fuzz_guided_createDebt_LiquidateMarginOnly(false,1090423519681558568);

}
}
