// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import {SettlementStrategy} from "../storage/SettlementStrategy.sol";
import {MarketConfiguration} from "../../storage.dump.sol";
import {Flags} from "../utils/Flags.sol";
import {AccountRBAC} from "@synthetixio/main/contracts/storage/AccountRBAC.sol";
import "@perimetersec/fuzzlib/src/FuzzBase.sol";

import "./helper/FuzzStorageVariables.sol";
contract FuzzSetup is FuzzBase, FuzzStorageVariables {
    function setup() internal {
        //Foundry comparibility
        checkCaller = new CheckCaller();

        router = new MockRouter();
        perps = address(new Proxy(address(router), address(this)));

        deployImplementations();

        addAsyncOrderModuleSels();
        addAsyncOrderCancelModuleSels();
        addAsyncOrderSettlementPythModuleSels();
        addCollateralConfigurationModuleSels();
        addGlobalPerpsMarketModuleSels();
        addMarketConfigurationModuleSels();
        addPerpsAccountModuleSels();
        addPerpsMarketFactoryModuleSels();
        addPerpsMarketModuleSels();
        addLiquidationModuleSels();
        addMockLensModuleSels();
        addFeatureFlagModuleSels();
        addMockModuleSels();
        addMockPythERC7412WrapperSels();
        //bootstrap()
        setPythPriceFeed();
        addWETHSettlementStrategy();
        addWBTCSettlementStrategy();
        addHUGESettlementStrategy();
        setSnxUSDCollateralConfiguration();
        setWETHCollateralConfiguration();
        setWBTCCollateralConfiguration();
        setHUGECollateralConfiguration();
        registerWETHDistributor();
        registerWBTCDistributor();
        registerHugeDistributor();
        setSynthMaketIdAndAddresses();

        //bootstrapPerpsMarkets()
        addToFeatureFlagAllowlist();
        enableAllFeatureFlags();
        initializePerpsMarketFactory();
        setPerpsMarketName();
        setCreateMarketWETH();
        setCreateMarketWBTC();
        setCreateMarketHUGE();
        setUpdatePriceDataWETH();
        setUpdatePriceDataWBTC();
        setUpdatePriceDataHUGE();
        setFundingParametersWETH();
        setFundingParametersWBTC();
        setFundingParametersHUGE();
        setMaxMarketSizeWETH();
        setMaxMarketSizeWBTC();
        setMaxMarketSizeHUGE();
        setMaxMarketValueWETH();
        setMaxMarketValueWBTC();
        setMaxMarketValueHUGE();
        setOrderFeesWETH();
        setOrderFeesWBTC();
        setOrderFeesHUGE();
        setLiquidationParametersWETH();
        setLiquidationParametersWBTC();
        setLiquidationParametersHUGE();
        setMaxLiquidationParametersWETH();
        setMaxLiquidationParametersWBTC();
        setMaxLiquidationParametersHUGE();
        createKeeperCostNode();
        updateKeeperCostNodeId();
        createAccounts();
        grantAccountPermissions();
        setMaxCollateralsPerAccount();
        setPerpMarketFactoryModuleImplInVault();
        setupActors();
    }

    function deployImplementations() private {
        sUSDTokenMock = new MockERC20("sUSD Token", "sUSD", 18);
        wethTokenMock = new MockERC20("weth Token", "WETH", 18);
        wbtcTokenMock = new MockERC20("wbtc Token", "WBTC", 18);
        hugePrecisionTokenMock = new MockERC20(
            "Huge Precision Token",
            "HUGE",
            30
        );

        v3Mock = new MockSynthetixV3();

        deployMockOracleManager();
        deployMockSpotMarket();
        deployMockPythERC7412Wrapper();

        setOracleManager();
        setMockSynthetixUSDToken();
        setMockWethToken();
        setMockWbtcToken();
        setMockhugeToken();
        // increaseCreditCapacity();

        coreModuleImpl = new CoreModule();

        asyncOrderCancelModuleImpl = new AsyncOrderCancelModule();
        asyncOrderModuleImpl = new AsyncOrderModule();
        asyncOrderSettlementPythModuleImpl = new AsyncOrderSettlementPythModule();
        collateralConfigurationModuleImpl = new CollateralConfigurationModule();
        featureFlagModuleImpl = new FeatureFlagModule();
        globalPerpsMarketModuleImpl = new GlobalPerpsMarketModule();
        liquidationModuleImpl = new LiquidationModule();
        marketConfigurationModuleImpl = new MarketConfigurationModule();
        perpsAccountModuleImpl = new PerpsAccountModule();
        perpsMarketFactoryModuleImpl = new PerpsMarketFactoryModule();
        perpsMarketModuleImpl = new PerpsMarketModule();

        //Mocks
        mockModuleImpl = new MockModule();
        mockPyth = new MockPyth();

        rewardWETHDistributorMock = new MockRewardDistributor(
            v3Mock,
            REWARD_DISTRIBUTOR_WETH_POOL_ID,
            1 //WETH
        );
        rewardWBTCDistributorMock = new MockRewardDistributor(
            v3Mock,
            REWARD_DISTRIBUTOR_WBTC_POOL_ID,
            2 //WBTC
        );
        rewardHUGEDistributorMock = new MockRewardDistributor(
            v3Mock,
            REWARD_DISTRIBUTOR_HUGE_POOL_ID,
            3 //WBTC
        );

        vaultModuleMock = new MockVaultModule(v3Mock, perps);
        mockLensModuleImpl = new MockLensModule();
    }

    function deployMockPythERC7412Wrapper() private {
        pythWrapper = new MockPythERC7412Wrapper(address(mockOracleManager));
        pythWrapper.setBenchmarkPrice(WETH_FEED_ID, 3_000e18);
        pythWrapper.setBenchmarkPrice(WBTC_FEED_ID, 10_000e18);
    }

    function deployMockOracleManager() private {
        bytes32[] memory initialIds = new bytes32[](4);
        int256[] memory initialPrices = new int256[](4);

        initialIds[0] = SUSD_ORACLE_NODE_ID;
        initialIds[1] = WETH_ORACLE_NODE_ID;
        initialIds[2] = WBTC_ORACLE_NODE_ID;
        initialIds[3] = KEEPER_NODE_ID;

        initialPrices[0] = 1e18;
        initialPrices[1] = 3_000e18;
        initialPrices[2] = 10_000e18;
        initialPrices[3] = 1e18;

        tokenChainlinkNode[address(sUSDTokenMock)] = SUSD_ORACLE_NODE_ID;
        tokenChainlinkNode[address(wethTokenMock)] = WETH_ORACLE_NODE_ID;
        tokenChainlinkNode[address(wbtcTokenMock)] = WBTC_ORACLE_NODE_ID;
        tokenChainlinkNode[
            address(hugePrecisionTokenMock)
        ] = HUGE_ORACLE_NODE_ID;

        mockOracleManager = new MockOracleManager(initialIds, initialPrices);
    }

    function deployMockSpotMarket() private {
        spot = new MockSpotMarket(
            v3Mock,
            mockOracleManager,
            address(wethTokenMock),
            WETH_MARKET_SKEW_SCALE,
            address(wbtcTokenMock),
            WBTC_MARKET_SKEW_SCALE,
            address(hugePrecisionTokenMock),
            HUGE_MARKET_SKEW_SCALE,
            WETH_ORACLE_NODE_ID,
            WBTC_ORACLE_NODE_ID,
            HUGE_ORACLE_NODE_ID
        );
    }

    function setOracleManager() private {
        v3Mock.setOracleManager(address(mockOracleManager));
    }

    function setMockSynthetixUSDToken() private {
        v3Mock.setUSDToken(address(sUSDTokenMock), SUSD_ORACLE_NODE_ID);
    }

    function setMockWethToken() private {
        v3Mock.setWethToken(address(wethTokenMock), WETH_ORACLE_NODE_ID);
    }

    function setMockWbtcToken() private {
        v3Mock.setWbtcToken(address(wbtcTokenMock), WBTC_ORACLE_NODE_ID);
    }
    function setMockhugeToken() private {
        v3Mock.setHugeToken(
            address(hugePrecisionTokenMock),
            HUGE_ORACLE_NODE_ID
        );
    }

    function increaseCreditCapacity() private {
        v3Mock.updateCreditCapacity(type(uint64).max, true);
    }

    function addLiquidationModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                liquidationModuleImpl.liquidate.selector,
                address(liquidationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                liquidationModuleImpl.liquidateMarginOnly.selector,
                address(liquidationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                liquidationModuleImpl.liquidateFlagged.selector,
                address(liquidationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                liquidationModuleImpl.liquidateFlaggedAccounts.selector,
                address(liquidationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                liquidationModuleImpl.flaggedAccounts.selector,
                address(liquidationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                liquidationModuleImpl.canLiquidate.selector,
                address(liquidationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                liquidationModuleImpl.canLiquidateMarginOnly.selector,
                address(liquidationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                liquidationModuleImpl.liquidationCapacity.selector,
                address(liquidationModuleImpl)
            )
        );
        assert(success);
    }
    function addAsyncOrderModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderModuleImpl.commitOrder.selector,
                address(asyncOrderModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderModuleImpl.getOrder.selector,
                address(asyncOrderModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderModuleImpl.computeOrderFees.selector,
                address(asyncOrderModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderModuleImpl.computeOrderFeesWithPrice.selector,
                address(asyncOrderModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderModuleImpl.getSettlementRewardCost.selector,
                address(asyncOrderModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderModuleImpl.requiredMarginForOrder.selector,
                address(asyncOrderModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderModuleImpl.requiredMarginForOrderWithPrice.selector,
                address(asyncOrderModuleImpl)
            )
        );
        assert(success);
    }
    function addAsyncOrderCancelModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderCancelModuleImpl.cancelOrder.selector,
                address(asyncOrderCancelModuleImpl)
            )
        );
        assert(success);
    }

    function addMockPythERC7412WrapperSels() private {
        pythWrapper.setBenchmarkPrice(WETH_FEED_ID, 3_000e18);
        pythWrapper.setBenchmarkPrice(WBTC_FEED_ID, 10_000e18);
    }

    function addAsyncOrderSettlementPythModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                asyncOrderSettlementPythModuleImpl.settleOrder.selector,
                address(asyncOrderSettlementPythModuleImpl)
            )
        );
        assert(success);
    }

    function addCollateralConfigurationModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                collateralConfigurationModuleImpl
                    .setCollateralConfiguration
                    .selector,
                address(collateralConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                collateralConfigurationModuleImpl
                    .getCollateralConfiguration
                    .selector,
                address(collateralConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                collateralConfigurationModuleImpl
                    .getCollateralConfigurationFull
                    .selector,
                address(collateralConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                collateralConfigurationModuleImpl
                    .setCollateralLiquidateRewardRatio
                    .selector,
                address(collateralConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                collateralConfigurationModuleImpl
                    .getCollateralLiquidateRewardRatio
                    .selector,
                address(collateralConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                collateralConfigurationModuleImpl.registerDistributor.selector,
                address(collateralConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                collateralConfigurationModuleImpl.isRegistered.selector,
                address(collateralConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                collateralConfigurationModuleImpl
                    .getRegisteredDistributor
                    .selector,
                address(collateralConfigurationModuleImpl)
            )
        );
        assert(success);
    }

    function addGlobalPerpsMarketModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.getSupportedCollaterals.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.setKeeperRewardGuards.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.getKeeperRewardGuards.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.totalGlobalCollateralValue.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.globalCollateralValue.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.setFeeCollector.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.getFeeCollector.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.updateKeeperCostNodeId.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.getKeeperCostNodeId.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.updateReferrerShare.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.getReferrerShare.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.getMarkets.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.setPerAccountCaps.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.getPerAccountCaps.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.setInterestRateParameters.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.getInterestRateParameters.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                globalPerpsMarketModuleImpl.updateInterestRate.selector,
                address(globalPerpsMarketModuleImpl)
            )
        );
        assert(success);
    }

    function addMarketConfigurationModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.addSettlementStrategy.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.setSettlementStrategy.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl
                    .setSettlementStrategyEnabled
                    .selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.setOrderFees.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.updatePriceData.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.getPriceData.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.setMaxMarketSize.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.setMaxMarketValue.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.setFundingParameters.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl
                    .setMaxLiquidationParameters
                    .selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.setLiquidationParameters.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.setLockedOiRatio.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.getSettlementStrategy.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl
                    .getMaxLiquidationParameters
                    .selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.getLiquidationParameters.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.getFundingParameters.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.getMaxMarketSize.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.getMaxMarketValue.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.getOrderFees.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                marketConfigurationModuleImpl.getLockedOiRatio.selector,
                address(marketConfigurationModuleImpl)
            )
        );
        assert(success);
    }

    function addPerpsAccountModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.modifyCollateral.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.debt.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.payDebt.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.totalCollateralValue.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.totalAccountOpenInterest.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.getOpenPosition.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.getOpenPositionSize.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.getAvailableMargin.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.getWithdrawableMargin.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.getRequiredMargins.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.getCollateralAmount.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.getAccountCollateralIds.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsAccountModuleImpl.getAccountOpenPositions.selector,
                address(perpsAccountModuleImpl)
            )
        );
        assert(success);
    }

    function addPerpsMarketFactoryModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.initializeFactory.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.setPerpsMarketName.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.createMarket.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.name.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.reportedDebt.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.minimumCredit.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.interestRate.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.utilizationRate.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketFactoryModuleImpl.supportsInterface.selector,
                address(perpsMarketFactoryModuleImpl)
            )
        );
        assert(success);
    }

    function addPerpsMarketModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.metadata.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.skew.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.size.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.maxOpenInterest.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.currentFundingRate.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.currentFundingVelocity.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.indexPrice.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.fillPrice.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                perpsMarketModuleImpl.getMarketSummary.selector,
                address(perpsMarketModuleImpl)
            )
        );
        assert(success);
    }

    function addMockModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockModuleImpl.createAccount.selector,
                address(mockModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockModuleImpl.grantPermission.selector,
                address(mockModuleImpl)
            )
        );
        assert(success);
    }

    function addFeatureFlagModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.setFeatureFlagAllowAll.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.setFeatureFlagDenyAll.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.addToFeatureFlagAllowlist.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.removeFromFeatureFlagAllowlist.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.setDeniers.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.getDeniers.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.getFeatureFlagAllowAll.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.getFeatureFlagDenyAll.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.getFeatureFlagAllowlist.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                featureFlagModuleImpl.isFeatureAllowed.selector,
                address(featureFlagModuleImpl)
            )
        );
        assert(success);
    }

    function addMockLensModuleSels() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.isOrderExpired.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.getOrder.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.getSettlementRewardCost.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.calculateFillPrice.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.getOpenPositionMarketIds.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);
        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.getGlobalCollateralTypes.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);
        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.getGlobalTotalAccountsDebt.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);
        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.getDebtCorrectionAccumulator.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);
        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.getPositionData.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);
        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.isAccountLiquidatable.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                router.addFunctionAndImplementation.selector,
                mockLensModuleImpl.getMaxLiquidatableAmount.selector,
                address(mockLensModuleImpl)
            )
        );
        assert(success);
    }

    function enableAllFeatureFlags() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                featureFlagModuleImpl.setFeatureFlagAllowAll.selector,
                Flags.PERPS_SYSTEM,
                true
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                featureFlagModuleImpl.setFeatureFlagAllowAll.selector,
                Flags.CREATE_MARKET,
                true
            )
        );
        assert(success);
    }

    function addWETHSettlementStrategy() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.addSettlementStrategy.selector,
                1, // marketId
                SettlementStrategy.Data({
                    strategyType: WETH_SETTLEMENT_STRATEGY_TYPE,
                    settlementDelay: WETH_SETTLEMENT_DELAY,
                    settlementWindowDuration: WETH_SETTLEMENT_WINDOW_DURATION,
                    priceVerificationContract: address(pythWrapper),
                    feedId: WETH_FEED_ID,
                    settlementReward: WETH_SETTLEMENT_REWARD,
                    disabled: WETH_DISABLED,
                    commitmentPriceDelay: WETH_COMMITMENT_PRICE_DELAY
                })
            )
        );
        assert(success);
    }

    function addWBTCSettlementStrategy() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.addSettlementStrategy.selector,
                2, // marketId
                SettlementStrategy.Data({
                    strategyType: WBTC_SETTLEMENT_STRATEGY_TYPE,
                    settlementDelay: WBTC_SETTLEMENT_DELAY,
                    settlementWindowDuration: WBTC_SETTLEMENT_WINDOW_DURATION,
                    priceVerificationContract: address(pythWrapper),
                    feedId: WBTC_FEED_ID,
                    settlementReward: WBTC_SETTLEMENT_REWARD,
                    disabled: WBTC_DISABLED,
                    commitmentPriceDelay: WBTC_COMMITMENT_PRICE_DELAY
                })
            )
        );
        assert(success);
    }
    function addHUGESettlementStrategy() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.addSettlementStrategy.selector,
                3, // marketId
                SettlementStrategy.Data({
                    strategyType: HUGE_SETTLEMENT_STRATEGY_TYPE,
                    settlementDelay: HUGE_SETTLEMENT_DELAY,
                    settlementWindowDuration: HUGE_SETTLEMENT_WINDOW_DURATION,
                    priceVerificationContract: address(pythWrapper),
                    feedId: HUGE_FEED_ID,
                    settlementReward: HUGE_SETTLEMENT_REWARD,
                    disabled: HUGE_DISABLED,
                    commitmentPriceDelay: HUGE_COMMITMENT_PRICE_DELAY
                })
            )
        );
        assert(success);
    }

    function initializePerpsMarketFactory() private {
        (
            bool success, //returns supermarket id

        ) = perps.call(
                abi.encodeWithSelector(
                    perpsMarketFactoryModuleImpl.initializeFactory.selector,
                    address(v3Mock),
                    address(spot) //TODO: reckeck
                )
            );
        assert(success);
    }

    function createKeeperCostNode() private {
        mockGasPriceNode = new MockGasPriceNode();

        (bool success, ) = address(mockGasPriceNode).call(
            abi.encodeWithSelector(
                mockGasPriceNode.setCosts.selector,
                KEEPER_SETTLEMENT_COST,
                KEEPER_FLAG_COST,
                KEEPER_LIQUIDATE_COST
            )
        );
        assert(success);
    }
    function updateKeeperCostNodeId() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                globalPerpsMarketModuleImpl.updateKeeperCostNodeId.selector,
                KEEPER_NODE_ID
            )
        );
        assert(success);
    }

    function setSnxUSDCollateralConfiguration() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                collateralConfigurationModuleImpl
                    .setCollateralConfiguration
                    .selector,
                SNX_USD_COLLATERAL_ID,
                SNX_USD_MAX_COLLATERAL_AMOUNT,
                SNX_USD_UPPER_LIMIT_DISCOUNT,
                SNX_USD_LOWER_LIMIT_DISCOUNT,
                SNX_USD_DISCOUNT_SCALAR
            )
        );
        assert(success);
    }

    function setWETHCollateralConfiguration() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                collateralConfigurationModuleImpl
                    .setCollateralConfiguration
                    .selector,
                WETH_COLLATERAL_ID,
                WETH_MAX_COLLATERAL_AMOUNT,
                WETH_UPPER_LIMIT_DISCOUNT,
                WETH_LOWER_LIMIT_DISCOUNT,
                WETH_DISCOUNT_SCALAR
            )
        );
        assert(success);
    }

    function setWBTCCollateralConfiguration() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                collateralConfigurationModuleImpl
                    .setCollateralConfiguration
                    .selector,
                WBTC_COLLATERAL_ID,
                WBTC_MAX_COLLATERAL_AMOUNT,
                WBTC_UPPER_LIMIT_DISCOUNT,
                WBTC_LOWER_LIMIT_DISCOUNT,
                WBTC_DISCOUNT_SCALAR
            )
        );
        assert(success);
    }

    function setHUGECollateralConfiguration() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                collateralConfigurationModuleImpl
                    .setCollateralConfiguration
                    .selector,
                HUGE_COLLATERAL_ID,
                HUGE_MAX_COLLATERAL_AMOUNT,
                HUGE_UPPER_LIMIT_DISCOUNT,
                HUGE_LOWER_LIMIT_DISCOUNT,
                HUGE_DISCOUNT_SCALAR
            )
        );
        assert(success);
    }

    function registerWETHDistributor() private {
        address[] memory poolDelegatedCollateralTypes = new address[](1);
        poolDelegatedCollateralTypes[0] = address(wethTokenMock);

        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                collateralConfigurationModuleImpl.registerDistributor.selector,
                address(wethTokenMock),
                address(rewardWETHDistributorMock),
                1, // collateralId WETH
                poolDelegatedCollateralTypes
            )
        );
        assert(success);
    }

    function registerWBTCDistributor() private {
        address[] memory poolDelegatedCollateralTypes = new address[](1);
        poolDelegatedCollateralTypes[0] = address(wbtcTokenMock);

        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                collateralConfigurationModuleImpl.registerDistributor.selector,
                address(wbtcTokenMock),
                address(rewardWBTCDistributorMock),
                2, // collateralId WBTC
                poolDelegatedCollateralTypes
            )
        );
        assert(success);
    }

    function registerHugeDistributor() private {
        address[] memory poolDelegatedCollateralTypes = new address[](1);
        poolDelegatedCollateralTypes[0] = address(hugePrecisionTokenMock);

        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                collateralConfigurationModuleImpl.registerDistributor.selector,
                address(hugePrecisionTokenMock),
                address(rewardHUGEDistributorMock),
                3, // collateralId HUGE
                poolDelegatedCollateralTypes
            )
        );
        assert(success);
    }

    function setSynthMaketIdAndAddresses() private {
        uint[] memory synthIds = new uint[](3);
        synthIds[0] = 1; //starting from 1 (typical dev comment :)
        synthIds[1] = 2;
        synthIds[2] = 3;

        address[] memory synthAddresses = new address[](3);
        synthAddresses[0] = address(wethTokenMock);
        synthAddresses[1] = address(wbtcTokenMock);
        synthAddresses[2] = address(hugePrecisionTokenMock);

        (bool success, ) = address(spot).call(
            abi.encodeWithSelector(
                spot.setSynthForMarketId.selector,
                synthIds,
                synthAddresses
            )
        );
        assert(success);
    }

    function addToFeatureFlagAllowlist() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                featureFlagModuleImpl.addToFeatureFlagAllowlist.selector,
                bytes32("createPool"),
                address(this)
            )
        );
        assert(success);
    }

    function createAccounts() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                mockModuleImpl.createAccount.selector,
                uint128(1),
                USER1
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                mockModuleImpl.createAccount.selector,
                uint128(2),
                USER2
            )
        );
        assert(success);

        (success, ) = perps.call(
            abi.encodeWithSelector(
                mockModuleImpl.createAccount.selector,
                uint128(3),
                USER3
            )
        );
        assert(success);
    }
    event MsgSender(address sender);
    function grantAccountPermissions() private {
        vm.prank(USER1);
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                mockModuleImpl.grantPermission.selector,
                uint128(1),
                AccountRBAC._PERPS_COMMIT_ASYNC_ORDER_PERMISSION,
                USER1
            )
        );
        assert(success);

        vm.prank(USER2);
        (success, ) = perps.call(
            abi.encodeWithSelector(
                mockModuleImpl.grantPermission.selector,
                uint128(2),
                AccountRBAC._PERPS_COMMIT_ASYNC_ORDER_PERMISSION,
                USER2
            )
        );
        assert(success);

        vm.prank(USER3);
        console2.log("Msg sender in setup", msg.sender);
        (success, ) = perps.call(
            abi.encodeWithSelector(
                mockModuleImpl.grantPermission.selector,
                uint128(3),
                AccountRBAC._PERPS_COMMIT_ASYNC_ORDER_PERMISSION,
                USER3
            )
        );
        assert(success);
    }

    function setMaxCollateralsPerAccount() private {
        (bool success, bytes memory returnData) = perps.call(
            abi.encodeWithSelector(
                globalPerpsMarketModuleImpl.setPerAccountCaps.selector,
                MAX_POSITIONS_PER_ACCOUNT,
                MAX_COLLATERALS_PER_ACCOUNT
            )
        );
        assert(success);
    }

    function setupActors() internal {
        setupAccountIds();

        bool success;
        address[] memory targets = new address[](2);
        targets[0] = address(perps);
        targets[1] = address(v3Mock);

        tokens.push(sUSDTokenMock);
        tokens.push(wethTokenMock);
        tokens.push(wbtcTokenMock);
        tokens.push(hugePrecisionTokenMock);

        for (uint8 i = 0; i < USERS.length; i++) {
            address user = USERS[i];
            (success, ) = address(user).call{value: INITIAL_BALANCE}("");
            assert(success);

            for (uint8 j = 0; j < tokens.length; j++) {
                tokens[j].mint(
                    user,
                    INITIAL_TOKEN_BALANCE * (10 ** tokens[j].decimals())
                );
                for (uint8 k = 0; k < targets.length; k++) {
                    vm.prank(user);
                    tokens[j].approve(targets[k], type(uint128).max);
                }
            }
        }

        _depositInitialAmounts(1, 0, 10_000e18);
    }

    function setupAccountIds() internal {
        userToAccountIds[USER1] = uint128(1);
        userToAccountIds[USER2] = uint128(2);
        userToAccountIds[USER3] = uint128(3);
        accountIdToUser[uint128(1)] = USER1;
        accountIdToUser[uint128(2)] = USER2;
        accountIdToUser[uint128(3)] = USER3;
    }

    function setPythPriceFeed() private {
        // Add price feeds
        addPriceFeed(
            WETH_PYTH_PRICE_FEED_ID,
            WETH_STARTING_PRICE,
            WETH_STARTING_CONF,
            WETH_STARTING_EXPO
        );
        addPriceFeed(
            WBTC_PYTH_PRICE_FEED_ID,
            WBTC_STARTING_PRICE,
            WBTC_STARTING_CONF,
            WBTC_STARTING_EXPO
        );
        addPriceFeed(
            HUGE_PYTH_PRICE_FEED_ID,
            HUGE_STARTING_PRICE,
            HUGE_STARTING_CONF,
            HUGE_STARTING_EXPO
        );

        // Set oracle nodes
        oracleNodes[WETH_ORACLE_NODE_ID] = WETH_PYTH_PRICE_FEED_ID;
        oracleNodes[WBTC_ORACLE_NODE_ID] = WBTC_PYTH_PRICE_FEED_ID;
        oracleNodes[HUGE_ORACLE_NODE_ID] = HUGE_PYTH_PRICE_FEED_ID;

        oracleNodes[WETH_PYTH_PRICE_FEED_ID] = WETH_ORACLE_NODE_ID;
        oracleNodes[WBTC_ORACLE_NODE_ID] = WBTC_ORACLE_NODE_ID;
        oracleNodes[HUGE_ORACLE_NODE_ID] = HUGE_ORACLE_NODE_ID;
    }

    function addPriceFeed(
        bytes32 id,
        int64 startingPrice,
        uint64 startingConf,
        int32 startingExpo
    ) private {
        (bool success, ) = address(mockPyth).call(
            abi.encodeWithSelector(
                mockPyth.addPriceFeed.selector,
                id,
                startingPrice,
                startingConf,
                startingExpo
            )
        );
        assert(success);
    }

    function setPythRequiredFee() private {
        mockPyth.setRequiredFee(100);
    }

    function setUpdatePriceDataWETH() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.updatePriceData.selector,
                1,
                WETH_PYTH_PRICE_FEED_ID,
                STRICT_PRICE_TOLERANCE
            )
        );
        assert(success);
    }

    function setUpdatePriceDataWBTC() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.updatePriceData.selector,
                2,
                WBTC_PYTH_PRICE_FEED_ID,
                STRICT_PRICE_TOLERANCE
            )
        );
        assert(success);
    }

    function setUpdatePriceDataHUGE() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.updatePriceData.selector,
                3,
                HUGE_PYTH_PRICE_FEED_ID,
                STRICT_PRICE_TOLERANCE
            )
        );
        assert(success);
    }
    //from test/integration/bootstrap/bootstrapPerpsMarkets.ts
    function setFundingParametersWETH() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setFundingParameters.selector,
                1,
                WETH_SKEW_SCALE,
                WETH_MAX_FUNDING_VELOCITY
            )
        );
        assert(success);
    }

    function setFundingParametersWBTC() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setFundingParameters.selector,
                2,
                WBTC_SKEW_SCALE,
                WBTC_MAX_FUNDING_VELOCITY
            )
        );
        assert(success);
    }

    function setFundingParametersHUGE() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setFundingParameters.selector,
                3,
                HUGE_SKEW_SCALE,
                HUGE_MAX_FUNDING_VELOCITY
            )
        );
        assert(success);
    }

    function setMaxMarketSizeWETH() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setMaxMarketSize.selector,
                1, // WETH market ID hardcoded
                WETH_MAX_MARKET_SIZE
            )
        );
        assert(success);
    }
    function setMaxMarketSizeWBTC() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setMaxMarketSize.selector,
                2, // WBTC market ID hardcoded
                WBTC_MAX_MARKET_SIZE
            )
        );
        assert(success);
    }
    function setMaxMarketSizeHUGE() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setMaxMarketSize.selector,
                3, // WBTC market ID hardcoded
                HUGE_MAX_MARKET_SIZE
            )
        );
        assert(success);
    }

    function setMaxMarketValueWETH() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setMaxMarketValue.selector,
                1, // WETH market ID hardcoded
                WETH_MAX_MARKET_VALUE
            )
        );
        assert(success);
    }

    function setMaxMarketValueWBTC() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setMaxMarketValue.selector,
                2, // WBTC market ID hardcoded
                WBTC_MAX_MARKET_VALUE
            )
        );
        assert(success);
    }

    function setMaxMarketValueHUGE() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setMaxMarketValue.selector,
                3, // WBTC market ID hardcoded
                HUGE_MAX_MARKET_VALUE
            )
        );
        assert(success);
    }

    function setOrderFeesWETH() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setOrderFees.selector,
                1, // WETH market ID hardcoded
                WETH_MAKER_FEE_RATIO,
                WETH_TAKER_FEE_RATIO
            )
        );
        assert(success);
    }

    function setOrderFeesWBTC() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setOrderFees.selector,
                2, // WBTC market ID hardcoded
                WBTC_MAKER_FEE_RATIO,
                WBTC_TAKER_FEE_RATIO
            )
        );
        assert(success);
    }
    function setOrderFeesHUGE() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setOrderFees.selector,
                3, // WBTC market ID hardcoded
                HUGE_MAKER_FEE_RATIO,
                HUGE_TAKER_FEE_RATIO
            )
        );
        assert(success);
    }

    function setLiquidationParametersWETH() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setLiquidationParameters.selector,
                1,
                WETH_INITIAL_MARGIN_FRACTION,
                WETH_MINIMUM_INITIAL_MARGIN_RATIO,
                WETH_MAINTENANCE_MARGIN_SCALAR,
                WETH_LIQUIDATION_REWARD_RATIO,
                WETH_MINIMUM_POSITION_MARGIN
            )
        );
        assert(success);
    }

    function setLiquidationParametersWBTC() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setLiquidationParameters.selector,
                2,
                WBTC_INITIAL_MARGIN_FRACTION,
                WBTC_MINIMUM_INITIAL_MARGIN_RATIO,
                WBTC_MAINTENANCE_MARGIN_SCALAR,
                WBTC_LIQUIDATION_REWARD_RATIO,
                WBTC_MINIMUM_POSITION_MARGIN
            )
        );
        assert(success);
    }
    function setLiquidationParametersHUGE() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl.setLiquidationParameters.selector,
                3,
                HUGE_INITIAL_MARGIN_FRACTION,
                HUGE_MINIMUM_INITIAL_MARGIN_RATIO,
                HUGE_MAINTENANCE_MARGIN_SCALAR,
                HUGE_LIQUIDATION_REWARD_RATIO,
                HUGE_MINIMUM_POSITION_MARGIN
            )
        );
        assert(success);
    }

    function setMaxLiquidationParametersWETH() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl
                    .setMaxLiquidationParameters
                    .selector,
                1,
                WETH_MAX_LIQUIDATION_LIMIT_ACCUMULATION_MULTIPLIER,
                WETH_MAX_SECONDS_IN_LIQUIDATION_WINDOW,
                WETH_MAX_LIQUIDATION_PD,
                WETH_ENDORSED_LIQUIDATOR
            )
        );
        assert(success);
    }

    function setMaxLiquidationParametersWBTC() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl
                    .setMaxLiquidationParameters
                    .selector,
                2,
                WBTC_MAX_LIQUIDATION_LIMIT_ACCUMULATION_MULTIPLIER,
                WBTC_MAX_SECONDS_IN_LIQUIDATION_WINDOW,
                WBTC_MAX_LIQUIDATION_PD,
                WBTC_ENDORSED_LIQUIDATOR
            )
        );
        assert(success);
    }
    function setMaxLiquidationParametersHUGE() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                marketConfigurationModuleImpl
                    .setMaxLiquidationParameters
                    .selector,
                3,
                HUGE_MAX_LIQUIDATION_LIMIT_ACCUMULATION_MULTIPLIER,
                HUGE_MAX_SECONDS_IN_LIQUIDATION_WINDOW,
                HUGE_MAX_LIQUIDATION_PD,
                HUGE_ENDORSED_LIQUIDATOR
            )
        );
        assert(success);
    }
    function setPerpsMarketName() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.setPerpsMarketName.selector,
                "SuperMarket"
            )
        );
        assert(success);
    }

    function setCreateMarketWETH() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.createMarket.selector,
                1, //requestedMarketId
                "WETH/USD", //marketName
                "WETHUSD" //marketSymbol
            )
        );
        assert(success);
        collateralToMarketId[address(wethTokenMock)] = 1;
    }
    function setPerpMarketFactoryModuleImplInVault() private {
        vaultModuleMock.setPerpMarketFactoryModuleImpl(
            perpsMarketFactoryModuleImpl
        );
    }

    function setCreateMarketWBTC() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.createMarket.selector,
                2, //requestedMarketId
                "WBTC/USD", //marketName
                "WBTCUSD" //marketSymbol
            )
        );
        assert(success);
        collateralToMarketId[address(wbtcTokenMock)] = 2;
    }

    function setCreateMarketHUGE() private {
        (bool success, ) = perps.call(
            abi.encodeWithSelector(
                perpsMarketFactoryModuleImpl.createMarket.selector,
                3, //requestedMarketId
                "HUGE/USD", //marketName
                "HUGEUSD" //marketSymbol
            )
        );
        assert(success);
        collateralToMarketId[address(wbtcTokenMock)] = 2;
    }

    function _getRandomCollateralToken(
        uint256 collateralTokenIndex
    ) internal returns (address) {
        (bool success, bytes memory data) = perps.call(
            abi.encodeWithSelector(
                globalPerpsMarketModuleImpl.getSupportedCollaterals.selector
            )
        );
        assert(success);
        uint256[] memory supportedCollaterals = abi.decode(data, (uint256[]));
        // assert(supportedCollaterals.length == 3);

        uint256 clampedIndex = collateralTokenIndex %
            supportedCollaterals.length;
        address collateral;
        if (clampedIndex == 0) collateral = address(sUSDTokenMock);
        else if (clampedIndex == 1) collateral = address(wethTokenMock);
        else collateral = address(wbtcTokenMock);
        return collateral;
        // TODO: Cleanup.
        // return supportedCollaterals[clampedIndex]; //== 1 ? address(wethTokenMock) : address(wbtcTokenMock);
    }

    function _getRandomNodeId(
        uint256 nodeIndex
    ) internal returns (bytes32 nodeId) {
        // first oracle nodeId is sUSD, ignore because its price shouldn't change
        nodeIndex = (nodeIndex % mockOracleManager.getActiveNodesLength()) + 1;
        nodeId = mockOracleManager.activeNodes(nodeIndex);
    }

    function _depositInitialAmounts(
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
}
