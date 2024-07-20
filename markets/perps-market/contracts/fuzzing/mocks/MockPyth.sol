// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.11 <0.9.0;

contract MockPyth {
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint256 publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }

    error InsufficientFee();

    mapping(bytes32 => PriceFeed[]) priceFeeds;
    bytes32[] activeFeeds;
    uint256 requiredFee;

    function addPriceFeed(
        bytes32 id,
        int64 startingPrice,
        uint64 startingConf,
        int32 startingExpo
    ) external {
        priceFeeds[id].push(
            PriceFeed({
                id: id,
                price: Price({
                    price: startingPrice,
                    conf: startingConf,
                    expo: startingExpo,
                    publishTime: block.timestamp
                }),
                emaPrice: Price({
                    price: startingPrice,
                    conf: startingConf,
                    expo: startingExpo,
                    publishTime: block.timestamp
                })
            })
        );
        activeFeeds.push(id);
    }

    function setRequiredFee(uint256 newFee) external {
        requiredFee = newFee;
    }

    function changePrice(bytes32 id, int64 newPrice) external {
        priceFeeds[id][0].price.price = newPrice;
        priceFeeds[id][0].price.publishTime = block.timestamp;
    }

    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PriceFeed[] memory feeds) {
        if (msg.value < requiredFee) revert InsufficientFee();

        return priceFeeds[priceIds[0]];
    }

    function getCurrentPrice(bytes32 id) external returns (int64) {
        return priceFeeds[id][0].price.price;
    }
}
