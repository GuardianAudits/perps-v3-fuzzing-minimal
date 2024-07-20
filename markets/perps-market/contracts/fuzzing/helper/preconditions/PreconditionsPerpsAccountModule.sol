// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

abstract contract PreconditionsPerpsAccountModule is PreconditionsBase {
    struct ModifyCollateralParams {
        uint128 accountId;
        uint128 marketId;
        address collateralAddress;
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
        uint128 account = userToAccountIds[currentActor][
            collateralTokenIndex % userToAccountIds[currentActor].length
        ];
        uint128 marketId = collateralTokenIndex % 2 == 0 ? 1 : 2;

        return
            ModifyCollateralParams({
                accountId: account,
                marketId: marketId,
                collateralAddress: collateralToken,
                amountDelta: fl.clamp(amountDelta, -int128(MAX_ALLOWABLE), int128(MAX_ALLOWABLE))
            });
    }

    function payDebtPreconditions(uint128 amount) internal view returns (PayDebtParams memory) {
        uint128 account = userToAccountIds[currentActor][
            amount % userToAccountIds[currentActor].length
        ];
        uint128 marketId = amount % 2 == 0 ? 1 : 2;

        return PayDebtParams({accountId: account, marketId: marketId, amount: amount});
    }
}
