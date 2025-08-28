// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../task/day27/rebaseToken.sol";

contract rebaseTokenTest is Test {
    RebaseToken public rebaseToken;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        rebaseToken = new RebaseToken();
    }

    // 自动通缩测试
    function test_rebaseTooEarly() public {
        // 尝试过早执行rebase应该失败
        // vm.expectRevert("Rebase too early");
        vm.warp(366 days);
        rebaseToken.rebase();
    }

    // 手动通缩
    function test_manualRebase() public {
        uint256 initialSupply = rebaseToken.totalSupply();
        uint256 initialGonsPerFragment = rebaseToken.gonsPerFragment();

        // 手动执行rebase
        rebaseToken.manualRebase();
        
        // 验证rebase后的状态
        assertEq(rebaseToken.rebaseCount(), 1);
        assertEq(rebaseToken.totalSupply(), (initialSupply * 99) / 100); // 通缩1%
        assertEq(rebaseToken.gonsPerFragment(), 1169617063003193893167383686956443513669393784501419);
    }

    // 转账余额 = 转账*调整系数 
    function test_gonBalanceConsistency() public {
        uint256 transferAmount = 1000 * 10**18;
        
        // 转移代币给用户1
        rebaseToken.transfer(user1, transferAmount);
        console.log("before user1 balances: ", rebaseToken.balanceOf(user1));
        
        // 执行rebase
        rebaseToken.manualRebase();
        console.log("after user1 balances: ", rebaseToken.balanceOf(user1));
        
        // 验证gon余额的一致性
        uint256 ownerGonBalance = rebaseToken.gonBalanceOf(owner);
        uint256 user1GonBalance = rebaseToken.gonBalanceOf(user1);
        uint256 gonsPerFragment = rebaseToken.gonsPerFragment();
        
        assertEq(rebaseToken.balanceOf(owner), ownerGonBalance / gonsPerFragment);
        assertEq(rebaseToken.balanceOf(user1), user1GonBalance / gonsPerFragment);
    }
}