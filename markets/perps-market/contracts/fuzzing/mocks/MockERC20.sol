// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.11 <0.9.0;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console2} from "lib/forge-std/src/Test.sol";

contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 dec
    ) ERC20(name, symbol) {
        _decimals = dec;
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
        console2.log("msg.sender", msg.sender);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
