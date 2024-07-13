pragma solidity ^0.8.0;

contract Contract {
    uint x;

    function setX(uint _newX) public {
        require(msg.sender == address(0x1000), "only user 1");
        x = _newX;
    }
}
