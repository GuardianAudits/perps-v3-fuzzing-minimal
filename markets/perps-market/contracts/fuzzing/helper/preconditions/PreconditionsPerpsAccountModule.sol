// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

abstract contract PreconditionsPerpsAccountModule is PreconditionsBase {
    struct ModifyCollateralParams {
        uint128 accountId;
        uint128 marketId;
        address collateralAddress;
        uint128 collateralId;
        int256 amountDelta;
    }

    struct PayDebtParams {
        uint128 accountId;
        uint128 marketId;
        uint128 amount;
    }

    function modifyCollateralPreconditions(
        int256 amountDelta,
        uint256 collateralTokenIndex
    ) internal returns (ModifyCollateralParams memory) {
        address collateralToken = _getRandomCollateralToken(collateralTokenIndex);
        uint128 account = userToAccountIds[currentActor];

        uint128 marketId = collateralTokenIndex % 2 == 0 ? 1 : 2;

        uint128 collateralId;
        if (collateralToken == address(sUSDTokenMock)) collateralId = 0;
        else if (collateralToken == address(wethTokenMock)) collateralId = 1;
        else if (collateralToken == address(wbtcTokenMock)) collateralId = 2;

        return
            ModifyCollateralParams({
                accountId: account,
                marketId: marketId,
                collateralAddress: collateralToken,
                collateralId: collateralId,
                amountDelta: fl.clamp(amountDelta, -int128(MAX_ALLOWABLE), int128(MAX_ALLOWABLE))
            });
    }

    function payDebtPreconditions(uint128 amount) internal view returns (PayDebtParams memory) {
        uint128 account = userToAccountIds[currentActor];
        uint128 marketId = amount % 2 == 0 ? 1 : 2;

        return PayDebtParams({accountId: account, marketId: marketId, amount: amount});
    }
}
