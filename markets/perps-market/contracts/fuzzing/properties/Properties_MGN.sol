// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PropertiesBase.sol";

abstract contract Properties_MGN is PropertiesBase {
    function invariant_MGN_01(uint128 accountId) internal {
        fl.t(!states[1].actorStates[accountId].isPositionLiquidatable, MGN_01);
    }

    function invariant_MGN_02(uint128 accountId) internal {
        fl.t(
            states[0].actorStates[accountId].sizeDelta == 0 ||
                states[0].actorStates[accountId].isOrderExpired,
            MGN_02
        );
    }

    function invariant_MGN_03(uint128 accountId) internal {
        //here is a total collateral value of speecific account
        if (states[1].actorStates[accountId].totalCollateralValue == 0) {
            fl.eq(states[1].actorStates[accountId].debt, 0, MGN_03);
        }
    }

    function invariant_MGN_04(int256 amountDelta, address collateral) internal {
        if (amountDelta != 0 && collateral == address(wbtcTokenMock)) {
            fl.eq(
                int256(states[1].depositedWbtcCollateral),
                int256(states[0].depositedWbtcCollateral) + amountDelta,
                MGN_04
            );
        }

        if (amountDelta != 0 && collateral == address(wethTokenMock)) {
            fl.eq(
                int256(states[1].depositedWethCollateral),
                int256(states[0].depositedWethCollateral) + amountDelta,
                MGN_04
            );
        }
    }

    // "./perps-market/contracts/modules/PerpsMarketFactoryModule.sol::minimumCredit"
    function invariant_MGN_05(int256 amountDelta, address collateral) internal {
        if (amountDelta != 0 && collateral == address(sUSDTokenMock)) {
            fl.eq(
                int256(states[1].minimumCredit),
                int256(states[0].minimumCredit) + amountDelta,
                MGN_05
            );
        }
    }

    function invariant_MGN_06() internal {
        console2.log(
            "states[1].totalCollateralValueUsd",
            states[1].totalCollateralValueUsd
        );
        console2.log(
            "states[1].totalCollateralValueUsdGhost",
            states[1].totalCollateralValueUsdGhost
        );

        eqWithTolerance(
            states[1].totalCollateralValueUsd,
            states[1].totalCollateralValueUsdGhost,
            0.01e18,
            MGN_06
        );
    }

    function invariant_MGN_07(uint128 accountId, uint collateralId) internal {
        // market collateral can only decrease by up to user's deposited weth amount value on withdrawal
        if (collateralId == 0) {
            fl.lte(
                states[0].depositedSusdCollateral -
                    states[1].depositedSusdCollateral,
                states[0].actorStates[accountId].collateralAmountSUSD,
                MGN_07
            );
        }
        if (collateralId == 1) {
            fl.lte(
                states[0].depositedWethCollateral -
                    states[1].depositedWethCollateral,
                states[0].actorStates[accountId].collateralAmountWETH,
                MGN_07
            );
        }
        if (collateralId == 2) {
            fl.lte(
                states[0].depositedWbtcCollateral -
                    states[1].depositedWbtcCollateral,
                states[0].actorStates[accountId].collateralAmountWBTC,
                MGN_07
            );
        }
    }

    function invariant_MGN_08(uint128 accountId, uint collateralId) internal {
        if (collateralId == 3) {
            fl.eq(
                states[1].actorStates[accountId].collateralAmountHUGE %
                    (10 ** (hugePrecisionTokenMock.decimals() - 18)),
                0,
                MGN_08
            );
        }
    }

    function invariant_MGN_09(uint128 accountId) internal {
        if (!states[0].actorStates[accountId].isPositionLiquidatable) {
            fl.t(
                !states[1].actorStates[accountId].isPositionLiquidatable,
                MGN_09
            );
        }
    }

    function invariant_MGN_10(uint128 accountId) internal {
        if (!states[0].actorStates[accountId].isPositionLiquidatable) {
            fl.t(
                !states[1].actorStates[accountId].isPositionLiquidatable,
                MGN_10
            );
        }
    }

    function invariant_MGN_11() internal {
        fl.eq(
            states[1].depositedSusdCollateral,
            uint(states[1].collateralValueAllUsersSUSDCalculated),
            MGN_11
        );

        fl.eq(
            states[1].depositedWethCollateral,
            uint(states[1].collateralValueAllUsersWETHCalculated),
            MGN_11
        );

        fl.eq(
            states[1].depositedWbtcCollateral,
            uint(states[1].collateralValueAllUsersWBTCCalculated),
            MGN_11
        );
    }
}
