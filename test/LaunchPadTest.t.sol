// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import { memeProxy } from "../task/day24/memeProxy.sol";
import { memeToken } from "../task/day24/memeToken.sol";
import { UniswapV2Router02 } from "../task/day24/UniswapV2Router02.sol";
import { UniswapV2Factory } from "../task/day24/UniswapV2Factory.sol";
import { WETH9 } from "../task/day24/WETH9.sol";
import { UniswapV2Library } from "../task/day24/libraries/UniswapV2Library.sol";

contract MemeTokenTest is Test {

    UniswapV2Router02 public router02;
    UniswapV2Factory public factory;
    WETH9 public weth;
    memeProxy public proxy;
    memeToken public token;

     
    address projectOwner = makeAddr("alice");  // 项目方地址
    address memeCreator = makeAddr("bob");    // meme 第一次初始化地址，后面是铸造地址等同于 memecreator 转账 给铸造者
    address user = makeAddr("user");   // 铸造者 == 用户


    function setUp() public {
        vm.startPrank(projectOwner);

        proxy = new memeProxy();
        
        factory = new UniswapV2Factory(address(proxy));
        weth = new WETH9();
        router02 = new UniswapV2Router02(address(factory), address(weth));

        vm.stopPrank();
        
    }

     // 测试部署
    function testMeme_Deploy() public {
        vm.startPrank(memeCreator);
        string memory symbol = "meme";
        uint256 maxSupply = 1000000;
        uint256 perMint = 10;
        uint256 totalPrice = 1 ether;
        address memeAddress = proxy.deployMeme(symbol, maxSupply, perMint, totalPrice);

        assertTrue(proxy.isMemeToken(memeAddress));
        assertEq(memeToken(memeAddress).creator(), memeCreator);
        assertEq(memeToken(memeAddress).maxSupply(), 1000000);
        assertEq(memeToken(memeAddress).perMint(), 10);
        assertEq(memeToken(memeAddress).price(), 1 ether);
        vm.stopPrank();
    }

    // 测试铸造
    function testMeme_Mint() public {
        uint256 initialProjectBalance = projectOwner.balance;
        uint256 initialCreatorBalance = memeCreator.balance;
        vm.deal(user, 1 ether);

        vm.startPrank(memeCreator);
        string memory symbol = "meme";
        uint256 maxSupply = 1000000;
        uint256 perMint = 10;
        uint256 totalPrice = 1 ether;
        address memeAddress = proxy.deployMeme(symbol, maxSupply, perMint, totalPrice);
        vm.stopPrank();

        vm.startPrank(user);
        proxy.mint{value: 1 ether}(memeAddress);
        vm.stopPrank();

        assertEq(memeToken(memeAddress).balanceOf(user), 9);  // 用户铸造 meme 币成功
        
        assertEq(user.balance, 0 ether);
        assertEq(address(proxy).balance - initialProjectBalance, 0.1 ether);
        assertEq(memeCreator.balance - initialCreatorBalance, 0.9 ether);

    }

    // 添加流动性
    function test_addLiquidity() public {
        uint256 initialProjectBalance = projectOwner.balance;
        uint256 initialCreatorBalance = memeCreator.balance;
        vm.deal(user, 1 ether);

        vm.startPrank(memeCreator);
        string memory symbol = "meme";
        uint256 maxSupply = 1000000;
        uint256 perMint = 10;
        uint256 totalPrice = 1 ether;
        address memeAddress = proxy.deployMeme(symbol, maxSupply, perMint, totalPrice);
        vm.stopPrank();

        vm.startPrank(user);
        proxy.mint{value: 1 ether}(memeAddress);
        vm.stopPrank();

        assertEq(memeToken(memeAddress).balanceOf(user), 9);  // 铸造 meme 用户 90% 的手续费和获得 9个 meme 代币
        assertEq(memeToken(memeAddress).balanceOf(address(proxy)), 1);  // 没有添加流动性前，项目方拥有 10% 的手续费和 1个 meme 代币

        // -----------------------添加流动性---------------------------------
        proxy._AddLiquidity(payable(address(router02)), memeAddress, 0.1 ether);

        // 检查
        assertEq(memeToken(memeAddress).balanceOf(user), 9);  // 铸造 meme 用户 获得 meme 代币数量
        assertEq(memeToken(memeAddress).balanceOf(address(proxy)), 0);  // 项目方代币被用于添加流动性了
        assertEq(address(weth).balance, 0.1 ether);  // eth 转变为 weth
        // weth代币已有 pair 合约地址存款
        // token 代币已有 pair 合约地址存款
        // 流动性Lp 数量正确    


    }

     // 添加流动性
    function test_swapLiquidity() public {
        uint256 initialProjectBalance = projectOwner.balance;
        uint256 initialCreatorBalance = memeCreator.balance;
        vm.deal(user, 1 ether);

        vm.startPrank(memeCreator);
        string memory symbol = "meme";
        uint256 maxSupply = 1000000;
        uint256 perMint = 10;
        uint256 totalPrice = 1 ether;
        address memeAddress = proxy.deployMeme(symbol, maxSupply, perMint, totalPrice);
        vm.stopPrank();

        vm.startPrank(user);
        proxy.mint{value: 1 ether}(memeAddress);
        vm.stopPrank();

        assertEq(memeToken(memeAddress).balanceOf(user), 9);  // 铸造 meme 用户 90% 的手续费和获得 9个 meme 代币
        assertEq(memeToken(memeAddress).balanceOf(address(proxy)), 1);  // 没有添加流动性前，项目方拥有 10% 的手续费和 1个 meme 代币

        // -----------------------添加流动性---------------------------------
        proxy._AddLiquidity(payable(address(router02)), memeAddress, 0.1 ether);
        // 检查
        assertEq(memeToken(memeAddress).balanceOf(user), 9);  // 铸造 meme 用户 获得 meme 代币数量
        assertEq(memeToken(memeAddress).balanceOf(address(proxy)), 0);  // 项目方代币被用于添加流动性了
        assertEq(address(weth).balance, 0.1 ether);  // eth 转变为 weth
        // weth代币已有 pair 合约地址存款
        // token 代币已有 pair 合约地址存款
        // 流动性Lp 数量正确  


        // ---------------------Token兑换ETH-----------------------------------
        // 用户用token兑换ETH
        vm.startPrank(user);
        
        // 记录用户兑换前的余额
        uint256 userTokenBalanceBefore = memeToken(memeAddress).balanceOf(user);
        uint256 userEthBalanceBefore = user.balance;
        
        console.log("User token balance before swap:", userTokenBalanceBefore);
        console.log("User ETH balance before swap:", userEthBalanceBefore);
        
        // 设置兑换参数
        uint256 tokenAmountToSwap = 5; // 兑换5个token
        uint256 minEthOut = 0.05 ether; // 最少获得0.05 ETH
                
        // 授权Router使用用户的token
        memeToken(memeAddress).approve(address(router02), tokenAmountToSwap);
        
        // 设置兑换路径：token -> WETH -> ETH
        address[] memory path = new address[](2);
        path[0] = memeAddress;  // token地址
        path[1] = address(weth); // WETH地址
        
        // 计算预期获得的ETH数量
        uint256[] memory amounts = router02.getAmountsOut(tokenAmountToSwap, path);
        uint256 expectedEthOut = amounts[1];
        
        console.log("Token amount to swap:", tokenAmountToSwap);
        console.log("Expected ETH output:", expectedEthOut);
        console.log("Minimum ETH output:", minEthOut);
        
        // 执行token兑换ETH
        router02.swapExactTokensForETH(
            tokenAmountToSwap,
            minEthOut,
            path,
            user,
            block.timestamp + 300
        );
        
        // 记录用户兑换后的余额
        uint256 userTokenBalanceAfter = memeToken(memeAddress).balanceOf(user);
        uint256 userEthBalanceAfter = user.balance;
        
        console.log("User token balance after swap:", userTokenBalanceAfter);
        console.log("User ETH balance after swap:", userEthBalanceAfter);
        
        // 验证兑换结果
        assertEq(userTokenBalanceAfter, userTokenBalanceBefore - tokenAmountToSwap, "Token balance should decrease");
        assertTrue(userEthBalanceAfter > userEthBalanceBefore, "ETH balance should increase");
        
        console.log("Token to ETH swap successful!");
        vm.stopPrank();  

    }

}