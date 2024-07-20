// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import {SettlementStrategy} from "../../storage/SettlementStrategy.sol";

abstract contract FuzzConstants {
    bool internal constant DEBUG = false;

    address internal constant USER1 = address(0x10000);
    address internal constant USER2 = address(0x20000);
    address internal constant USER3 = address(0x30000);
    address[] internal USERS = [USER1, USER2, USER3];
    uint128[] internal ACCOUNTS = [1, 2, 3];

    uint256 internal constant INITIAL_BALANCE = 500_000 ether; // 1 Billion USD worth of ETH at $2000/ETH
    uint256 internal constant INITIAL_TOKEN_BALANCE = 5_000_000_000; // 5 Billion tokens, to be multiplied by decimals in setup

    int256 internal constant INT_MAX_ETH_CHANGE_BP = 2000; // 20% is the max change for 1 transaction
    uint256 internal constant UINT_MAX_ETH_CHANGE_BP = 2000; // 20% is the max change for 1 transaction

    bytes32 internal constant SUSD_ORACLE_NODE_ID = "1";
    bytes32 internal constant WETH_ORACLE_NODE_ID = "2";
    bytes32 internal constant WBTC_ORACLE_NODE_ID = "3";

    bytes32 internal constant KEEPER_NODE_ID = "4";

    bytes32 internal constant WETH_PYTH_PRICE_FEED_ID = "2";
    bytes32 internal constant WBTC_PYTH_PRICE_FEED_ID = "3";

    int64 internal constant WETH_STARTING_PRICE = 3_000 * 1e8;
    uint64 internal constant WETH_STARTING_CONF = 1;
    int32 internal constant WETH_STARTING_EXPO = -8;

    int64 internal constant WBTC_STARTING_PRICE = 3_000 * 1e8;
    uint64 internal constant WBTC_STARTING_CONF = 1;
    int32 internal constant WBTC_STARTING_EXPO = -8;

    uint128 internal constant REWARD_DISTRIBUTOR_WETH_POOL_ID = 1;
    uint128 internal constant REWARD_DISTRIBUTOR_WBTC_POOL_ID = 2;

    bytes32 internal constant KEEPER_SETTLEMENT_COST = 0;
    bytes32 internal constant KEEPER_FLAG_COST = 0;
    bytes32 internal constant KEEPER_LIQUIDATE_COST = 0;

    uint internal constant STRICT_PRICE_TOLERANCE = 60;

    uint internal constant POOL_ID_1 = 1;
    uint internal constant POOL_ID_2 = 2;

    //markets/perps-market/test/integration/Account/Margins.test.ts
    //synthetix/perps-v3-fuzzing-fresh/markets/spot-market/test/AtomicOrderModule.buy.test.ts
    uint128 internal constant WETH_MARKET_SKEW_SCALE = 100e18;
    uint128 internal constant WBTC_MARKET_SKEW_SCALE = 10000e18;

    // Settlement strategy WETH
    SettlementStrategy.Type internal constant WETH_SETTLEMENT_STRATEGY_TYPE =
        SettlementStrategy.Type.PYTH;
    uint256 internal constant WETH_SETTLEMENT_DELAY = 5;
    uint256 internal constant WETH_SETTLEMENT_WINDOW_DURATION = 120;
    bytes32 internal constant WETH_FEED_ID = "2";
    uint256 internal constant WETH_SETTLEMENT_REWARD = 5e18;
    bool internal constant WETH_DISABLED = false;
    uint256 internal constant WETH_COMMITMENT_PRICE_DELAY = 2;

    // Settlement strategy WBTC
    SettlementStrategy.Type internal constant WBTC_SETTLEMENT_STRATEGY_TYPE =
        SettlementStrategy.Type.PYTH;
    uint256 internal constant WBTC_SETTLEMENT_DELAY = 5;
    uint256 internal constant WBTC_SETTLEMENT_WINDOW_DURATION = 120;
    bytes32 internal constant WBTC_FEED_ID = "3";
    uint256 internal constant WBTC_SETTLEMENT_REWARD = 5e18;
    bool internal constant WBTC_DISABLED = false;
    uint256 internal constant WBTC_COMMITMENT_PRICE_DELAY = 2;

    // SNX USD Collateral Configuration
    uint256 internal constant SNX_USD_COLLATERAL_ID = 0;
    uint256 internal constant SNX_USD_MAX_COLLATERAL_AMOUNT = type(uint256).max;
    uint256 internal constant SNX_USD_UPPER_LIMIT_DISCOUNT = 0;
    uint256 internal constant SNX_USD_LOWER_LIMIT_DISCOUNT = 0;
    uint256 internal constant SNX_USD_DISCOUNT_SCALAR = 0;

    // WETH Collateral Configuration
    uint256 internal constant WETH_COLLATERAL_ID = 1;
    uint256 internal constant WETH_MAX_COLLATERAL_AMOUNT = type(uint256).max;
    uint256 internal constant WETH_UPPER_LIMIT_DISCOUNT = 0;
    uint256 internal constant WETH_LOWER_LIMIT_DISCOUNT = 0;
    uint256 internal constant WETH_DISCOUNT_SCALAR = 0;

    // WBTC Collateral Configuration
    uint256 internal constant WBTC_COLLATERAL_ID = 2;
    uint256 internal constant WBTC_MAX_COLLATERAL_AMOUNT = type(uint256).max;
    uint256 internal constant WBTC_UPPER_LIMIT_DISCOUNT = 0;
    uint256 internal constant WBTC_LOWER_LIMIT_DISCOUNT = 0;
    uint256 internal constant WBTC_DISCOUNT_SCALAR = 0;

    // Max Positions and Collaterals Per Account Configuration
    uint128 internal constant MAX_POSITIONS_PER_ACCOUNT = 100000;
    uint128 internal constant MAX_COLLATERALS_PER_ACCOUNT = 100000;

    // WETH Funding Parameters
    uint128 internal constant WETH_SKEW_SCALE = 1_000_000e18;
    uint256 internal constant WETH_MAX_FUNDING_VELOCITY = 0;

    // WBTC Funding Parameters
    uint128 internal constant WBTC_SKEW_SCALE = 1_000_000e18;
    uint256 internal constant WBTC_MAX_FUNDING_VELOCITY = 0;

    // Max Market Sizes
    uint128 internal constant WETH_MAX_MARKET_SIZE = 27_000 * 1e18; //10_000_000;
    uint128 internal constant WBTC_MAX_MARKET_SIZE = 27_000 * 1e18; //10_000_000;

    // Max Market Values
    uint256 internal constant WETH_MAX_MARKET_VALUE = 0;
    uint256 internal constant WBTC_MAX_MARKET_VALUE = 0;

    // Order Fee Ratios
    uint256 internal constant WETH_MAKER_FEE_RATIO = 0.003e18;
    uint256 internal constant WETH_TAKER_FEE_RATIO = 0.006e18;
    uint256 internal constant WBTC_MAKER_FEE_RATIO = 0.003e18;
    uint256 internal constant WBTC_TAKER_FEE_RATIO = 0.006e18;

    // WETH Liquidation Parameters
    uint256 internal constant WETH_INITIAL_MARGIN_FRACTION = 2e18;
    uint256 internal constant WETH_MINIMUM_INITIAL_MARGIN_RATIO = 0.01e18;
    uint256 internal constant WETH_MAINTENANCE_MARGIN_SCALAR = 0.5e18;
    uint256 internal constant WETH_LIQUIDATION_REWARD_RATIO = 0.05e18;
    uint256 internal constant WETH_MINIMUM_POSITION_MARGIN = 1000e18;

    // WBTC Liquidation Parameters
    uint256 internal constant WBTC_INITIAL_MARGIN_FRACTION = 2e18;
    uint256 internal constant WBTC_MINIMUM_INITIAL_MARGIN_RATIO = 0.01e18;
    uint256 internal constant WBTC_MAINTENANCE_MARGIN_SCALAR = 0.5e18;
    uint256 internal constant WBTC_LIQUIDATION_REWARD_RATIO = 0.05e18;
    uint256 internal constant WBTC_MINIMUM_POSITION_MARGIN = 1000e18;

    // WETH Max Liquidation Parameters
    uint256 internal constant WETH_MAX_LIQUIDATION_LIMIT_ACCUMULATION_MULTIPLIER = 0.00001e18;
    uint256 internal constant WETH_MAX_SECONDS_IN_LIQUIDATION_WINDOW = 60;
    uint256 internal constant WETH_MAX_LIQUIDATION_PD = 0;
    address internal constant WETH_ENDORSED_LIQUIDATOR = address(0);

    // WBTC Max Liquidation Parameters
    uint256 internal constant WBTC_MAX_LIQUIDATION_LIMIT_ACCUMULATION_MULTIPLIER = 0.00001e18;
    uint256 internal constant WBTC_MAX_SECONDS_IN_LIQUIDATION_WINDOW = 60;
    uint256 internal constant WBTC_MAX_LIQUIDATION_PD = 0;
    address internal constant WBTC_ENDORSED_LIQUIDATOR = address(0);

    //Pyth settings

    int256 internal constant INT_MAX_SYNTHETIX_USD_CHANGE_BP = 2000; // 20% is the max change for 1 transaction
    int256 internal constant INT_ONE_HUNDRED_BP = 10000;
    int64 internal constant INT_ONE_HUNDRED_BP_64 = 10000;

    uint256 internal constant UINT_MAX_SYNTHETIX_USD_CHANGE_BP = 2000; // 20% is the max change for 1 transaction
    uint256 internal constant UINT_ONE_HUNDRED_BP = 10000;

    int256 internal constant INT_MAX_CHANGE_BP = 2000; // 20% is the max change for 1 transaction
    uint256 internal constant UINT_MAX_CHANGE_BP = 2000; //  2000; // 20% is the max change for 1 transaction

    uint128 internal constant MAX_ALLOWABLE = 10_000_000 * 1e18;
    int256 internal constant PRICE_DIVERGENCE_BPS_256 = 100;
    int64 internal constant PRICE_DIVERGENCE_BPS_64 = 100;
}
