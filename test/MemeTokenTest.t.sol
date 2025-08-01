// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import { memeProxy } from "../task/day16/memeProxy.sol";
import { memeToken } from "../task/day16/memeToken.sol";


contract MemeTokenTest is Test {
    memeToken public token;
    memeProxy public proxy;

    address projectOwner = makeAddr("alice");  // 项目方地址
    address memeCreator = makeAddr("bob");    // meme 第一次初始化地址，后面是铸造地址等同于 memecreator 转账 给铸造者
    address user = makeAddr("user");   // 铸造者 == 用户

    function setUp() public {
        vm.startPrank(projectOwner);
        proxy = new memeProxy();
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

        assertEq(memeToken(memeAddress).balanceOf(user), 10);  // 用户铸造 meme 币成功
        
        assertEq(user.balance, 0 ether);
        assertEq(address(proxy).balance - initialProjectBalance, 0.01 ether);
        assertEq(memeCreator.balance - initialCreatorBalance, 0.99 ether);

    }

}