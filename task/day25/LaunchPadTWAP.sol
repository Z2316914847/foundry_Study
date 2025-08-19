// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../day24/interfaces/IUniswapV2Pair.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LaunchPadTWAP
 * @dev 获取 LaunchPad 发行的 Meme 代币的 TWAP 价格
 * TWAP (Time-Weighted Average Price) 时间加权平均价格
 */
contract LaunchPadTWAP {
    
    // 存储价格累积值和时间戳的映射
    // pair => (price0CumulativeLast, price1CumulativeLast, blockTimestampLast)
    mapping(address => PriceObservation) public priceObservations;
    
    // 价格观察结构体
    struct PriceObservation {
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        uint32 blockTimestampLast;
        bool initialized;
    }
    
    // 事件：价格更新
    event PriceUpdated(
        address indexed pair,
        uint256 price0Cumulative,
        uint256 price1Cumulative,
        uint32 timestamp
    );
    
    // 事件：TWAP 价格计算
    event TWAPCalculated(
        address indexed pair,
        address token0,
        address token1,
        uint256 twapPrice0,
        uint256 twapPrice1,
        uint32 timeElapsed
    );
    
    /**
     * @dev 更新价格观察数据
     * @param pair Uniswap V2 交易对地址
     */
    function updatePriceObservation(address pair) external {
        require(pair != address(0), "Invalid pair address");
        
        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);
        
        // 获取当前储备量和时间戳
        (,, uint32 blockTimestampLast) = pairContract.getReserves();
        
        // 获取价格累积值
        uint256 price0CumulativeLast = pairContract.price0CumulativeLast();
        uint256 price1CumulativeLast = pairContract.price1CumulativeLast();
        
        // 更新价格观察数据
        priceObservations[pair] = PriceObservation({
            price0CumulativeLast: price0CumulativeLast,
            price1CumulativeLast: price1CumulativeLast,
            blockTimestampLast: blockTimestampLast,
            initialized: true
        });
        
        emit PriceUpdated(pair, price0CumulativeLast, price1CumulativeLast, blockTimestampLast);
    }
    
    /**
     * @dev 计算 TWAP 价格
     * @param pair Uniswap V2 交易对地址
     * @param period 时间周期（秒）
     * @return twapPrice0 token0 相对于 token1 的 TWAP 价格
     * @return twapPrice1 token1 相对于 token0 的 TWAP 价格
     */
    // 两部：获取价格 -》 计算TWAP
    function calculateTWAP(address pair, uint32 period) external returns (uint256 twapPrice0, uint256 twapPrice1) {
        require(pair != address(0), "Invalid pair address");
        require(period > 0, "Period must be greater than 0");

        // 检查是否有足够的历史数据
        PriceObservation storage observation = priceObservations[pair];
        require(observation.initialized, "Price observation not initialized");
        
        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);
        
        // 获取当前储备量和时间戳
        (,, uint32 blockTimestampLast) = pairContract.getReserves();
        
        // 获取当前价格累积值
        uint256 price0CumulativeLast = pairContract.price0CumulativeLast();
        uint256 price1CumulativeLast = pairContract.price1CumulativeLast();
        
        // 计算时间差
        uint32 timeElapsed = blockTimestampLast - observation.blockTimestampLast;
        require(timeElapsed >= period, "Insufficient time elapsed");
        
        // 计算 TWAP 价格
        // TWAP = (priceCumulative2 - priceCumulative1) / (time2 - time1)
        twapPrice0 = (price0CumulativeLast - observation.price0CumulativeLast) / timeElapsed;
        twapPrice1 = (price1CumulativeLast - observation.price1CumulativeLast) / timeElapsed;
        
        // 更新价格观察数据
        // observation.price0CumulativeLast = price0CumulativeLast;
        // observation.price1CumulativeLast = price1CumulativeLast;
        // observation.blockTimestampLast = blockTimestampLast;
        
        emit TWAPCalculated(
            pair,
            pairContract.token0(),
            pairContract.token1(),
            twapPrice0,
            twapPrice1,
            timeElapsed
        );
    }
    
    /**
     * @dev 获取指定代币相对于 WETH 的 TWAP 价格
     * @param pair Uniswap V2 交易对地址
     * @param token 目标代币地址
     * @param period 时间周期（秒）
     * @return twapPrice 代币相对于 WETH 的 TWAP 价格
     */
    function getTokenTWAP(address pair, address token, uint32 period) external returns (uint256 twapPrice) {
        require(pair != address(0), "Invalid pair address");
        require(token != address(0), "Invalid token address");
        
        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);
        address token0 = pairContract.token0();
        address token1 = pairContract.token1();
        
        require(token == token0 || token == token1, "Token not in pair");
        
        (uint256 twapPrice0, uint256 twapPrice1) = this.calculateTWAP(pair, period);
        
        if (token == token0) {
            twapPrice = twapPrice0;
        } else {
            twapPrice = twapPrice1;
        }
    }
    
    /**
     * @dev 批量更新多个交易对的价格观察数据
     * @param pairs 交易对地址数组
     */
    function batchUpdatePriceObservations(address[] calldata pairs) external {
        for (uint256 i = 0; i < pairs.length; i++) {
            if (pairs[i] != address(0)) {
                this.updatePriceObservation(pairs[i]);
            }
        }
    }
    
    /**
     * @dev 获取价格观察数据
     * @param pair 交易对地址
     * @return price0CumulativeLast token0 价格累积值
     * @return price1CumulativeLast token1 价格累积值
     * @return blockTimestampLast 最后更新时间戳
     * @return initialized 是否已初始化
     */
    function getPriceObservation(address pair) external view returns (
        uint256 price0CumulativeLast,
        uint256 price1CumulativeLast,
        uint32 blockTimestampLast,
        bool initialized
    ) {
        PriceObservation storage observation = priceObservations[pair];
        return (
            observation.price0CumulativeLast,
            observation.price1CumulativeLast,
            observation.blockTimestampLast,
            observation.initialized
        );
    }
}
