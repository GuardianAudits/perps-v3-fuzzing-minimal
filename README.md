# Synthetix Readme Draft


# Quick Start with Echidna Installed 

```
forge install perimetersec/fuzzlib@main --no-commit &&
forge install foundry-rs/forge-std --no-commit &&
mv lib markets/perps-market/lib &&
cd markets/perps-market &&
PATH=./contracts/fuzzing/:$PATH echidna contracts/fuzzing/Fuzz.sol --contract Fuzz --config echidna.yaml
```

# Overview

Synthetix engaged Guardian Audits for an in-depth security review of their PerpsV3 market. This comprehensive evaluation, conducted from July 3rd to July 29th, 2024, included the development of a specialized fuzzing suite to uncover complex logical errors in various protocol states. This suite, an integral part of the audit, was created during the review period and successfully delivered upon the audit's conclusion.

# Contents

This fuzzing suite was created for the scope below, and updated for remediations at [TODO: ADD LINK]. The fuzzing suite primarily targets the core functionality found in `LiquidationModule.sol`, `OrderModule.sol` and `PerpsAccountModule.sol`.

Due to the unstable nature of fork testing, and the need to adjust prices to meet liquidation conditions, mock versions of SynthetixV3, Pyth, and OracleManager were created to resolve these issues.

A mock module was created for the functionality of creating accounts and granting permissions to accounts.

A mock lens contract was created to access the states of the Perps market which was necessary for many invariants.

This suite implements sUSD, WETH, WBTC and a 30-decimal token (for deposit and withdrawal assertions) as collateral. 

[Logical coverage]((markets/perps-market/contracts/fuzzing/helper/logicalCoverage)) for the main modules allow the fuzzer to view amounts, pnls, and statuses of trades with additional details beyond line coverage. 

All properties tested can be found below in this readme.

## Setup

1. Installing Echidna 

   Install Echidna, follow the steps here: [Installation Guide](https://github.com/crytic/echidna#installation) using the latest master branch

2. Install libs

```
forge install perimetersec/fuzzlib@main --no-commit &&
forge install foundry-rs/forge-std --no-commit &&
mv lib markets/perps-market/lib

```
3. Go to perps dir
`cd markets/perps-market`

## Usage 

5. Run Echidna with no Slither check (faster debugging)

`PATH=./contracts/fuzzing/:$PATH echidna contracts/fuzzing/Fuzz.sol --contract Fuzz --config echidna.yaml`

6. Run Echidna with a Slither check (slow)

`echidna contracts/fuzzing/Fuzz.sol --contract Fuzz --config echidna.yaml`


7. Run Foundry
`forge test --mt test_modifyCollateral`

# Scope

Repo: https://github.com/Synthetixio/synthetix-v3

Branch: `main`

Commit: `fd4c562868761bdcafb1a3dc080c3465e4e4de76`

```.
├── README.md
├── cache
│   ├── solidity-files-cache.json
│   └── test-failures
├── cache_forge
│   └── solidity-files-cache.json
├── contracts
│   ├── Mocks.sol
│   ├── Proxy.sol
│   ├── fuzzing
│   │   ├── FoundryPlayground.sol
│   │   ├── Fuzz.sol
│   │   ├── FuzzAdmin.sol
│   │   ├── FuzzGuidedModule.sol
│   │   ├── FuzzLiquidationModule.sol
│   │   ├── FuzzModules.sol
│   │   ├── FuzzOrderModule.sol
│   │   ├── FuzzPerpsAccountModule.sol
│   │   ├── FuzzSetup.sol
│   │   ├── helper
│   │   │   ├── BeforeAfter.sol
│   │   │   ├── BeforeAfterOLD.sol
│   │   │   ├── FuzzStorageVariables.sol
│   │   │   ├── logicalCoverage
│   │   │   ├── postconditions
│   │   │   └── preconditions
│   │   ├── mocks
│   │   │   ├── MockERC20.sol
│   │   │   ├── MockLensModule.sol
│   │   │   ├── MockModule.sol
│   │   │   ├── MockOracleManager.sol
│   │   │   ├── MockPyth.sol
│   │   │   ├── MockRewardDistributor.sol
│   │   │   ├── MockRouter.sol
│   │   │   ├── MockSpotMarket.sol
│   │   │   ├── MockSynthetixV3.sol
│   │   │   └── MockVaultModule.sol
│   │   ├── properties
│   │   │   ├── Properties.sol
│   │   │   ├── PropertiesBase.sol
│   │   │   ├── PropertiesDescriptions.sol
│   │   │   ├── Properties_LIQ.sol
│   │   │   ├── Properties_MGN.sol
│   │   │   └── Properties_ORD.sol
│   │   ├── slither
│   │   └── util
│   │       ├── CheckCaller.sol
│   │       ├── FunctionCalls.sol
│   │       └── FuzzConstants.sol
│   ├── interfaces
│   │   ├── IAccountEvents.sol
│   │   ├── IAsyncOrderCancelModule.sol
│   │   ├── IAsyncOrderModule.sol
│   │   ├── IAsyncOrderSettlementPythModule.sol
│   │   ├── ICollateralConfigurationModule.sol
│   │   ├── IDistributorErrors.sol
│   │   ├── IGlobalPerpsMarketModule.sol
│   │   ├── ILiquidationModule.sol
│   │   ├── IMarketConfigurationModule.sol
│   │   ├── IMarketEvents.sol
│   │   ├── IPerpsAccountModule.sol
│   │   ├── IPerpsMarketFactoryModule.sol
│   │   ├── IPerpsMarketModule.sol
│   │   └── external
│   │       ├── IFeeCollector.sol
│   │       ├── IPythERC7412Wrapper.sol
│   │       ├── ISpotMarketSystem.sol
│   │       └── ISynthetixSystem.sol
│   ├── mocks
│   │   ├── FeeCollectorMock.sol
│   │   ├── MockGasPriceNode.sol
│   │   ├── MockPyth.sol
│   │   ├── MockPythERC7412Wrapper.sol
│   │   └── MockRewardsDistributorExternal.sol
│   ├── modules
│   │   ├── AssociatedSystemsModule.sol
│   │   ├── AsyncOrderCancelModule.sol
│   │   ├── AsyncOrderModule.sol
│   │   ├── AsyncOrderSettlementPythModule.sol
│   │   ├── CollateralConfigurationModule.sol
│   │   ├── CoreModule.sol
│   │   ├── FeatureFlagModule.sol
│   │   ├── GlobalPerpsMarketModule.sol
│   │   ├── LiquidationModule.sol
│   │   ├── MarketConfigurationModule.sol
│   │   ├── PerpsAccountModule.sol
│   │   ├── PerpsMarketFactoryModule.sol
│   │   └── PerpsMarketModule.sol
│   ├── storage
│   │   ├── AsyncOrder.sol
│   │   ├── GlobalPerpsMarket.sol
│   │   ├── GlobalPerpsMarketConfiguration.sol
│   │   ├── InterestRate.sol
│   │   ├── KeeperCosts.sol
│   │   ├── Liquidation.sol
│   │   ├── LiquidationAssetManager.sol
│   │   ├── MarketUpdate.sol
│   │   ├── OrderFee.sol
│   │   ├── PerpsAccount.sol
│   │   ├── PerpsCollateralConfiguration.sol
│   │   ├── PerpsMarket.sol
│   │   ├── PerpsMarketConfiguration.sol
│   │   ├── PerpsMarketFactory.sol
│   │   ├── PerpsPrice.sol
│   │   ├── Position.sol
│   │   └── SettlementStrategy.sol
│   └── utils
│       ├── BigNumber.sol
│       ├── Flags.sol
│       └── MathUtil.sol
├── echidna.yaml
├── echidnaProfiler
│   └── Echidna Profile.prof
├── foundry.toml
├── node_modules
│   ├── @openzeppelin
│   └── @synthetixio
├── remappings.txt
└── storage.dump.sol```



```
| Invariant ID | Invariant Description | Passed | Run Count | Remediations |
| --- | --- | --- | --- | --- |
| ORD-01 | If an account has an unexpired committed order, a subsequent commit order call will always revert | ✅ | 2m | - |
| ORD-02 | The sizeDelta of an order is always 0 after a successful settle order call | ✅ | 2m | - |
| ORD-03 | An order immediately after a successful settle order call is never liquidatable | ❌ | 2m | - |
| ORD-04 | If a user successfully settles an order, their sUSD balance is strictly increasing | ✅  | 2m | - |
| ORD-05 | The sUSD balance of a user that successfully cancels an order for another user is strictly increasing | ✅ | 2m | - |
| ORD-06 | The minimum credit requirement must be met after increase order settlement | ❌ | 2m | - |
| ORD-07 | Utilization is between 0% and 100% before and after order settlement | ❌ | 2m | - |
| ORD-08 | Non-SUSD collateral should stay the same after profitably settling order | ✅ | 2m | - |
| ORD-09 | Should always give premium when increasing skew and discount when decreasing skew | ✅ | 2m | - |
| ORD-10 | Market utilization rate is always between 0 and 100% | ✅ | 2m | - |
| ORD-11 | An account should not be liquidatable by margin only after order settlement | ✅ | 2m | - |
| ORD-12 | An account should not be liquidatable by margin only after order cancelled | ✅ | 2m | - |
| ORD-13 | Market size should always be the sum of individual position sizes | ✅ | 2m | - |
| ORD-14 | Position should not be liquidatable after committing an order | ✅ | 2m | - |
| ORD-15 | Position should not be liquidatable after cancelling an order | ❌ | 2m | - |
| ORD-16 | Open positions should always be added / removed from the openPositionMarketIds array | ✅ | 2m | - |
| ORD-17 | All tokens in the activeCollateralTypes array from individual accounts should be included in the global activeCollateralTypes array | ✅ | 2m | - |
| ORD-18 | Sum of the debt of all accounts == global debt | ❌ | 2m | - |
| ORD-19 | Debt should not vanish after settle another order | ❌ | 2m | - |
| ORD-20 | AsyncOrder.calculateFillPrice() should never revert. | ✅ | 2m | - |
| LIQ-01 | isPositionLiquidatable never reverts | ✅ | 2m | - |
| LIQ-02 | remainingLiquidatableSizeCapacity is strictly decreasing immediately after a successful liquidation | ✅ | 2m | - |
| LIQ-03 | A user can be liquidated if minimum credit is not met | ❌ | 2m | - |
| LIQ-04 | All account margin collateral should be removed after full liquidation | ✅ | 2m | - |
| LIQ-05 | Market deposited collateral should decrease after full liquidation by the account collateral that was liquidated | ✅ | 2m | - |
| LIQ-06 | User should not be able to gain more in keeper fees than collateral lost in liquidateMarginOnly | ✅ | 2m | - |
| LIQ-07 | If an account is flagged for liquidations the account is not allowed to have collateral or debt. | ✅ | 2m | - |
| LIQ-08 | MaxLiquidatableAmount can never return a value greater than requestedLiquidationAmount | ✅ | 2m | - |
| LIQ-09 | Calling LiquidationModule.liquidate after it has been previously called in the same block should not increase the balance of the caller | ✅ | 2m | - |
| MGN-01 | Position is never liquidatable after a successful margin withdraw | ✅ | 2m | - |
| MGN-02 | A modify collateral call will always revert for an account that has a pending order | ✅ | 2m | - |
| MGN-03 | If an account's collateral is 0, then the account's debt must also be 0 | ✅ | 2m | - |
| MGN-04 | depositedCollaterals array should be adjusted by amount of collateral modified (for WBTC) | ✅ | 2m | - |
| MGN-05 | If sUSD collateral modified, minimumCredit should be updated by that amount | ✅ | 2m | - |
| MGN-06 | Sum of collateral token values should be the totalCollateralValueUsd stored in the market | ✅ | 2m | - |
| MGN-07 | User cannot withdraw more non-susd collateral than they deposited | ✅ | 2m | - |
| MGN-08 | It should never happen that a user has an amount of collateral deposited with a token > 18 decimals precision and withdrawing lead to precision loss | ✅ | 2m | - |
| MGN-09 | After modifying collateral, a trader should not be immediately liquidatable. | ✅ | 2m | - |
| MGN-10 | After paying debt, a trader should not be immediately liquidatable. | ✅ | 2m | - |
| MGN-11 | The sum of collateral amounts from all accounts should always equal the global collateral amount. | ✅ | 2m | - |
