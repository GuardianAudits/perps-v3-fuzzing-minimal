// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./helper/preconditions/PreconditionsAdmin.sol";
import "./helper/postconditions/PostconditionsAdmin.sol";

contract FuzzAdmin is PreconditionsAdmin, PostconditionsAdmin {
    function fuzz_mintUSDToSynthetix(uint256 amount) public {
        amount = mintUSDToSynthetixPreconditions(amount);

        v3Mock.mintUSDToSynthetix(amount);
    }

    function fuzz_burnUSDFromSynthetix(uint256 amount) public {
        amount = burnUSDFromSynthetixPreconditions(amount);

        v3Mock.burnUSDFromSynthetix(amount);
    }

    function fuzz_changeWETHPythPrice(int64 newPrice) public {
        ChangePythPriceParams memory params = changeWETHPythPricePreconditions(newPrice);

        pythWrapperWETH.setBenchmarkPrice(params.newPrice);

        changePythPricePostconditions(params.id, params.newPrice);
    }

    function fuzz_changeWBTCPythPrice(int64 newPrice) public {
        ChangePythPriceParams memory params = changeWBTCPythPricePreconditions(newPrice);

        pythWrapperWBTC.setBenchmarkPrice(params.newPrice);

        changePythPricePostconditions(params.id, params.newPrice);
    }

    function fuzz_changeOracleManagerPrice(uint256 nodeIndex, int256 newPrice) public {
        (int256 newClampedPrice, bytes32 nodeId) = changeOracleManagerPricePreconditions(
            nodeIndex,
            newPrice
        );

        mockOracleManager.changePrice(nodeId, newClampedPrice);

        changeOracleManagerPricePostconditions(nodeId, newClampedPrice);
    }

    function fuzz_delegateCollateral(
        uint128 accountId,
        uint128 poolId,
        uint256 collateralIndex,
        uint256 newCollateralAmountD18,
        uint256 leverage
    ) public {
        (
            uint256 clampedNewCollateralAmountD18,
            address collateralType,
            uint128 marketId
        ) = delegateCollateralPreconditions(newCollateralAmountD18, collateralIndex);

        vaultModuleMock.delegateCollateral(
            accountId,
            poolId,
            collateralType,
            clampedNewCollateralAmountD18,
            leverage,
            marketId
        );
    }
}
