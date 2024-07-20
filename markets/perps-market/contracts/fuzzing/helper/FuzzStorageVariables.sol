// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../util/FuzzConstants.sol";

import {MockRouter} from "../mocks/MockRouter.sol";
import {MockSynthetixV3} from "../mocks/MockSynthetixV3.sol";
import {Proxy} from "../../Proxy.sol";
import {MockOracleManager} from "../mocks/MockOracleManager.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockOracleManager} from "../mocks/MockOracleManager.sol";
import {CoreModule} from "../../modules/CoreModule.sol";
import {AsyncOrderCancelModule} from "../../modules/AsyncOrderCancelModule.sol";
import {AsyncOrderModule} from "../../modules/AsyncOrderModule.sol";
import {AsyncOrderSettlementPythModule} from "../../modules/AsyncOrderSettlementPythModule.sol";
import {CollateralConfigurationModule} from "../../modules/CollateralConfigurationModule.sol";
import {FeatureFlagModule} from "../../modules/FeatureFlagModule.sol";
import {GlobalPerpsMarketModule} from "../../modules/GlobalPerpsMarketModule.sol";
import {LiquidationModule} from "../../modules/LiquidationModule.sol";
import {MarketConfigurationModule} from "../../modules/MarketConfigurationModule.sol";
import {PerpsAccountModule} from "../../modules/PerpsAccountModule.sol";
import {PerpsMarketFactoryModule} from "../../modules/PerpsMarketFactoryModule.sol";
import {PerpsMarketModule} from "../../modules/PerpsMarketModule.sol";

import {MockModule} from "../mocks/MockModule.sol";
import {MockPyth} from "../mocks/MockPyth.sol";
import {MockPythERC7412Wrapper} from "../../mocks/MockPythERC7412Wrapper.sol";
import {MockRewardDistributor} from "../mocks/MockRewardDistributor.sol";
import {MockSpotMarket} from "../mocks/MockSpotMarket.sol";
import {MockVaultModule} from "../mocks/MockVaultModule.sol";

import {MockGasPriceNode} from "../../mocks/MockGasPriceNode.sol";

import "lib/forge-std/src/Test.sol";

contract FuzzStorageVariables is FuzzConstants, Test {
    // Echidna settings
    address internal currentActor;
    bool internal _setActor = true;

    // user => accountId
    mapping(address => uint128[]) userToAccountIds;
    mapping(uint128 => address) accountIdToUser;
    // pythNodeId => chainlinkNodeId, chainlinkNodeId => pythNodeId
    mapping(bytes32 node1 => bytes32 node2) oracleNodes;
    // collateralToken => chainlink nodeId
    mapping(address collateralToken => bytes32 nodeId) tokenChainlinkNode;

    MockERC20[] internal tokens;

    // All of the deployed contracts
    address internal perps;
    MockRouter internal router;
    MockSpotMarket internal spot;
    MockSynthetixV3 internal v3Mock;

    CoreModule internal coreModuleImpl;

    AsyncOrderCancelModule internal asyncOrderCancelModuleImpl;
    AsyncOrderModule internal asyncOrderModuleImpl;
    AsyncOrderSettlementPythModule internal asyncOrderSettlementPythModuleImpl;
    CollateralConfigurationModule internal collateralConfigurationModuleImpl;
    FeatureFlagModule internal featureFlagModuleImpl;
    GlobalPerpsMarketModule internal globalPerpsMarketModuleImpl;
    LiquidationModule internal liquidationModuleImpl;
    MarketConfigurationModule internal marketConfigurationModuleImpl;
    PerpsAccountModule internal perpsAccountModuleImpl;
    PerpsMarketFactoryModule internal perpsMarketFactoryModuleImpl;
    PerpsMarketModule internal perpsMarketModuleImpl;
    // PoolModule internal poolModuleImpl;

    MockModule internal mockModuleImpl;
    MockOracleManager internal mockOracleManager;
    MockERC20 internal sUSDTokenMock;
    MockERC20 internal wethTokenMock;
    MockERC20 internal wbtcTokenMock;
    MockPyth internal mockPyth;
    MockPythERC7412Wrapper internal pythWrapperWETH;
    MockPythERC7412Wrapper internal pythWrapperWBTC;
    MockRewardDistributor internal rewardWETHDistributorMock;
    MockRewardDistributor internal rewardWBTCDistributorMock;
    MockGasPriceNode internal mockGasPriceNode;
    MockVaultModule internal vaultModuleMock;

    bool modifyCalled;
    bool commitCalled;
    address commitCaller;
    uint128 latestAvailableId = 4;
}
