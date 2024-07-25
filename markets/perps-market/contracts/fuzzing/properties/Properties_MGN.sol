// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PropertiesBase.sol";

abstract contract Properties_MGN is PropertiesBase {
    function invariant_MGN_01(uint128 accountId) internal {
        fl.t(!states[1].actorStates[accountId].isPositionLiquidatable, MGN_01);
    }

    //MGN_02 FlaggedBy is N/A

    function invariant_MGN_03(uint128 accountId) internal {
        fl.t(
            states[0].actorStates[accountId].sizeDelta == 0 ||
                states[0].actorStates[accountId].isOrderExpired,
            MGN_03
        );
    }

    function invariant_MGN_04(uint128 accountId) internal {
        //here is a total collateral value of speecific account
        if (states[1].actorStates[accountId].totalCollateralValue == 0) {
            fl.eq(states[1].actorStates[accountId].debt, 0, MGN_04);
        }
    }

    function invariant_MGN_05(int256 amountDelta, address collateral) internal {
        if (amountDelta != 0 && collateral == address(wethTokenMock)) {
            fl.eq(
                int256(states[1].depositedWethCollateral),
                int256(states[0].depositedWethCollateral) + amountDelta,
                MGN_05
            );
        }
    }

    // "./perps-market/contracts/modules/PerpsMarketFactoryModule.sol::minimumCredit"
    function invariant_MGN_06(int256 amountDelta, address collateral) internal {
        if (amountDelta != 0 && collateral == address(sUSDTokenMock)) {
            fl.eq(
                int256(states[1].minimumCredit),
                int256(states[0].minimumCredit) + amountDelta,
                MGN_06
            );
        }
    }
    function invariant_MGN_13(int256 amountDelta, address collateral) internal {
        if (amountDelta != 0 && collateral == address(wbtcTokenMock)) {
            fl.eq(
                int256(states[1].depositedWbtcCollateral),
                int256(states[0].depositedWbtcCollateral) + amountDelta,
                MGN_05 //TODO: split btc and eth desc
            );
        }
    }

    //N/A for perps
    // function invariant_MGN_07() internal {
    //     // TODO: DG review
    //     //Q1
    //     //totalCollateralValueUsd is a total for all markets
    //     // skew is a value that was taken from PerpsMarket::Data::skew
    //     // so skew is different for every market
    //     //Q2 or is it skew for SuperMarket
    //     //Q3 this skew value in logs is always zero, something with config

    //     if (states[1].totalCollateralValueUsd == 0 && states[1].skew == 0)
    //         fl.eq(states[1].reportedDebt, 0, MGN_07);
    // }

    function invariant_MGN_08() internal {
        console2.log(
            "states[1].totalCollateralValueUsd",
            states[1].totalCollateralValueUsd
        );
        console2.log(
            "states[1].totalCollateralValueUsdGhost",
            states[1].totalCollateralValueUsdGhost
        );

        fl.eq(
            states[1].totalCollateralValueUsd,
            states[1].totalCollateralValueUsdGhost,
            MGN_08
        );
    }

    //MGN_09 is N/A now WithdrawAll function
    //MGN_10 is N/A now WithdrawAll function
    //MGN_11 is N/A now WithdrawAll function

    function invariant_MGN_12(uint128 accountId, uint collateralId) internal {
        // market collateral can only decrease by up to user's deposited weth amount value on withdrawal
        if (collateralId == 0) {
            fl.lte(
                states[0].depositedSusdCollateral -
                    states[1].depositedSusdCollateral,
                states[0].actorStates[accountId].collateralAmountSUSD,
                MGN_12
            );
        }
        if (collateralId == 1) {
            fl.lte(
                states[0].depositedWethCollateral -
                    states[1].depositedWethCollateral,
                states[0].actorStates[accountId].collateralAmountWETH,
                MGN_12
            );
        }
        if (collateralId == 2) {
            fl.lte(
                states[0].depositedWbtcCollateral -
                    states[1].depositedWbtcCollateral,
                states[0].actorStates[accountId].collateralAmountWBTC,
                MGN_12
            );
        }
    }

    function invariant_MGN_13(uint128 accountId, uint collateralId) internal {
        if (collateralId == 3) {
            fl.eq(
                states[1].actorStates[accountId].collateralAmountHUGE %
                    (10 ** (hugePrecisionTokenMock.decimals() - 18)),
                0,
                MGN_13
            );
        }
    }

    function invariant_MGN_14(uint128 accountId) public {
        if (!states[0].actorStates[accountId].isPositionLiquidatable) {
            fl.t(!states[1].actorStates[accountId].isPositionLiquidatable, MGN_14);
        }
    }

    function invariant_MGN_15(uint128 accountId) public {
        if (!states[0].actorStates[accountId].isPositionLiquidatable) {
            fl.t(!states[1].actorStates[accountId].isPositionLiquidatable, MGN_15);
        }
    }

    function invariant_MGN_16() public {
        fl.eq(
            states[1].depositedSusdCollateral,
            uint(states[1].collateralValueAllUsersSUSDCalculated),
            MGN_16
        );

        fl.eq(
            states[1].depositedWethCollateral,
            uint(states[1].collateralValueAllUsersWETHCalculated),
            MGN_16
        );

        fl.eq(
            states[1].depositedWbtcCollateral,
            uint(states[1].collateralValueAllUsersWBTCCalculated),
            MGN_16
        );
    }
}
