// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AMM 自动做市商
//   添加流动性、移除流动性、交易、计算是否满足 K = x * y
contract MiniSwapPool {
    address token0;
    address token1;

    uint256 reserve0;
    uint256 reserve1;

    uint256 K ;

    // 添加流动性
    function addLiquidity(uint256 amount0, uint256 amount1) public {
        reserve0 = reserve0 + amount0;
        reserve1 = reserve1 + amount1;
        K = reserve0 * reserve1;
        // uint256 LP_amount = sqrt(amount0 * amount1);
        // 铸造 LP 代币
        // _mint(msg.sender, LP_amount)
    }

    // 移除流动性
    function removeLiquidity(uint256 LP_amount) public {
        // 流动性比例

        // 根据比例分配 具体的 token0和 token1 数量
        
        // 代币转移

        // 销毁 LP 代币
        // 
    }

    // 交易
    function swap(address _token, uint256 amount) public {
        // 假设购买 token0，那么 server1 = k / ( server0 + amount )

        // 更新 reserve0 和 reserve1

        // 代币转移
    }




}