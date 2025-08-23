// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {LaunchPadTWAP} from "../task/day25/LaunchPadTWAP.sol";
import { Token } from "../task/day25/Token.sol";
import { UniswapV2Router02 } from "../task/day24/UniswapV2Router02.sol";
import { UniswapV2Factory } from "../task/day24/UniswapV2Factory.sol";
import { WETH9 } from "../task/day24/WETH9.sol";
import { FlashSwap } from "../task/day25/FlashSwap.sol";
import { UniswapV2Library } from "../task/day24/libraries/UniswapV2Library.sol";

contract FlashSwapTest is Test {
    
    LaunchPadTWAP public twapContract;
    UniswapV2Factory public factory;
    UniswapV2Router02 public router02;
    WETH9 public weth;
    Token public token;

    LaunchPadTWAP public twapContract2;
    UniswapV2Factory public factory2;
    UniswapV2Router02 public router022;
    WETH9 public weth2;
    Token public token2;
    
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

        factory2 = new UniswapV2Factory(owner);
        router022 = new UniswapV2Router02(address(factory2), address(weth));

        
        token.mint(user1, INITIAL_SUPPLY / 3);
        token.mint(user2, INITIAL_SUPPLY / 3);
        token.mint(user3, INITIAL_SUPPLY / 3);
        
        vm.deal(user1, INITIAL_ETH);
        vm.deal(user2, INITIAL_ETH);
        vm.deal(user3, INITIAL_ETH);
        
    }

    // 期望获得 weth
    function test_FlashSwap() public {

        // router02 创建池子
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

        // router022 创建池子
        vm.startPrank(user2);
        token.approve(address(router022), type(uint256).max);
        weth.approve(address(router022), type(uint256).max);
        router022.addLiquidityETH{value: 20 ether}(
            address(token),
            10 * 10**18,  // 期望token
            9.5 * 10**18,   // 最低 token
            10 ether,  // 最低 ETH
            user2,
            block.timestamp + 1 hours
        );
        vm.stopPrank();

        // 创建flashSwap(factory2,router022)合约
        FlashSwap flashSwap = new FlashSwap(
            UniswapV2Library.pairFor(address(factory2), address(token), address(weth)), 
            address(factory2), 
            address(router022)
        );

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        uint amountRequired;
        amountRequired = UniswapV2Library.getAmountsIn(address(factory), 1 * 10**18, path)[0];
        // flashSwap - 借出WETH而不是Token
        flashSwap.flashSwap(
            UniswapV2Library.pairFor(address(factory), address(token), address(weth)), 
            address(token), 
            amountRequired
        );
    }

    // 期望获得 token
    function test_FlashSwap2() public {

        // router02 创建池子
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

        // router022 创建池子
        vm.startPrank(user2);
        token.approve(address(router022), type(uint256).max);
        weth.approve(address(router022), type(uint256).max);
        router022.addLiquidityETH{value: 5 ether}(
            address(token),
            10 * 10**18,  // 期望token
            9.5 * 10**18,   // 最低 token
            2 ether,  // 最低 ETH
            user2,
            block.timestamp + 1 hours
        );
        vm.stopPrank();

        // 创建flashSwap(factory2,router022)合约
        FlashSwap flashSwap = new FlashSwap(
            UniswapV2Library.pairFor(address(factory2), address(token), address(weth)), 
            address(factory2), 
            address(router022)
        );

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(token);
        uint amountRequired;
        amountRequired = UniswapV2Library.getAmountsIn(address(factory), 1 * 10**18, path)[0];  // 欠pair多少个token
        // flashSwap - 借出WETH而不是Token
        flashSwap.flashSwap(
            UniswapV2Library.pairFor(address(factory), address(token), address(weth)), 
            address(weth), 
            amountRequired
        );
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
