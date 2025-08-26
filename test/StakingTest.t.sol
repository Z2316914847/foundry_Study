// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../task/day26/Staking.sol";
import "../task/day26/KKToken.sol";
import "../task/day26/WETH9.sol";

contract StakingTest is Test {
    StakingPool public stakingPool;
    KKToken public kkToken;
    WETH9 public weth;
    
    address public owner = address(this);
    address public user1 = makeAddr("user1");
    address public user2 =  makeAddr("user2");
    address public user3 =  makeAddr("user3");
    
    uint256 public constant STAKE_AMOUNT = 10 ether;
    
    function setUp() public {
        
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        
        kkToken = new KKToken();
        weth = new WETH9();
        
        stakingPool = new StakingPool(
            address(kkToken),
            address(weth),
            address(0)
        );
        
        // kkToken.mint(address(stakingPool), 1000000 * 1e18);
    }

    // 同一时刻质押 ＋ 计算用户待领取KKToken奖励 
    function test_Multiple_UsersStaking() public {
        vm.prank(user1);
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        vm.prank(user2);
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        // 区块加10个，更新奖励
        vm.roll(block.number + 10);
        
        uint256 user1Earned = stakingPool.earned(user1);
        uint256 user2Earned = stakingPool.earned(user2);
        
        assertEq(user1Earned, 50 * 1e18);
        assertEq(user1Earned, user2Earned);
    }

    // 同一时刻质押 ＋ 撤回
    function test_Multiple_UsersStaking_1() public {
        vm.prank(user1);
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        vm.prank(user2);
        stakingPool.stake{value: STAKE_AMOUNT}();

        // 区块加10个，更新奖励
        vm.roll(block.number + 10);
        uint256 user1Earned = stakingPool.earned(user1);
        uint256 user2Earned = stakingPool.earned(user2);
        
        assertEq(user1Earned, 50 * 1e18);
        assertEq(user1Earned, user2Earned);

        //----------------------------------撤回全部质押ETH---------------------------------------- 
        // vm.prank(user1);
        // stakingPool.unstake(STAKE_AMOUNT);
        // uint256 user1KKTokenBalance = kkToken.balanceOf(user1);
        // uint256 user2KKTokenBalance = kkToken.balanceOf(user2);
        // assertEq(user1KKTokenBalance, 50 * 1e18);
        // assertEq(user2KKTokenBalance, 0 * 1e18);

        // ----------------------------------撤回部分质押ETH---------------------------------------- 
        // vm.startPrank(user1);
        // stakingPool.unstake(STAKE_AMOUNT / 2);
        // vm.roll(block.number + 3);
        // stakingPool.unstake(STAKE_AMOUNT / 2);
        // // stakingPool.claim();
        // uint256 user1KKTokenBalance = kkToken.balanceOf(user1);
        // uint256 user2KKTokenBalance = kkToken.balanceOf(user2);
        // assertEq(user1KKTokenBalance, 60 * 1e18);
        // assertEq(user2KKTokenBalance, 0 * 1e18);
        // vm.stopPrank();

        // ----------------------------------中途加入用户质押ETH---------------------------------------- 
        vm.startPrank(user3);
        stakingPool.stake{value: STAKE_AMOUNT}();
        uint256 user3KKTokenBalance = kkToken.balanceOf(user3);
        assertEq(kkToken.balanceOf(user3), 0 * 1e18);
        uint256 user3Earned = stakingPool.earned(user3);
        assertEq(user3Earned, 0 * 1e18);
        assertEq(kkToken.balanceOf(user1), 0 * 1e18);
        assertEq(kkToken.balanceOf(user2), 0 * 1e18);
        vm.stopPrank();

        vm.roll(block.number + 30);

        vm.prank(user1);
        stakingPool.unstake(STAKE_AMOUNT/2);

        vm.prank(user2);
        stakingPool.unstake(STAKE_AMOUNT/2);

        vm.prank(user3);
        stakingPool.unstake(STAKE_AMOUNT/2);

        assertEq(kkToken.balanceOf(user1), 150 * 1e18);
        assertEq(kkToken.balanceOf(user2), 150 * 1e18);
        assertEq(kkToken.balanceOf(user3), 100 * 1e18);
       
        
        
    }
    
    
    // function testFuzz_StakeAmount(uint256 amount) public {
    //     vm.assume(amount > 0 && amount <= 1000 ether);
    //     vm.deal(user1, amount);
        
    //     vm.prank(user1);
    //     stakingPool.stake{value: amount}();
        
    //     assertEq(stakingPool.balanceOf(user1), amount);
    //     assertEq(stakingPool.totalStaked(), amount);
    // }
}
