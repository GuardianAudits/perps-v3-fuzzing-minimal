pragma solidity ^0.8.0;

contract PropertiesDescriptions {
    string constant MGN_01 =
        "MGN-01: Position is never liquidatable after a successful margin withdraw";
    string constant MGN_02 =
        "MGN-02: A modify collateral call will always revert for an account that has a pending order";
    string constant MGN_03 =
        "MGN-03: If an account's collateral is 0, then the account's debt must also be 0";
    string constant MGN_04 =
        "MGN-04: depositedCollaterals array should be adjusted by amount of collateral modified";
    string constant MGN_05 =
        "MGN-05: If sUSD collateral modified, minimumCredit should be updated by that amount";
    string constant MGN_06 =
        "MGN-06: Sum of collateral token values should be the totalCollateralValueUsd stored in the market";
    string constant MGN_07 =
        "MGN-07: User cannot withdraw more non-susd collateral than they deposited";
    string constant MGN_08 =
        "MGN-08: It should never happen that a user has an amount of collateral deposited with a token > 18 decimals precision and withdrawing lead to precision loss.";
    string constant MGN_09 =
        "MGN-09:  After modifying collateral, a trader should not be immediately liquidatable.";
    string constant MGN_10 =
        "MGN-10:  After paying debt, a trader should not be immediately liquidatable.";
    string constant MGN_11 =
        "MGN-11:  The sum of collateral amounts from all accounts should always equal the global collateral amount.";

    string constant LIQ_01 = "LIQ-01: isPositionLiquidatable never reverts";
    string constant LIQ_02 =
        "LIQ-02: remainingLiquidatableSizeCapacity is strictly decreasing immediately after a successful liquidation";
    string constant LIQ_03 =
        "LIQ-03: A user can be liquidated if minimum credit is not met";
    string constant LIQ_04 =
        "LIQ-04: All account margin collateral should be removed after full liquidation";
    string constant LIQ_05 =
        "LIQ-05: Market deposited collateral should decrease after full liquidation by the account collaterla that was liquidated";
    string constant LIQ_06 =
        "LIQ-06: User should not be able to gain more in keeper fees than collateral lost in liquidateMarginOnly";
    string constant LIQ_07 =
        "LIQ-07: If an account is flagged for liquidations the account is not allowed to have collateral or debt.";
    string constant LIQ_08 =
        "LIQ-08: maxLiquidatableAmount can never return a value greater than requestedLiquidationAmount.";
    string constant LIQ_09 =
        "LIQ-09: Calling LiquidationModule.liquidate after it has been previously called in the same block should not increase the balance of the caller.";

    string constant ORD_01 =
        "ORD-01: If an account has an order commited that is unexpired, a subsequent commit order call will always revert";
    string constant ORD_02 =
        "ORD-02: The sizeDelta of an order is always 0 after a successful settle order call";
    string constant ORD_03 =
        "ORD-03: An order immediately after a successful settle order call, is never liquidatable";
    string constant ORD_04 =
        "ORD-04: If a user successfully settles an order, their sUSD balance is strictly increasing";
    string constant ORD_05 =
        "ORD-05: The sUSD balance of a user that successfully cancels an order for another user is strictly increasing";
    string constant ORD_06_WETH =
        "ORD-06_WETH: The minimum credit requirement must be met after increase order settlement";
    string constant ORD_06_WBTC =
        "ORD-06_WBTC: The minimum credit requirement must be met after increase order settlement";
    string constant ORD_07 =
        "ORD-07: Utilization is between 0% and 100% before and after order settlement";
    string constant ORD_08_WETH =
        "ORD_08_WETH: non-SUSD collateral should stay the same after profitably settling order";
    string constant ORD_08_WBTC =
        "ORD_08_WBTC: non-SUSD collateral should stay the same after profitably settling order";
    string constant ORD_09 =
        "ORD-09: Should always give premium when increasing skew and discount when decreasing skew";
    string constant ORD_10 =
        "ORD-10: market.currentUtilizationAccruedComputed decreases";
    string constant ORD_11 =
        "ORD-11: An account should not be liquidatable by margin only after order settlement";
    string constant ORD_12 =
        "ORD-12: An account should not be liquidatable by margin only after order cancelled";
    string constant ORD_13 =
        "ORD-13: Market size should always be the sum of individual position sizes";
    string constant ORD_14 =
        "ORD-14: Position should no be liquidatable after committing an order";
    string constant ORD_15 =
        "ORD-15: Position should no be liquidatable after cancelling an order";
    string constant ORD_16 =
        "ORD-16:  Open positions should always be added / removed from the openPositionMarketIds array.";
    string constant ORD_17 =
        "ORD-17:  All tokens in the activeCollateralTypes array from individual accounts should be included in the global activeCollateralTypes array.";
    string constant ORD_18 =
        "ORD-18:  Sum of the debt of all accounts == global debt..";
    string constant ORD_19 =
        "ORD-19: Debt should not vanish after settle another order.";
    string constant ORD_20 =
        "ORD-20: AsyncOrder.calculateFillPrice() should never revert.";
}
