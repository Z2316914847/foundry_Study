// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import "../task/day23/Vesting.sol";
import "../task/day23/ownerERC20Permit.sol";

contract Vesting is Test {

    ownerERC20Permit public token;
    MyVesting public vesting;
    address owner= makeAddr("alice");

    function setUp() public {
        vm.startPrank(owner);

        token = new  ownerERC20Permit();
        vesting = new MyVesting( address(owner), address(token));
        token.approve(address(vesting), 24e18);    
        vesting.deposit(24e18);
        vm.stopPrank();
    }

    function test_InitialState() public {
        assertEq(address(vesting._token()), address(token));
        assertEq(vesting._beneficiary(), address(owner));
        assertEq(vesting._totalAmount(), 24e18);
        assertEq(vesting._releasedAmount(), 0);
        assertEq(token.balanceOf(address(vesting)), 24e18);
        console.log();
    }

    // 获取释放的 amount
    function test_release() public {
        vm.startPrank(owner);

        uint256 amount= vesting.release();
        console.log(amount);

        vm.stopPrank();
    }

    function test_release2() public {
        vm.startPrank(owner);

        // 推进时间但仍在锁定期内
        vm.warp(block.timestamp + 36 * 30 days);
        uint256 amount= vesting.release();
        console.log(amount);
        
        vm.stopPrank();
    }

    // 时间向前推进 37 个月
    function test_release3() public {
        vm.startPrank(owner);

        // 推进时间但仍在锁定期内
        vm.warp(block.timestamp + 37 * 30 days);
        uint256 amount= vesting.release();
        
        vm.stopPrank();
    }
}