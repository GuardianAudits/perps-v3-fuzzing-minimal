//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ERC2771Context} from "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";
import {FeatureFlag} from "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";
import {IAsyncOrderSettlementPythModule} from "../interfaces/IAsyncOrderSettlementPythModule.sol";
import {PerpsAccount, SNX_USD_MARKET_ID} from "../storage/PerpsAccount.sol";
import {MathUtil} from "../utils/MathUtil.sol";
import {Flags} from "../utils/Flags.sol";
import {PerpsMarket} from "../storage/PerpsMarket.sol";
import {AsyncOrder} from "../storage/AsyncOrder.sol";
import {Position} from "../storage/Position.sol";
import {GlobalPerpsMarket} from "../storage/GlobalPerpsMarket.sol";
import {SettlementStrategy} from "../storage/SettlementStrategy.sol";
import {PerpsMarketFactory} from "../storage/PerpsMarketFactory.sol";
import {GlobalPerpsMarketConfiguration} from "../storage/GlobalPerpsMarketConfiguration.sol";
import {IMarketEvents} from "../interfaces/IMarketEvents.sol";
import {IAccountEvents} from "../interfaces/IAccountEvents.sol";
import {KeeperCosts} from "../storage/KeeperCosts.sol";
import {IPythERC7412Wrapper} from "../interfaces/external/IPythERC7412Wrapper.sol";
import {SafeCastU256, SafeCastI256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "forge-std/console2.sol";
import {PerpsPrice} from "../storage/PerpsPrice.sol";

/**
 * @title Module for settling async orders using pyth as price feed.
 * @dev See IAsyncOrderSettlementPythModule.
 */
contract AsyncOrderSettlementPythModule is
    IAsyncOrderSettlementPythModule,
    IMarketEvents,
    IAccountEvents
{
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;
    using PerpsAccount for PerpsAccount.Data;
    using PerpsMarket for PerpsMarket.Data;
    using AsyncOrder for AsyncOrder.Data;
    using PerpsMarketFactory for PerpsMarketFactory.Data;
    using GlobalPerpsMarket for GlobalPerpsMarket.Data;
    using GlobalPerpsMarketConfiguration for GlobalPerpsMarketConfiguration.Data;
    using Position for Position.Data;
    using KeeperCosts for KeeperCosts.Data;

    /**
     * @inheritdoc IAsyncOrderSettlementPythModule
     */
    function settleOrder(uint128 accountId) external {
        FeatureFlag.ensureAccessToFeature(Flags.PERPS_SYSTEM);

        (
            AsyncOrder.Data storage asyncOrder,
            SettlementStrategy.Data storage settlementStrategy
        ) = AsyncOrder.loadValid(accountId);

        int256 offchainPrice = IPythERC7412Wrapper(
            settlementStrategy.priceVerificationContract
        ).getBenchmarkPrice(
                settlementStrategy.feedId,
                (asyncOrder.commitmentTime +
                    settlementStrategy.commitmentPriceDelay).to64()
            );

        _settleOrder(offchainPrice.toUint(), asyncOrder, settlementStrategy);
    }

    /**
     * @notice Settles an offchain order
     * @param price provided by offchain oracle
     * @param asyncOrder to be validated and settled
     * @param settlementStrategy used to validate order and calculate settlement reward
     */
    function _settleOrder(
        uint256 price,
        AsyncOrder.Data storage asyncOrder,
        SettlementStrategy.Data storage settlementStrategy
    ) private {
        /// @dev runtime stores order settlement data; circumvents stack limitations
        SettleOrderRuntime memory runtime;

        runtime.accountId = asyncOrder.request.accountId;
        runtime.marketId = asyncOrder.request.marketId;
        runtime.sizeDelta = asyncOrder.request.sizeDelta;

        GlobalPerpsMarket.load().checkLiquidation(runtime.accountId);

        Position.Data storage oldPosition;
        console2.log("%%%%%%%%%%%%% validate request %%%%%%%%%%%%%");
         PerpsAccount.Data storage perpsAccount = PerpsAccount.load(runtime.accountId);

        // validate order request can be settled; call reverts if not
        (runtime.newPosition, runtime.totalFees, runtime.fillPrice, oldPosition) = asyncOrder
            .validateRequest(settlementStrategy, price);
        int currentAvailableMargin;
        bool isEligible;

        console2.log("oldPosition:", oldPosition.size);
        console2.log("newPosition:", runtime.newPosition.size);
        console2.log("size:", runtime.sizeDelta);
        
        console2.log("############## end validate request ############");
        console2.log();

         console2.log("------ ELIGIBLE CHECK BEFORE CHARGE -----");

         (
            isEligible,
            currentAvailableMargin
        ) = perpsAccount.isEligibleForMarginLiquidation(PerpsPrice.Tolerance.DEFAULT);
        console2.log("<_settleOrder> isEligible BEFORE CHARGE:", isEligible);
        console2.log("<_settleOrder> currentAvailableMargin BEFORE CHARGE:", currentAvailableMargin);
        console2.log("------ END ELIGIBLE CHECK BEFORE CHARGE -----");


        // validate final fill price is acceptable relative to price specified by trader
        asyncOrder.validateAcceptablePrice(runtime.fillPrice);

        PerpsMarketFactory.Data storage factory = PerpsMarketFactory.load();
       
        // use actual fill price to calculate realized pnl
        (runtime.pnl, , runtime.chargedInterest, runtime.accruedFunding, , ) = oldPosition.getPnl(
            runtime.fillPrice
        );
        
        runtime.chargedAmount = runtime.pnl - runtime.totalFees.toInt();
        perpsAccount.charge(runtime.chargedAmount);

        emit AccountCharged(runtime.accountId, runtime.chargedAmount, perpsAccount.debt);

        console2.log("------ ELIGIBLE CHECK AFTER CHARGE -----");

         (
            isEligible,
            currentAvailableMargin
        ) = perpsAccount.isEligibleForMarginLiquidation(PerpsPrice.Tolerance.DEFAULT);
        console2.log("<_settleOrder> isEligible AFTER CHARGE:", isEligible);
        console2.log("<_settleOrder> currentAvailableMargin AFTER CHARGE:", currentAvailableMargin);
        console2.log("------ END ELIGIBLE CHECK AFTER CHARGE -----");




        // only update position state after pnl has been realized
        runtime.updateData = PerpsMarket.loadValid(runtime.marketId).updatePositionData(
            runtime.accountId,
            runtime.newPosition
        );


        console2.log("------ ELIGIBLE CHECK AFTER UPDATE POSITION DATA -----");

         (
            isEligible,
            currentAvailableMargin
        ) = perpsAccount.isEligibleForMarginLiquidation(PerpsPrice.Tolerance.DEFAULT);
        console2.log("<_settleOrder> isEligible AFTER UPDATE POS DATA:", isEligible);
        console2.log("<_settleOrder> currentAvailableMargin AFTER UPDATE POS DATA:", currentAvailableMargin);
        console2.log("------ END ELIGIBLE CHECK AFTER UPDATE POSITION DATA -----");



        perpsAccount.updateOpenPositions(runtime.marketId, runtime.newPosition.size);

        console2.log("------ ELIGIBLE CHECK AFTER UPDATE OPEN POSITIONS -----");

         (
            isEligible,
            currentAvailableMargin
        ) = perpsAccount.isEligibleForMarginLiquidation(PerpsPrice.Tolerance.DEFAULT);
        console2.log("<_settleOrder> isEligible AFTER UPDATE OPEN POSITIONS:", isEligible);
        console2.log("<_settleOrder> currentAvailableMargin AFTER UPDATE OPEN POSITIONS:", currentAvailableMargin);
        console2.log("------ END ELIGIBLE CHECK AFTER UPDATE OPEN POSITIONS -----");




        // emit MarketUpdated(
        //     runtime.updateData.marketId,
        //     price,
        //     runtime.updateData.skew,
        //     runtime.updateData.size,
        //     runtime.sizeDelta,
        //     runtime.updateData.currentFundingRate,
        //     runtime.updateData.currentFundingVelocity,
        //     runtime.updateData.interestRate
        // );

        runtime.settlementReward = AsyncOrder.settlementRewardCost(settlementStrategy);

        // if settlement reward is non-zero, pay keeper
        if (runtime.settlementReward > 0) {
            factory.withdrawMarketUsd(ERC2771Context._msgSender(), runtime.settlementReward);
        }

        {
            // order fees are total fees minus settlement reward
            uint256 orderFees = runtime.totalFees - runtime.settlementReward;
            GlobalPerpsMarketConfiguration.Data storage s = GlobalPerpsMarketConfiguration.load();
            s.collectFees(orderFees, asyncOrder.request.referrer, factory);
        }

        // trader can now commit a new order
        asyncOrder.reset();

        /// @dev two events emitted to avoid stack limitations
        // emit InterestCharged(runtime.accountId, runtime.chargedInterest);

        // emit event
        // emit OrderSettled(
        //     runtime.marketId,
        //     runtime.accountId,
        //     runtime.fillPrice,
        //     runtime.pnl,
        //     runtime.accruedFunding,
        //     runtime.sizeDelta,
        //     runtime.newPosition.size,
        //     runtime.totalFees,
        //     runtime.referralFees,
        //     runtime.feeCollectorFees,
        //     runtime.settlementReward,
        //     asyncOrder.request.trackingCode,
        //     ERC2771Context._msgSender()
        // );
    }
}
