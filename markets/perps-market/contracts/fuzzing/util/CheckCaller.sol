pragma solidity ^0.8.0;
import {console2} from "lib/forge-std/src/Test.sol";

contract CheckCaller {
    function checkCaller() public returns (address) {
        console2.log("CheckCaller::msg.sender", msg.sender);
        console2.log("CheckCaller::tx.origin", tx.origin);

        return msg.sender;
    }
}
