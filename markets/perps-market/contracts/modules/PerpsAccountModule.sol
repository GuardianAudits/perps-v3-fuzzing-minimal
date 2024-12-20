//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ERC2771Context} from "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";
import {FeatureFlag} from "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";
import {Account} from "@synthetixio/main/contracts/storage/Account.sol";
import {AccountRBAC} from "@synthetixio/main/contracts/storage/AccountRBAC.sol";
import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {ITokenModule} from "@synthetixio/core-modules/contracts/interfaces/ITokenModule.sol";
import {PerpsMarketFactory} from "../storage/PerpsMarketFactory.sol";
import {IPerpsAccountModule} from "../interfaces/IPerpsAccountModule.sol";
import {PerpsAccount, SNX_USD_MARKET_ID} from "../storage/PerpsAccount.sol";
import {Position} from "../storage/Position.sol";
import {AsyncOrder} from "../storage/AsyncOrder.sol";
import {PerpsMarket} from "../storage/PerpsMarket.sol";
import {GlobalPerpsMarket} from "../storage/GlobalPerpsMarket.sol";
import {PerpsPrice} from "../storage/PerpsPrice.sol";
import {MathUtil} from "../utils/MathUtil.sol";
import {Flags} from "../utils/Flags.sol";
import {SafeCastU256, SafeCastI256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {PerpsCollateralConfiguration} from "../storage/PerpsCollateralConfiguration.sol";

import {console2} from "../../lib/forge-std/src/Test.sol";

/**
 * @title Module to manage accounts
 * @dev See IPerpsAccountModule.
 */
contract PerpsAccountModule is IPerpsAccountModule {
    using SetUtil for SetUtil.UintSet;
    using PerpsAccount for PerpsAccount.Data;
    using Position for Position.Data;
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;
    using GlobalPerpsMarket for GlobalPerpsMarket.Data;
    using PerpsMarketFactory for PerpsMarketFactory.Data;

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function modifyCollateral(
        uint128 accountId,
        uint128 collateralId,
        int256 amountDelta
    ) external override {
        console2.log("===== PerpsAccountModule::modifyCollateral START =====");

        console2.log("Before ensureAccessToFeature");
        FeatureFlag.ensureAccessToFeature(Flags.PERPS_SYSTEM);
        console2.log("After ensureAccessToFeature");

        PerpsCollateralConfiguration.validDistributorExists(collateralId);

        Account.exists(accountId);
        Account.loadAccountAndValidatePermission(
            accountId,
            AccountRBAC._PERPS_MODIFY_COLLATERAL_PERMISSION
        );

        if (amountDelta == 0) revert InvalidAmountDelta(amountDelta);

        console2.log("Before perpsMarketFactory");
        PerpsMarketFactory.Data storage perpsMarketFactory = PerpsMarketFactory
            .load();
        console2.log("After perpsMarketFactory");

        console2.log("Before globalPerpsMarket");

        GlobalPerpsMarket.Data storage globalPerpsMarket = GlobalPerpsMarket
            .load();
        console2.log("After globalPerpsMarket");

        globalPerpsMarket.validateCollateralAmount(collateralId, amountDelta);
        globalPerpsMarket.checkLiquidation(accountId);

        PerpsAccount.Data storage account = PerpsAccount.create(accountId);
        uint128 perpsMarketId = perpsMarketFactory.perpsMarketId;

        PerpsAccount.validateMaxCollaterals(accountId, collateralId);

        AsyncOrder.checkPendingOrder(account.id);

        if (amountDelta > 0) {
            console2.log("DEPOSIT MARGIN");
            _depositMargin(
                perpsMarketFactory,
                perpsMarketId,
                collateralId,
                amountDelta.toUint()
            );
        } else {
            uint256 amountAbs = MathUtil.abs(amountDelta);
            // removing collateral
            account.validateWithdrawableAmount(
                collateralId,
                amountAbs,
                perpsMarketFactory.spotMarket
            );
            console2.log("WITHDRAW MARGIN");

            _withdrawMargin(
                perpsMarketFactory,
                perpsMarketId,
                collateralId,
                amountAbs
            );
        }

        // accounting
        account.updateCollateralAmount(collateralId, amountDelta);

        emit CollateralModified(
            accountId,
            collateralId,
            amountDelta,
            ERC2771Context._msgSender()
        );
        console2.log("===== PerpsAccountModule::modifyCollateral END =====");
    }

    function debt(
        uint128 accountId
    ) external view override returns (uint256 accountDebt) {
        Account.exists(accountId);
        PerpsAccount.Data storage account = PerpsAccount.load(accountId);

        accountDebt = account.debt;
    }

    // 1. call depositMarketUsd and deposit amount directly to core system
    // 2. look up account and reduce debt by amount
    // 3b. quoteUnwrap() -> inchQuote -> returnAmount
    function payDebt(uint128 accountId, uint256 amount) external override {
        Account.exists(accountId);
        PerpsAccount.Data storage account = PerpsAccount.load(accountId);

        account.payDebt(amount);

        emit DebtPaid(accountId, amount, ERC2771Context._msgSender());
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function totalCollateralValue(
        uint128 accountId
    ) external view override returns (uint256) {
        return
            PerpsAccount.load(accountId).getTotalCollateralValue(
                PerpsPrice.Tolerance.DEFAULT,
                false
            );
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function totalAccountOpenInterest(
        uint128 accountId
    ) external view override returns (uint256) {
        return PerpsAccount.load(accountId).getTotalNotionalOpenInterest();
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function getOpenPosition(
        uint128 accountId,
        uint128 marketId
    )
        external
        view
        override
        returns (
            int256 totalPnl,
            int256 accruedFunding,
            int128 positionSize,
            uint256 owedInterest
        )
    {
        PerpsMarket.Data storage perpsMarket = PerpsMarket.loadValid(marketId);

        Position.Data storage position = perpsMarket.positions[accountId];

        (
            ,
            totalPnl, //pricePnl
            ,
            owedInterest,
            accruedFunding,
            ,

        ) = position.getPositionData(
            PerpsPrice.getCurrentPrice(marketId, PerpsPrice.Tolerance.DEFAULT)
        );
        console2.log("PepsAccountModule::totalPnl", totalPnl);
        console2.log("PepsAccountModule::owedInterest", owedInterest);
        console2.log("PepsAccountModule::positionSize", position.size);
        return (totalPnl, accruedFunding, position.size, owedInterest);
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function getOpenPositionSize(
        uint128 accountId,
        uint128 marketId
    ) external view override returns (int128 positionSize) {
        PerpsMarket.Data storage perpsMarket = PerpsMarket.loadValid(marketId);

        positionSize = perpsMarket.positions[accountId].size;
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function getAvailableMargin(
        uint128 accountId
    ) external view override returns (int256 availableMargin) {
        availableMargin = PerpsAccount.load(accountId).getAvailableMargin(
            PerpsPrice.Tolerance.DEFAULT
        );
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function getWithdrawableMargin(
        uint128 accountId
    ) external view override returns (int256 withdrawableMargin) {
        PerpsAccount.Data storage account = PerpsAccount.load(accountId);
        withdrawableMargin = account.getWithdrawableMargin(
            PerpsPrice.Tolerance.DEFAULT
        );
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function getRequiredMargins(
        uint128 accountId
    )
        external
        view
        override
        returns (
            uint256 requiredInitialMargin,
            uint256 requiredMaintenanceMargin,
            uint256 maxLiquidationReward
        )
    {
        PerpsAccount.Data storage account = PerpsAccount.load(accountId);
        if (account.openPositionMarketIds.length() == 0) {
            return (0, 0, 0);
        }

        (
            requiredInitialMargin,
            requiredMaintenanceMargin,
            maxLiquidationReward
        ) = account.getAccountRequiredMargins(PerpsPrice.Tolerance.DEFAULT);

        // Include liquidation rewards to required initial margin and required maintenance margin
        requiredInitialMargin += maxLiquidationReward;
        requiredMaintenanceMargin += maxLiquidationReward;
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function getCollateralAmount(
        uint128 accountId,
        uint128 collateralId
    ) external view override returns (uint256) {
        return PerpsAccount.load(accountId).collateralAmounts[collateralId];
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function getAccountCollateralIds(
        uint128 accountId
    ) external view override returns (uint256[] memory) {
        return PerpsAccount.load(accountId).activeCollateralTypes.values();
    }

    /**
     * @inheritdoc IPerpsAccountModule
     */
    function getAccountOpenPositions(
        uint128 accountId
    ) external view override returns (uint256[] memory) {
        return PerpsAccount.load(accountId).openPositionMarketIds.values();
    }

    function _depositMargin(
        PerpsMarketFactory.Data storage perpsMarketFactory,
        uint128 perpsMarketId,
        uint128 collateralId,
        uint256 amount
    ) internal {
        if (collateralId == SNX_USD_MARKET_ID) {
            // depositing into the USD market
            perpsMarketFactory.synthetix.depositMarketUsd(
                perpsMarketId,
                ERC2771Context._msgSender(),
                amount
            );
        } else {
            ITokenModule synth = ITokenModule(
                perpsMarketFactory.spotMarket.getSynth(collateralId)
            );
            synth.transferFrom(
                ERC2771Context._msgSender(),
                address(this),
                amount
            );
            // depositing into a synth market
            perpsMarketFactory.depositMarketCollateral(synth, amount);
        }
    }

    function _withdrawMargin(
        PerpsMarketFactory.Data storage perpsMarketFactory,
        uint128 perpsMarketId,
        uint128 collateralId,
        uint256 amount
    ) internal {
        if (collateralId == SNX_USD_MARKET_ID) {
            // withdrawing from the USD market
            perpsMarketFactory.synthetix.withdrawMarketUsd(
                perpsMarketId,
                ERC2771Context._msgSender(),
                amount
            );
        } else {
            ITokenModule synth = ITokenModule(
                perpsMarketFactory.spotMarket.getSynth(collateralId)
            );
            // withdrawing from a synth market
            perpsMarketFactory.synthetix.withdrawMarketCollateral(
                perpsMarketId,
                address(synth),
                amount
            );
            synth.transfer(ERC2771Context._msgSender(), amount);
        }
    }
}
