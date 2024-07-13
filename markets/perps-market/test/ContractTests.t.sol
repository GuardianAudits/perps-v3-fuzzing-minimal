pragma solidity ^0.8.0;

import "./Contract.sol";
import "forge-std/Test.sol";

contract ContractTests is Test {
    Contract con;
    function setUp() {
        con = new Contract();
    }
    function test_setX() external {
        vm.startPrank(address(0x1000));
        con.setX(1);
    }

    function test_me() external {
        assert(false);
    }
}
