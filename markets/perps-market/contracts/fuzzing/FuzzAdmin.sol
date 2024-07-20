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

    event DebugPrice(int256 p, string s);

    function fuzz_changeWETHPythPrice(int64 newPrice) public {
        ChangePythPriceParams memory params = changeWETHPythPricePreconditions(
            newPrice
        );
        fl.gt(
            params.newPrice,
            0,
            "fuzz_changeWETHPythPrice AFTER CHANGED PRICE"
        );

        pythWrapper.setBenchmarkPrice(WETH_FEED_ID, params.newPrice);

        changePythPricePostconditions(params.id, params.newPrice);
    }

    function fuzz_changeWBTCPythPrice(int64 newPrice) public {
        ChangePythPriceParams memory params = changeWBTCPythPricePreconditions(
            newPrice
        );
        fl.gt(
            params.newPrice,
            0,
            "fuzz_changeWBTCPythPrice AFTER CHANGED PRICE"
        );

        pythWrapper.setBenchmarkPrice(WBTC_FEED_ID, params.newPrice);

        changePythPricePostconditions(params.id, params.newPrice);
    }

    event OM(bytes32 node, string s);

    function fuzz_changeOracleManagerPrice(
        uint256 nodeIndex,
        int256 newPrice
    ) public {
        (
            int256 newClampedPrice,
            bytes32 nodeId
        ) = changeOracleManagerPricePreconditions(nodeIndex, newPrice);
        fl.gt(
            newClampedPrice,
            0,
            "fuzz_changeOracleManagerPrice CLAMPED PRICE NEGATIVE!"
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
        ) = delegateCollateralPreconditions(
                newCollateralAmountD18,
                collateralIndex
            );

        vaultModuleMock.delegateCollateral(
            accountId,
            poolId,
            collateralType,
            clampedNewCollateralAmountD18,
            leverage,
            marketId
        );
    }

    function fuzz_crashWBTCPythPrice(uint loops) public {
        loops = fl.clamp(loops, 1, 10);
        ChangePythPriceParams memory params;
        for (uint i; i < loops; i++) {
            params = crashWBTCPythPricePreconditions();

            pythWrapper.setBenchmarkPrice(WBTC_FEED_ID, params.newPrice);
        }
        fl.gt(
            params.newPrice,
            0,
            "fuzz_crashWBTCPythPrice AFTER CHANGED PRICE"
        );

        changePythPricePostconditions(params.id, params.newPrice);
    }

    function fuzz_pumpWBTCPythPrice(uint loops) public {
        loops = fl.clamp(loops, 1, 10);

        ChangePythPriceParams memory params;
        for (uint i; i < loops; i++) {
            params = pumpWBTCPythPricePreconditions();

            pythWrapper.setBenchmarkPrice(WBTC_FEED_ID, params.newPrice);
        }
        fl.gt(
            params.newPrice,
            0,
            "fuzz_crashWBTCPythPrice AFTER CHANGED PRICE"
        );

        changePythPricePostconditions(params.id, params.newPrice);
    }

    function fuzz_crashWETHPythPrice(uint loops) public {
        loops = fl.clamp(loops, 1, 10);

        ChangePythPriceParams memory params;
        for (uint i; i < loops; i++) {
            params = crashWETHPythPricePreconditions();

            pythWrapper.setBenchmarkPrice(WETH_FEED_ID, params.newPrice);
        }
        fl.gt(
            params.newPrice,
            0,
            "fuzz_crashWETHPythPrice AFTER CHANGED PRICE"
        );

        changePythPricePostconditions(params.id, params.newPrice);
    }

    function fuzz_pumpWETHPythPrice(uint loops) public {
        loops = fl.clamp(loops, 1, 10);

        ChangePythPriceParams memory params;
        for (uint i; i < loops; i++) {
            params = pumpWETHPythPricePreconditions();

            pythWrapper.setBenchmarkPrice(WETH_FEED_ID, params.newPrice);
        }
        fl.gt(
            params.newPrice,
            0,
            "fuzz_crashWETHPythPrice AFTER CHANGED PRICE"
        );

        changePythPricePostconditions(params.id, params.newPrice);
    }
}
