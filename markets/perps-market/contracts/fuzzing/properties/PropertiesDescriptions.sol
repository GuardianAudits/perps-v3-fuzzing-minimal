pragma solidity ^0.8.0;

contract PropertiesDescriptions {
    string constant MGN_01 =
        "MGN-01: Position is never liquidatable after a successful margin withdraw";
    // no flagged in perps
    // string constant MGN_02 =
    //     "MGN-02: A modify collateral call will always revert for an account with a flagged position";
    string constant MGN_03 =
        "MGN-03: A modify collateral call will always revert for an account that has a pending order";
    string constant MGN_04 =
        "MGN-04: If an account's collateral is 0, then the account's debt must also be 0";
    string constant MGN_05 =
        "MGN-05: depositedCollaterals array should be adjusted by amount of collateral modified";
    string constant MGN_06 =
        "MGN-06: If sUSD collateral modified, minimumCredit should be updated by that amount";
    string constant MGN_07 =
        "MGN-07: There should be no reportedDebt if all collateral has been withdrawn and skew=0";
    string constant MGN_08 =
        "MGN-08: Sum of collateral token values should be the totalCollateralValueUsd stored in the market";
    //no withaw all function
    // string constant MGN_09 =
    //     "MGN-09: After call to withdrawAllCollateral actor account margin debt should be 0";
    // string constant MGN_10 =
    //     "MGN-10: All accountMargin.collaterals should be 0 after call to withdrawAllCollateral()";
    // string constant MGN_11 =
    //     "MGN-11: Market collateral should decrease by amount of collateral user had deposited before withdrawing all collateral";
    string constant MGN_12 =
        "MGN-12: User cannot withdraw more non-susd collateral than they deposited";
    string constant MGN_13 =
        "MGN-13: activeCollateralTypesIt should never happen that a user has an amount of collateral deposited with a token > 18 decimals precision and withdrawing lead to precision loss.";
    string constant MGN_14 =
        "MGN-14:  After modifying collateral, a trader should not be immediately liquidatable.";
    string constant MGN_15 =
        "MGN-15:  After paying debt, a trader should not be immediately liquidatable.";
    string constant MGN_16 =
        "MGN-16:  The sum of collateral amounts from all accounts should always equal the global collateral amount.";

    string constant LIQ_01 = "LIQ-01: isPositionLiquidatable never reverts";
    string constant LIQ_02 =
        "LIQ-02: If a position is flagged for liquidation before any function call, the position after is always either flagged for liquidation, or no longer exists";
    string constant LIQ_03 =
        "LIQ-03: remainingLiquidatableSizeCapacity is strictly decreasing immediately after a successful liquidation";
    string constant LIQ_04 =
        "LIQ-04: If a user gets successfully flagged, their collateral will always be 0";
    string constant LIQ_05 =
        "LIQ-05: The sUSD balance of a user that successfully flags a position is strictly increasing";
    string constant LIQ_06 =
        "LIQ-06: The sUSD balance of a user that successfully flags a position increases less or equal to maxKeeperFee";
    string constant LIQ_07 =
        "LIQ-07:  User should not be able to gain more in keeper fees than collateral lost in liquidatePosition";
    string constant LIQ_08 =
        "LIQ-08: A user can be liquidated if minimum credit is not met";
    string constant LIQ_09 =
        "LIQ-09: All account margin collateral should be removed after full liquidation";
    string constant LIQ_10 =
        "LIQ-10: Flagged positions should be liquidated even if they have a health factor > 1";
    string constant LIQ_11 =
        "LIQ-11: Market deposited collateral should decrease after full liquidation by the account collaterla that was liquidated";
    string constant LIQ_12 =
        "LIQ-12: If a position has position.size == 0, flagger should be set to address(0)";
    string constant LIQ_13 =
        "LIQ-13: After user position flagged, user should have 0 collateral value";
    string constant LIQ_14 =
        "LIQ-14: After user is flagged, market collateral should decreases by user collateral amount";
    string constant LIQ_15 =
        "LIQ-15: User should not be able to gain more in keeper fees than collateral lost in liquidateMarginOnly";
    string constant LIQ_16 =
        "LIQ-16: After liquidation, debtCorrectionAccumulator and reportedDebt is strictly decreasing in one of the markets";
    string constant LIQ_17 =
        "LIQ-17: If an account is flagged for liquidations the account is not allowed to have collateral or debt.";

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
        "ORD-11: market.reportedDebt != positions.sum(p.collateralUsd + p.pricePnL + p.pendingFunding - p.pendingUtilization - p.debtUsd)";
    string constant ORD_12 =
        "ORD-12: An account should not be liquidatable by margin only after order settlement";
    string constant ORD_13 =
        "ORD-13: An account should not be liquidatable by margin only after order cancelled";
    string constant ORD_14 =
        "ORD-14: Market size should always be the sum of individual position sizes";
    string constant ORD_15 =
        "ORD-15: Position should no be liquidatable after committing an order";
    string constant ORD_16 =
        "ORD-16: Position should no be liquidatable after cancelling an order";
    string constant ORD_17 =
        "ORD-17: Position should no be liquidatable after cancelling a stale order";
    string constant ORD_18 =
        "ORD-18:  Open positions should always be added / removed from the openPositionMarketIds array.";
    string constant ORD_19 =
        "ORD-19:  All tokens in the activeCollateralTypes array from individual accounts should be included in the global activeCollateralTypes array.";
    string constant ORD_20 =
        "ORD-20:  Sum of the debt of all accounts == global debt..";
    string constant ORD_21 =
        "ORD-21: ReportedDebt == traders' collateral + traders' PnL.";
}
