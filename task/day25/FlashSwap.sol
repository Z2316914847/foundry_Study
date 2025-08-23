// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../day24/interfaces/IUniswapV2Callee.sol';

import '../day24/libraries/UniswapV2Library.sol';
import '../day24/interfaces/IUniswapV2Router02.sol';
import '../day24/interfaces/IERC20.sol';
import '../day24/interfaces/IWETH.sol';
import { console } from "forge-std/Test.sol";


contract FlashSwap is IUniswapV2Callee {
    
    address immutable factory;
    address immutable router2;
    address immutable owner;
    address immutable pair2;

    constructor(address _pair, address _factory, address _router2) public {
        pair2 = _pair;
        factory = _factory;
        router2 = _router2;
        owner = msg.sender;
    }

    // 用户主动调用该函数，去pair池子贷款
    // 参数：pair: 贷款池子合约地址，borrowToken: 贷款池子代币地址，borrowAmount: 借出的代币数量, 并没有说借出的代币地址一定要为borrowToken
    function flashSwap(address pair, address borrowToken, uint256 borrowAmount) external {
        address token0 = IUniswapV2Pair(pair).token0();  // token0=weth, token1=token
        bytes memory data = abi.encode(borrowToken, borrowAmount);

        if(token0 == borrowToken) {
            IUniswapV2Pair(pair).swap(1e18, 0, address(this), data);   // 你期望获得weth
        } else {
            IUniswapV2Pair(pair).swap(0, 1e18, address(this), data);  // 你期望获得token
        }
    }


    // 参数：sender: pair1合约地址，amount0: 期望获得的token0数量，amount1: 期望获得token1数量，data: 数据
    // uniswap回调这个函数，必须由pair调用
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        (address borrowToken, uint256 borrowAmount) = abi.decode(data, (address, uint256));
        require(amount0 == 0 || amount1 == 0, "invalid amounts"); 
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(pair2 == UniswapV2Library.pairFor(factory, token0, token1), "invalid caller"); 

        // 闪电贷，只有其中一方有余额(2e18)，另一方没有余额
        uint balance0 = IERC20(token0).balanceOf(address(this)); 
        uint balance1 = IERC20(token1).balanceOf(address(this));
        console.log("balance0", balance0);
        console.log("balance1", balance1);
        console.log("borrowAmount", borrowAmount);

        address[] memory path = new address[](2);
        uint amountRequired ;   // 从2池兑换这些代币，需要多少另一个代币数量
        // 收到了 token0,  兑换为 token1
        if (balance0 > 0) {
            path[0] = token0;
            path[1] = token1;
            IERC20(token0).approve(router2, type(uint256).max);
            uint[] memory amounts = IUniswapV2Router02(router2).swapExactTokensForTokens(balance0, 0, path, address(this), block.timestamp);
            uint amountReceived = amounts[1];  //实际从池子获得的代币数量
            console.log("amountReceived", amountReceived);

            require(amountReceived > borrowAmount, "un profitable 1");  // 如果实际获得的代币数量大于期望的代币数量，则交易成功，说明由套利机会
            assert(IERC20(token1).transfer(msg.sender, borrowAmount));   // 将借贷的币还给池子
            IERC20(token1).transfer(owner, amountReceived - borrowAmount);   // 将套利获得的代币转给owner

            console.log("owner balance", IERC20(token0).balanceOf(owner));
        }

        // 收到了 token1, 兑换为 token0
        if (balance1 > 0) {
            path[0] = token1;
            path[1] = token0;
            IERC20(token1).approve(router2, type(uint256).max);
            uint[] memory amounts = IUniswapV2Router02(router2).swapExactTokensForTokens(balance1, 0, path, address(this), block.timestamp);
            uint amountReceived = amounts[1];  // 计算balance1能兑换多少另一个代币的数量

            require(amountReceived > borrowAmount, "unprofitable");
            require(IERC20(token0).transfer(msg.sender, borrowAmount)); 
            IERC20(token0).transfer(owner, amountReceived - borrowAmount); 

            console.log("owner balance", IERC20(token0).balanceOf(owner));
        }

    }
}