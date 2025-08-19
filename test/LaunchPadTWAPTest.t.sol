// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {LaunchPadTWAP} from "../task/day25/LaunchPadTWAP.sol";
// import { memeToken } from "../task/day24/memeToken.sol";
import { Token } from "../task/day25/Token.sol";
import { UniswapV2Router02 } from "../task/day24/UniswapV2Router02.sol";
import { UniswapV2Factory } from "../task/day24/UniswapV2Factory.sol";
import { WETH9 } from "../task/day24/WETH9.sol";
// import { UniswapV2Library } from "../task/day24/libraries/UniswapV2Library.sol";

contract LaunchPadTWAPTest is Test {
    
    LaunchPadTWAP public twapContract;
    UniswapV2Factory public factory;
    UniswapV2Router02 public router02;
    WETH9 public weth;
    Token public token;
    
    address owner = makeAddr("owner");
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    
    uint256 public constant INITIAL_SUPPLY = 30 * 10**18;
    uint256 public constant INITIAL_ETH = 30 ether;
    
    function setUp() public {
        weth = new WETH9();
        factory = new UniswapV2Factory(owner);
        router02 = new UniswapV2Router02(address(factory), address(weth));
        token = new Token("meme", "meme");
        twapContract = new LaunchPadTWAP();
        
        token.mint(user1, INITIAL_SUPPLY / 3);
        token.mint(user2, INITIAL_SUPPLY / 3);
        token.mint(user3, INITIAL_SUPPLY / 3);
        
        vm.deal(user1, INITIAL_ETH);
        vm.deal(user2, INITIAL_ETH);
        vm.deal(user3, INITIAL_ETH);
        
        // vm.startPrank(user1);
        // weth.deposit{value: INITIAL_ETH}();
        // vm.stopPrank();
        
        // vm.startPrank(user2);
        // weth.deposit{value: INITIAL_ETH}();
        // vm.stopPrank();
        
        // vm.startPrank(user3);
        // weth.deposit{value: INITIAL_ETH}();
        // vm.stopPrank();
    }
    
    // 计算TWAP价格
    function test_TWAPPriceCalculation() public {
        
        // 添加流动性
        vm.startPrank(user1);
        token.approve(address(router02), type(uint256).max);
        weth.approve(address(router02), type(uint256).max);
        router02.addLiquidityETH{value: 10 ether}(
            address(token),
            10 * 10**18,  // 期望token
            9.5 * 10**18,   // 最低 token
            9.5 ether,  // 最低 ETH
            user1,
            block.timestamp + 1 hours 
        );
        vm.stopPrank();

        // 更新价格观察数据
        address pair = factory.getPair(address(token), address(weth));
        twapContract.updatePriceObservation(pair);
        vm.warp(block.timestamp + 1 hours);
        
        // 兑换Token
        vm.startPrank(user2);
        token.approve(address(router02), type(uint256).max);
        weth.approve(address(router02), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(token);
        uint256[] memory amounts = router02.swapExactETHForTokens{value: 1 ether}(
            0,
            path,
            user2,
            block.timestamp + 1 hours  // 交易截止时间
        );
        vm.stopPrank();
        
        // 计算TWAP价格
        (uint256 twapPrice0, uint256 twapPrice1) = twapContract.calculateTWAP(pair, 1 hours);
        
        // 检查
        assertGt(twapPrice0, 0);
        assertGt(twapPrice1, 0);
    }
    
    function test_MultipleTradesOverTime() public {
        
        // 添加流动性
        vm.startPrank(user1);
        token.approve(address(router02), type(uint256).max);
        weth.approve(address(router02), type(uint256).max);
        router02.addLiquidityETH{value: 10 ether}(
            address(token),
            10 * 10**18,  // 期望token
            9.5 * 10**18,   // 最低 token
            9.5 ether,  // 最低 ETH
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();

        // 更新价格观察数据
        address pair = factory.getPair(address(token), address(weth));
        twapContract.updatePriceObservation(pair);
        uint256[] memory timestamps = new uint256[](4);
        timestamps[0] = block.timestamp + 1 hours;
        timestamps[1] = block.timestamp + 2 hours;
        timestamps[2] = block.timestamp + 4 hours;
        timestamps[3] = block.timestamp + 6 hours;
        
        for (uint256 i = 0; i < timestamps.length; i++) {
            vm.warp(timestamps[i]);
            
            address trader = i % 2 == 0 ? user2 : user3;
            vm.startPrank(trader);
            
            token.approve(address(router02), type(uint256).max);
            weth.approve(address(router02), type(uint256).max);
            
            if (i % 2 == 0) {
                address[] memory path = new address[](2);
                path[0] = address(weth);
                path[1] = address(token);
                
                router02.swapExactETHForTokens{value: 0.5 ether}(
                    0,
                    path,
                    trader,
                    block.timestamp + 1 hours
                );
            } else {
                address[] memory path = new address[](2);
                path[0] = address(token);
                path[1] = address(weth);
                
                uint256 tokenAmount = token.balanceOf(trader) / 10;
                
                router02.swapExactTokensForETH(
                    tokenAmount,
                    0,
                    path,
                    trader,
                    block.timestamp + 1 hours
                );
            }
            
            vm.stopPrank();
            
            // 第一次更新
            if(i == 0){
                twapContract.updatePriceObservation(pair);
            }
            
            if (i > 0) {
                uint32 period = uint32(timestamps[i] - timestamps[0]);
                (uint256 twapPrice0, uint256 twapPrice1) = twapContract.calculateTWAP(pair, period);
                console.log("i: ", i );
                console.log("twapPrice0", twapPrice0);
                console.log("twapPrice1", twapPrice1);
                assertGt(twapPrice0, 0);
                assertGt(twapPrice1, 0);
            }
        }
    }
    
    // function test_GetTokenTWAP() public {
    //     address pair = factory.createPair(address(memeToken), address(weth));
        
    //     vm.startPrank(user1);
    //     memeToken.approve(address(router), type(uint256).max);
    //     weth.approve(address(router), type(uint256).max);
        
    //     router.addLiquidityETH{value: 10 ether}(
    //         address(memeToken),
    //         10000 * 10**18,
    //         9500 * 10**18,
    //         9.5 ether,
    //         user1,
    //         block.timestamp + 1 hours
    //     );
    //     vm.stopPrank();
        
    //     twapContract.updatePriceObservation(pair);
        
    //     vm.warp(block.timestamp + 2 hours);
        
    //     vm.startPrank(user2);
    //     memeToken.approve(address(router), type(uint256).max);
    //     weth.approve(address(router), type(uint256).max);
        
    //     address[] memory path = new address[](2);
    //     path[0] = address(weth);
    //     path[1] = address(memeToken);
        
    //     router.swapExactETHForTokens{value: 2 ether}(
    //         0,
    //         path,
    //         user2,
    //         block.timestamp + 1 hours
    //     );
    //     vm.stopPrank();
        
    //     twapContract.updatePriceObservation(pair);
        
    //     uint256 memeTokenTWAP = twapContract.getTokenTWAP(pair, address(memeToken), 2 hours);
    //     uint256 wethTWAP = twapContract.getTokenTWAP(pair, address(weth), 2 hours);
        
    //     assertGt(memeTokenTWAP, 0);
    //     assertGt(wethTWAP, 0);
    // }
    
    // function test_RevertOnInvalidPair() public {
    //     vm.expectRevert("Invalid pair address");
    //     twapContract.updatePriceObservation(address(0));
    // }
    
    // function test_RevertOnInsufficientTime() public {
    //     address pair = factory.createPair(address(memeToken), address(weth));
        
    //     twapContract.updatePriceObservation(pair);
        
    //     vm.expectRevert("Insufficient time elapsed");
    //     twapContract.calculateTWAP(pair, 1 hours);
    // }
    
    // function test_RevertOnUninitializedObservation() public {
    //     address pair = factory.createPair(address(memeToken), address(weth));
        
    //     vm.expectRevert("Price observation not initialized");
    //     twapContract.calculateTWAP(pair, 1 hours);
    // }
    
    // function test_BatchUpdatePriceObservations() public {
    //     address pair1 = factory.createPair(address(memeToken), address(weth));
        
    //     vm.startPrank(user1);
    //     memeToken.approve(address(router), type(uint256).max);
    //     weth.approve(address(router), type(uint256).max);
        
    //     router.addLiquidityETH{value: 10 ether}(
    //         address(memeToken),
    //         10000 * 10**18,
    //         9500 * 10**18,
    //         9.5 ether,
    //         user1,
    //         block.timestamp + 1 hours
    //     );
    //     vm.stopPrank();
        
    //     address[] memory pairs = new address[](1);
    //     pairs[0] = pair1;
        
    //     twapContract.batchUpdatePriceObservations(pairs);
        
    //     (
    //         uint256 price0CumulativeLast,
    //         uint256 price1CumulativeLast,
    //         uint32 blockTimestampLast,
    //         bool initialized
    //     ) = twapContract.getPriceObservation(pair1);
        
    //     assertTrue(initialized);
    //     assertGt(price0CumulativeLast, 0);
    //     assertGt(price1CumulativeLast, 0);
    //     assertGt(blockTimestampLast, 0);
    // }
}
