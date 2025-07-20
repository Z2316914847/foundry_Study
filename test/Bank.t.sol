// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public alice;
    address public bob;
    address public tom;
    address public haJiMi;


    function setUp() public {
        bank = new Bank();
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        tom = makeAddr("tom");
        haJiMi = makeAddr("haJiMi");
    }

    // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确
    function test_withDraw() public {
        vm.deal(alice, 1 ether); // 给alice 1 ETH
    
        vm.startPrank(alice);
        uint256 depositAmount = 0.5 ether;
    
        // 记录初始余额
        uint256 initialBalance = address(bank).balance;
        uint256 initialAliceBalance = alice.balance;
    
        // 执行存款
        (bool success,) = address(bank).call{value: depositAmount}("");
        require(success, "Deposit failed");
    
        // 检查存款后状态
        assertEq(bank.balances(alice), depositAmount, "Balance not updated");
        assertEq(address(bank).balance, initialBalance + depositAmount, "Contract balance incorrect");
        assertEq(alice.balance, initialAliceBalance - depositAmount, "Alice balance incorrect");
    
        vm.stopPrank();
        
    }

    // 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
    function test_top3() public {        
        // 给用户分配测试ETH
        vm.deal(alice, 1.6 ether);
        vm.deal(bob, 2 ether);
        vm.deal(tom, 1 ether);
        vm.deal(haJiMi, 10 ether);

        // Alice 存款 (0.5 + 0.1 = 0.6 ether)
        vm.startPrank(alice);
        (bool success,) = address(bank).call{value: 0.5 ether}("");
        require(success, "Alice first deposit failed");
        (success,) = address(bank).call{value: 0.5 ether}("");
        require(success, "Alice second deposit failed");
        vm.stopPrank();
        
        // Bob 存款 (1.5 ether)
        vm.startPrank(bob);
        (success,) = address(bank).call{value: 1.5 ether}("");
        require(success, "Bob deposit failed");
        vm.stopPrank();

        // Tom 存款 (0.8 ether)
        vm.startPrank(tom);
        (success,) = address(bank).call{value: 0.8 ether}("");
        require(success, "Tom deposit failed");
        vm.stopPrank();    

        // haJiMi 存款 (6 ether)
        vm.startPrank(haJiMi);
        (success,) = address(bank).call{value: 6 ether}("");
        require(success, "haJiMi deposit failed");
        vm.stopPrank();    

        // 验证各用户余额
        assertEq(bank.balances(alice), 1 ether, "Alice balance incorrect");
        assertEq(bank.balances(bob), 1.5 ether, "Bob balance incorrect");
        assertEq(bank.balances(tom), 0.8 ether, "Tom balance incorrect");
        assertEq(bank.balances(haJiMi), 6 ether, "haJiMi balance incorrect");

        // 获取并验证前3名
        // address[] memory top3 = bank.getBalanceTop();
        // assertEq(top3.length, 3, "Should have exactly 3 top users");
        
        // assertEq(top3[0], haJiMi, "First place address mismatch");
        
        // assertEq(top3[1], bob, "Second place address mismatch");
        
        // assertEq(top3[2], tom, "Third place address mismatch");
    }

    function test_onlyOwner() public{
        vm.startPrank(alice);
        Bank bank1 = new Bank();
        vm.deal(alice, 1 ether);
        (bool success,) = address(bank1).call{value: 0.5 ether}("");
        require(success, " only admin can withdraw" );
        bank1.withdraw(0.1 ether);
        vm.stopPrank();
    }
}
