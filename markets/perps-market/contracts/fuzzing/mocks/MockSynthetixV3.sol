// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {INodeModule, NodeOutput} from "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import {ERC2771Context} from "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";
import {MockERC20} from "./MockERC20.sol";
import {MockOracleManager} from "./MockOracleManager.sol";
import {MathUtil} from "../../utils/MathUtil.sol";
import {console2} from "lib/forge-std/src/Test.sol";

struct Vault {
    address collateralToken;
    bytes32 nodeId; // the nodeId used in oracleManager to return the price for a give collateral type
    uint256 collateralAmount; // the amount of a given collateral held in SynthetixV3
    uint256 rewardAmount; // reward amount accumulated for a debt distribution during a liquidation event
    uint256 totalShares; // the total amount of shares that exist in the vault
}
struct Cache {
    uint256 sUSDBalance;
    uint256 wETHBalance;
    uint256 wBTCBalance;
    uint256 hugeBalance;
    bytes32 sUSDNodeId;
    bytes32 wETHNodeId;
    bytes32 wBTCNodeId;
    bytes32 hugeNodeId;
    NodeOutput.Data sUSDNode;
    NodeOutput.Data wETHNode;
    NodeOutput.Data wBTCNode;
    NodeOutput.Data hugeNode;
    uint256 valueSUSD;
    uint256 valueWETH;
    uint256 valuewBTC;
    uint256 valuehuge;
}
contract MockSynthetixV3 {
    address oracleManager;
    address public sUSD;
    address public wETH;
    address public wBTC;
    address public huge;
    uint256 public withdrawableUSD;
    uint256 public creditCapacity;

    mapping(address collateralToken => Vault) public vaults;
    mapping(address user => mapping(address collateralToken => bool deposited))
        public shares; // mock implementation of vault shares where each user gets 1 share of the vault they're depositing into, independent of deposit size for simplicity, since each user gets one share, just need to know if they're deposited into a vault

    event DepositMarketUsd(uint128 marketId, address msgSender, uint256 amount);
    event DepositMarketUsdAfter(
        uint128 marketId,
        address msgSender,
        uint256 amount
    );

    uint256 constant FEE_PERCENT = 0.01e18;

    /**
        Getters
    */
    function getUsdToken() external view returns (address) {
        return sUSD;
    }

    function getAssociatedSystem(
        bytes32 id
    ) external returns (address, bytes32) {
        if (id == vaults[sUSD].nodeId) {
            return (vaults[sUSD].collateralToken, "");
        } else if (id == vaults[wETH].nodeId) {
            return (vaults[wETH].collateralToken, "");
        } else if (id == vaults[wBTC].nodeId) {
            return (vaults[wBTC].collateralToken, "");
        } else if (id == vaults[huge].nodeId) {
            return (vaults[huge].collateralToken, "");
        }
    }

    function getOracleManager() external returns (address) {
        return oracleManager;
    }

    function getWithdrawableMarketUsd(
        uint128 marketId
    ) external view returns (uint256 withdrawableUsd) {
        console2.log(
            "===== MockSynthetixV3::getWithdrawableMarketUsd START ====="
        );
        console2.log("marketId", marketId);

        Cache memory cache;

        cache.sUSDBalance = MockERC20(sUSD).balanceOf(address(this));
        console2.log("sUSDBalance", cache.sUSDBalance);

        cache.wETHBalance = MockERC20(wETH).balanceOf(address(this));
        console2.log("wETHBalance", cache.wETHBalance);

        cache.wBTCBalance = MockERC20(wBTC).balanceOf(address(this));
        console2.log("wBTCBalance", cache.wBTCBalance);

        cache.hugeBalance = MockERC20(huge).balanceOf(address(this));
        console2.log("hugeBalance", cache.hugeBalance);

        cache.sUSDNodeId = vaults[sUSD].nodeId;
        console2.log("sUSDNodeId");
        console2.logBytes32(cache.sUSDNodeId);

        cache.wETHNodeId = vaults[wETH].nodeId;
        console2.log("wETHNodeId");
        console2.logBytes32(cache.wETHNodeId);

        cache.wBTCNodeId = vaults[wBTC].nodeId;
        console2.log("wBTCNodeId");
        console2.logBytes32(cache.wBTCNodeId);

        cache.hugeNodeId = vaults[huge].nodeId;
        console2.log("hugeNodeId");
        console2.logBytes32(cache.hugeNodeId);

        cache.sUSDNode = MockOracleManager(oracleManager).process(
            cache.sUSDNodeId
        );
        console2.log("sUSDNode.price", cache.sUSDNode.price);

        cache.wETHNode = MockOracleManager(oracleManager).process(
            cache.wETHNodeId
        );
        console2.log("wETHNode.price", cache.wETHNode.price);

        cache.wBTCNode = MockOracleManager(oracleManager).process(
            cache.wBTCNodeId
        );
        console2.log("wBTCNode.price", cache.wBTCNode.price);

        cache.hugeNode = MockOracleManager(oracleManager).process(
            cache.hugeNodeId
        );
        console2.log("hugeNode.price", cache.hugeNode.price);

        cache.valueSUSD = uint256(int256(cache.sUSDBalance));
        console2.log("valueSUSD", cache.valueSUSD);

        cache.valueWETH = uint256(
            (int256(cache.wETHBalance) * cache.wETHNode.price) / 1e18
        );
        console2.log("valueWETH", cache.valueWETH);

        cache.valuewBTC = uint256(
            (int256(cache.wBTCBalance) * cache.wBTCNode.price) / 1e18
        );
        console2.log("valuewBTC", cache.valuewBTC);

        cache.valuehuge = uint256(
            (int256(cache.hugeBalance) * cache.hugeNode.price) / 1e18
        );
        console2.log("valuehuge", cache.valuehuge);

        withdrawableUsd = MathUtil.min(
            creditCapacity +
                (cache.valueSUSD +
                    cache.valueWETH +
                    cache.valuewBTC +
                    cache.valuehuge),
            type(uint128).max
        );
        console2.log("withdrawableUsd", withdrawableUsd);

        console2.log(
            "===== MockSynthetixV3::getWithdrawableMarketUsd END ====="
        );
    }

    event Debug(string s);
    event DebugValue(int256 val);
    function getVaultCollateral(
        uint128 poolId,
        address collateralType
    ) public returns (uint256 amount, uint256 value) {
        amount = vaults[collateralType].collateralAmount;

        // poolId is irrelevant because assuming only one pool exists so just query using the collateralType id here
        bytes32 nodeId = vaults[collateralType].nodeId;
        // NodeOutput.Data memory node = MockOracleManager(oracleManager).process(nodeId);
        // emit DebugValue(node.price);
        // value = uint256(int256(amount) * node.price);

        // TODO: temporary fix to work around StateChangeWhileStatic error
        // assumes price of 1
        value = amount * 1;
        // emit Debug("getVaultCollateral");
    }

    /// @notice assumes that there's only one pool in the system
    /// @dev added to simplify fetching collaterals for MockRewardDistributor
    function getCollateralTypes() external view returns (address[] memory) {
        address[] memory collateralTypes = new address[](4);
        collateralTypes[0] = sUSD;
        collateralTypes[1] = wETH;
        collateralTypes[2] = wBTC;
        collateralTypes[3] = huge;
        return collateralTypes;
    }

    function getShares(
        address user,
        address collateral
    ) external view returns (bool) {
        return shares[user][collateral];
    }

    /** 
        Admin
    */
    function setUSDToken(address _usdToken, bytes32 _nodeId) external {
        sUSD = _usdToken;
        vaults[_usdToken].nodeId = _nodeId;
    }

    function setWethToken(address _wethToken, bytes32 _nodeId) external {
        wETH = _wethToken;
        vaults[_wethToken].nodeId = _nodeId;
    }

    function setWbtcToken(address _wbtcToken, bytes32 _nodeId) external {
        wBTC = _wbtcToken;
        vaults[_wbtcToken].nodeId = _nodeId;
    }

    function setHugeToken(address _hugeToken, bytes32 _nodeId) external {
        huge = _hugeToken;
        vaults[_hugeToken].nodeId = _nodeId;
    }

    function setOracleManager(address _oracleManager) external {
        oracleManager = _oracleManager;
    }

    function registerMarket(address market) external returns (uint128) {
        return 1;
    }

    function setCollateralPrice(
        address collateralType,
        uint256 newPrice
    ) external {
        bytes32 nodeId = vaults[collateralType].nodeId;

        // this needs to use the MockOracleManager to set the price for a given collateral type
        MockOracleManager(oracleManager).changePrice(nodeId, int256(newPrice));
    }

    /// @notice only used by MockRewardDistributor to simulate distributing reward shares
    function updateRewardDistribution(
        address collateralToken,
        uint256 amount
    ) external {
        vaults[collateralToken].rewardAmount += amount;
    }

    function updateCreditCapacity(uint256 amount, bool increase) external {
        if (increase) {
            creditCapacity += amount;
        } else {
            creditCapacity -= amount;
        }
    }

    /**
        User Actions
    */
    function mintUSDToSynthetix(uint256 toMint) external {
        MockERC20(sUSD).mint(address(this), toMint);
    }

    function burnUSDFromSynthetix(uint256 toBurn) external {
        MockERC20(sUSD).burn(address(this), toBurn);
    }

    function depositMarketUsd(
        uint128 marketId,
        address msgSender,
        uint256 amount
    ) external returns (uint256) {
        MockERC20(sUSD).burn(msgSender, amount);
        MockERC20(sUSD).mint(address(1), (amount * FEE_PERCENT) / 1e18);

        // accounting for user shares for handling rewards that get distributed in a liquidation event
        vaults[sUSD].totalShares += 1;
        shares[msgSender][sUSD] = true;
        creditCapacity += (amount - (amount * FEE_PERCENT) / 1e18);

        return (amount * FEE_PERCENT) / 1e18;
    }

    // function withdrawMarketUsd(
    //     uint128 marketId,
    //     address target,
    //     uint256 amount
    // ) external returns (uint256) {
    //     MockERC20(sUSD).mint(target, amount);
    //     MockERC20(sUSD).mint(address(1), (amount * FEE_PERCENT) / 1e18);

    //     // accounting for user shares for handling rewards that get distributed in a liquidation event
    //     // if the user has shares in the vault, then they should be decremented
    //     if (shares[msg.sender][sUSD]) {
    //         vaults[sUSD].totalShares -= 1;
    //         shares[msg.sender][sUSD] = false;
    //     }

    //     creditCapacity -= (amount + (amount * FEE_PERCENT) / 1e18);

    //     return (amount * FEE_PERCENT) / 1e18;
    // }
    function withdrawMarketUsd(
        uint128 marketId,
        address target,
        uint256 amount
    ) external returns (uint256) {
        console2.log("marketId", marketId);
        console2.log("target", target);
        console2.log("amount", amount);

        MockERC20(sUSD).mint(target, amount);
        console2.log("Minted to target", amount);

        uint256 feeAmount = (amount * FEE_PERCENT) / 1e18;
        console2.log("feeAmount", feeAmount);

        MockERC20(sUSD).mint(address(1), feeAmount);
        console2.log("Minted fee to address(1)", feeAmount);

        console2.log("msg.sender", msg.sender);
        console2.log(
            "shares[msg.sender][sUSD] before",
            shares[msg.sender][sUSD]
        );

        // accounting for user shares for handling rewards that get distributed in a liquidation event
        // if the user has shares in the vault, then they should be decremented
        if (shares[msg.sender][sUSD]) {
            console2.log(
                "vaults[sUSD].totalShares before",
                vaults[sUSD].totalShares
            );
            vaults[sUSD].totalShares -= 1;
            console2.log(
                "vaults[sUSD].totalShares after",
                vaults[sUSD].totalShares
            );

            shares[msg.sender][sUSD] = false;
            console2.log(
                "shares[msg.sender][sUSD] after",
                shares[msg.sender][sUSD]
            );
        }

        console2.log("creditCapacity before", creditCapacity);
        creditCapacity -= (amount + feeAmount);
        console2.log("creditCapacity after", creditCapacity);

        console2.log("Returning feeAmount", feeAmount);
        return feeAmount;
    }
    /// @notice allows a market to deposit collateral
    /// @dev assumes collateral types with 18 decimals
    function depositMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmount
    ) external {
        // NOTE: no fees accounted for in this deposit function, unlike in depositMarketUsd
        // account for token being deposited into a vault
        vaults[collateralType].collateralAmount += tokenAmount;

        // accounting for user shares for handling rewards that get distributed in a liquidation event
        vaults[collateralType].totalShares += 1;
        shares[msg.sender][collateralType] = true;

        // transfer collateral token
        MockERC20(collateralType).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
    }

    /// @notice allows a market to withdraw collateral that it has previously deposited.
    /// @dev marketId is irrelevant because this just mocks total accounting into and out of system
    function withdrawMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmount
    ) external {
        // account for token being removed from a vault
        vaults[collateralType].collateralAmount -= tokenAmount;

        // accounting for user shares for handling rewards that get distributed in a liquidation event
        // vaults[collateralType].totalShares -= 1;
        // shares[msg.sender][collateralType] = false;

        MockERC20(collateralType).transfer(
            ERC2771Context._msgSender(),
            tokenAmount
        );
        emit Debug("withdraw");
    }
}
