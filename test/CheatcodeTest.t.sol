// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {Owner} from "../src/Owner.sol";
import {MyToken} from "../src/MyToken.sol";

contract CheatcodeTest is Test {
    Counter public counter;
    address public alice;
    address public bob;

    function setUp() public {
        counter = new Counter();
        alice = makeAddr("alice");  // makeAddr 是一个由 ​**forge-std/Test.sol​ 提供的实用方法，用于生成一个确定性（固定）的以太坊地址**，并自动分配初始 ETH 余额（默认为 100 ETH）
        bob = makeAddr("bob");
        // console.log("New Counter instance:", address(counter));
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    // 设置区块号
    function test_Roll() public {
        counter.increment();
        assertEq(counter.number(), 1);

        uint256 newBlockNumber = 100;
        vm.roll(newBlockNumber); 
        console.log("after roll Block number", block.number);

        // 判断当前区块号是否等于设定号，等于就跳过，不等于就抛出异常
        assertEq(block.number, newBlockNumber);
        assertEq(counter.number(), 1);
    }


    // 设置时间戳
    function test_Warp() public {
        uint256 newTimestamp = 1753207525;   // 2025-07-23 02:05:25
        vm.warp(newTimestamp);
        console.log("after warp Block timestamp", block.timestamp);
        assertEq(block.timestamp, newTimestamp);

        skip(1000);  // 时间加1000秒
        console.log("after skip Block timestamp", block.timestamp);
        assertEq(block.timestamp, newTimestamp + 1000);
    }

    // 更换msg.sender
    function test_Prank() public {
        console.log("current contract address", address(this));
        console.log("test_Prank  counter address", address(counter));

        Owner o = new Owner();
        console.log("owner address", address(o.owner()));  // 在 Solidity 中，如果你定义了一个 public 状态变量（如 address public owner），​编译器会自动生成一个同名的 getter 函数。所以即使你没有显式定义 owner() 方法，仍然可以调用 o.owner()！
        assertEq(o.owner(), address(this));  // 注意Owner构造函数，就会指定为什么相等了

        console.log("alice address", alice);
        vm.prank(alice);
        Owner o2 = new Owner();
        assertEq(o2.owner(), alice);
    }

    // 更好msg.sender并设置作用域
    function test_StartPrank() public {
        console.log("current contract address", address(this));
        console.log("test_StartPrank  counter address", address(counter));

        Owner o = new Owner();
        console.log("owner address", address(o.owner()));
        assertEq(o.owner(), address(this));

        vm.startPrank(alice);
        Owner o2 = new Owner();
        assertEq(o2.owner(), alice);


        Owner o4 = new Owner();
        assertEq(o4.owner(), alice);

        vm.stopPrank();

        Owner o3 = new Owner();
        assertEq(o3.owner(), address(this));
    }

    //  重置余额
    function test_Deal() public {
        vm.deal(alice, 100 ether);
        assertEq(alice.balance, 100 ether);

        vm.deal(alice, 1 ether); 
        assertEq(alice.balance, 1 ether);
    }

    // 重置ERC20余额
    function test_Deal_ERC20() public {
        MyToken token = new MyToken("OpenSpace S7", "OS6");
        console.log("token address", address(token));

        console.log("alice address", alice);

        // 1 token = 10 ^ 18 
        deal(address(token), alice, 100e18);  // StdCheats.deal

        console.log("alice token balance", token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 100 ether);
    }

    // forge test test/Cheatcode.t.sol --mt test_Revert_IFNOT_Owner -vv
    // 断言合约执行错误：vm.expectRevert() / expectRevert(bytes4 revertData) / expectRevert(bytes calldata revertData)
    function test_Revert_IFNOT_Owner() public {
        
        vm.startPrank(alice);
        Owner o = new Owner();
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Only the owner can transfer ownership"); // 预期下一条语句会revert,这样这条数据触发
        o.transferOwnership(alice);
        vm.stopPrank();

    }

    function test_Revert_IFNOT_Owner2() public {
        vm.startPrank(alice);
        Owner o = new Owner();
        vm.stopPrank();

        vm.startPrank(bob);
        bytes memory data = abi.encodeWithSignature("NotOwner(address)", bob);
        vm.expectRevert(data); // 预期下一条语句会revert
        o.transferOwnership2(alice);
        vm.stopPrank();
    }

    event OwnerTransfer(address indexed caller, address indexed newOwner);
    function test_Emit() public {
        Owner o = new Owner();

        // function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;
        vm.expectEmit(true, true, false, false);
        emit OwnerTransfer(address(this), bob);

        o.transferOwnership(bob);
    }

}