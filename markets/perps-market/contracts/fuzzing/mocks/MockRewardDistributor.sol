// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IRewardDistributor} from "@synthetixio/main/contracts/interfaces/external/IRewardDistributor.sol";
import {IERC165} from "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";
import "./MockSynthetixV3.sol";
import {console2} from "lib/forge-std/src/Test.sol";

contract MockRewardDistributor {
    MockSynthetixV3 v3Mock;
    uint128 public poolId;
    uint public collateralId;
    constructor(MockSynthetixV3 _v3Mock, uint128 _poolId, uint _collateralId) {
        v3Mock = _v3Mock;
        poolId = _poolId;
        collateralId = _collateralId;
    }

    function getPoolId() external view returns (uint128) {
        return poolId;
    }

    function getPoolCollateralTypes() external view returns (address[] memory) {
        return v3Mock.getCollateralTypes();
    }

    function distributeRewards(
        uint128 poolId_,
        address collateralType_,
        uint256 amount_,
        uint64 start_,
        uint32 duration_
    ) external {
        // distribute a portion of debt rewards to different vaults
        // TODO: commenting out temporarily to resolve issues in LiquidationModule coverage
        // v3Mock.updateRewardDistribution(collateralType, amount);
        // console2.log(
        //     "====== MockRewardDistributor::distributeRewards END ======"
        // );
    }

    /**
        Below are required for passing safeSupportsInterface when calling MarginModule::setMarginCollateralConfiguration
    */
    function name() external view returns (string memory) {
        return "MockRewardDistributor";
    }

    function payout(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address sender,
        uint256 amount
    ) external returns (bool) {
        // check if user is actually deposited into the vault and has shares
        require(v3Mock.getShares(sender, collateralType));

        // calculate how much a user is owed based on their share of the vault
        // each user's deposit in a vault is 1 share for simplification
        (, , , uint256 rewardAmount, uint256 totalShares) = v3Mock.vaults(
            collateralType
        );
        uint256 percentOfVault = (1 * 1e18) / (totalShares * 1e18);
        uint256 amountOfRewards = percentOfVault * rewardAmount;

        if (amount <= amountOfRewards) {
            MockERC20(collateralType).transfer(sender, amount);
            return true;
        }

        return false;
    }

    function onPositionUpdated(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newShares
    ) external {}

    /// @notice Address to ERC-20 token distributed by this distributor, for display purposes only
    /// @dev Return address(0) if providing non ERC-20 rewards
    function token() external view returns (address) {
        return
            collateralId == 1
                ? v3Mock.wETH()
                : collateralId == 2
                    ? v3Mock.wBTC()
                    : v3Mock.huge();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IRewardDistributor).interfaceId ||
            interfaceId == this.supportsInterface.selector;
    }
}
