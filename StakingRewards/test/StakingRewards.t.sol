// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/StakingRewards.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract StakingRewardsTest is Test {
    StakingRewards public stakingRewards;
    MockERC20 public rewardsToken;
    MockERC20 public stakingToken;
    
    address public constant OWNER = address(0x123);
    address public constant USER1 = address(0x456);
    address public constant USER2 = address(0x789);
    
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant REWARD_AMOUNT = 100 ether;
    uint256 public constant STAKE_AMOUNT = 10 ether;

    function setUp() public {
        vm.startPrank(OWNER);
        
        // Deploy mock tokens
        rewardsToken = new MockERC20("Rewards Token", "RWD");
        stakingToken = new MockERC20("Staking Token", "STK");
        
        // Deploy staking contract
        stakingRewards = new StakingRewards(
            address(rewardsToken),
            address(stakingToken)
        );
        
        // Mint initial tokens
        rewardsToken.mint(OWNER, INITIAL_BALANCE);
        stakingToken.mint(USER1, INITIAL_BALANCE);
        stakingToken.mint(USER2, INITIAL_BALANCE);
        
        // Approve and transfer rewards to the staking contract
        rewardsToken.approve(address(stakingRewards), REWARD_AMOUNT);
        rewardsToken.transfer(address(stakingRewards), REWARD_AMOUNT);
        
        vm.stopPrank();
        
        // Approve staking tokens for users
        vm.startPrank(USER1);
        stakingToken.approve(address(stakingRewards), INITIAL_BALANCE);
        vm.stopPrank();
        
        vm.startPrank(USER2);
        stakingToken.approve(address(stakingRewards), INITIAL_BALANCE);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(address(stakingRewards.rewardsToken()), address(rewardsToken));
        assertEq(address(stakingRewards.stakingToken()), address(stakingToken));
        assertEq(stakingRewards.owner(), OWNER);
        assertEq(stakingRewards.totalSupply(), 0);
        assertEq(stakingRewards.periodFinish(), 0);
        assertEq(stakingRewards.rewardRate(), 0);
        assertEq(stakingRewards.rewardsDuration(), 7 days);
    }

    function testStaking() public {
        vm.prank(USER1);
        stakingRewards.stake(STAKE_AMOUNT);
        
        assertEq(stakingRewards.totalSupply(), STAKE_AMOUNT);
        assertEq(stakingRewards.balanceOf(USER1), STAKE_AMOUNT);
        assertEq(stakingToken.balanceOf(address(stakingRewards)), STAKE_AMOUNT);
    }

    function test_RevertWhen_StakingZero() public {
        vm.prank(USER1);
        vm.expectRevert("Cannot stake 0");
        stakingRewards.stake(0);
    }

    function testWithdraw() public {
        // First stake
        vm.prank(USER1);
        stakingRewards.stake(STAKE_AMOUNT);
        
        // Then withdraw
        vm.prank(USER1);
        stakingRewards.withdraw(STAKE_AMOUNT);
        
        assertEq(stakingRewards.totalSupply(), 0);
        assertEq(stakingRewards.balanceOf(USER1), 0);
        assertEq(stakingToken.balanceOf(USER1), INITIAL_BALANCE);
    }

    function test_RevertWhen_WithdrawZero() public {
        vm.prank(USER1);
        vm.expectRevert("Cannot withdraw 0");
        stakingRewards.withdraw(0);
    }

    function testNotifyRewardAmount() public {
        vm.startPrank(OWNER);
        stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
        
        assertGt(stakingRewards.periodFinish(), block.timestamp);
        assertGt(stakingRewards.rewardRate(), 0);
        vm.stopPrank();
    }

    function test_RevertWhen_NotifyRewardAmountByNonOwner() public {
        vm.prank(USER1);
        vm.expectRevert("Ownable: caller is not the owner");
        stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
    }

    function testEarnRewards() public {
        // Setup rewards
        vm.prank(OWNER);
        stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
        
        // Stake tokens
        vm.prank(USER1);
        stakingRewards.stake(STAKE_AMOUNT);
        
        // Move forward in time
        vm.warp(block.timestamp + 1 days);
        
        // Check earned rewards
        uint256 earned = stakingRewards.earned(USER1);
        assertGt(earned, 0);
    }

    function testGetReward() public {
        // Setup rewards
        vm.prank(OWNER);
        stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
        
        // Stake tokens
        vm.prank(USER1);
        stakingRewards.stake(STAKE_AMOUNT);
        
        // Move forward in time
        vm.warp(block.timestamp + 1 days);
        
        // Get initial balance
        uint256 initialBalance = rewardsToken.balanceOf(USER1);
        
        // Claim rewards
        vm.prank(USER1);
        stakingRewards.getReward();
        
        // Check rewards received
        assertGt(rewardsToken.balanceOf(USER1), initialBalance);
    }

    function testExit() public {
        // Setup rewards and stake
        vm.prank(OWNER);
        stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
        
        vm.prank(USER1);
        stakingRewards.stake(STAKE_AMOUNT);
        
        // Move forward in time
        vm.warp(block.timestamp + 1 days);
        
        // Record balances before exit
        uint256 initialStakingBalance = stakingToken.balanceOf(USER1);
        uint256 initialRewardBalance = rewardsToken.balanceOf(USER1);
        
        // Exit
        vm.prank(USER1);
        stakingRewards.exit();
        
        // Verify all tokens returned and rewards claimed
        assertEq(stakingToken.balanceOf(USER1), initialStakingBalance + STAKE_AMOUNT);
        assertGt(rewardsToken.balanceOf(USER1), initialRewardBalance);
        assertEq(stakingRewards.balanceOf(USER1), 0);
    }

    function testSetRewardsDuration() public {
        uint256 newDuration = 14 days;
        
        // Can't change duration before current period finishes
        vm.prank(OWNER);
        stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
        
        vm.prank(OWNER);
        vm.expectRevert("Previous rewards period must be complete before changing the duration for the new period");
        stakingRewards.setRewardsDuration(newDuration);
        
        // Move past period finish
        vm.warp(block.timestamp + 8 days);
        
        // Now we can change duration
        vm.prank(OWNER);
        stakingRewards.setRewardsDuration(newDuration);
        
        assertEq(stakingRewards.rewardsDuration(), newDuration);
    }

    function test_RevertWhen_SetRewardsDurationByNonOwner() public {
        vm.prank(USER1);
        vm.expectRevert("Ownable: caller is not the owner");
        stakingRewards.setRewardsDuration(14 days);
    }
} 