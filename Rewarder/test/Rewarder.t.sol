// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Rewarder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract RewarderTest is Test {
    Rewarder public rewarder;
    MockERC20 public rewardsToken;
    MockERC20 public stakingToken;
    
    address public constant OWNER = address(0x123);
    address public constant USER1 = address(0x456);
    address public constant USER2 = address(0x789);
    
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant REWARD_AMOUNT = 100 ether;
    uint256 public constant STAKE_AMOUNT = 10 ether;
    uint256 public constant MIN_STAKE = 5 ether;
    uint256 public constant MAX_STAKE = 100 ether;

    function setUp() public {
        vm.startPrank(OWNER);
        
        // Deploy mock tokens
        rewardsToken = new MockERC20("Rewards Token", "RWD");
        stakingToken = new MockERC20("Staking Token", "STK");
        
        // Deploy rewarder
        rewarder = new Rewarder(
            address(rewardsToken),
            address(stakingToken),
            MIN_STAKE,
            MAX_STAKE
        );
        
        // Mint initial tokens
        rewardsToken.mint(OWNER, INITIAL_BALANCE);
        stakingToken.mint(USER1, INITIAL_BALANCE);
        stakingToken.mint(USER2, INITIAL_BALANCE);
        
        // Approve and transfer rewards to the rewarder
        rewardsToken.approve(address(rewarder), REWARD_AMOUNT);
        rewardsToken.transfer(address(rewarder), REWARD_AMOUNT);
        
        vm.stopPrank();
        
        // Approve staking tokens for users
        vm.startPrank(USER1);
        stakingToken.approve(address(rewarder), INITIAL_BALANCE);
        vm.stopPrank();
        
        vm.startPrank(USER2);
        stakingToken.approve(address(rewarder), INITIAL_BALANCE);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(address(rewarder.rewardsToken()), address(rewardsToken));
        assertEq(address(rewarder.stakingToken()), address(stakingToken));
        assertEq(rewarder.owner(), OWNER);
        assertEq(rewarder.totalSupply(), 0);
        assertEq(rewarder.periodFinish(), 0);
        assertEq(rewarder.rewardRate(), 0);
        assertEq(rewarder.rewardsDuration(), 7 days);
        assertEq(rewarder.minimumStakeAmount(), MIN_STAKE);
        assertEq(rewarder.maximumStakeAmount(), MAX_STAKE);
    }

    function testStaking() public {
        vm.prank(USER1);
        rewarder.stake(STAKE_AMOUNT);
        
        assertEq(rewarder.totalSupply(), STAKE_AMOUNT);
        assertEq(rewarder.balanceOf(USER1), STAKE_AMOUNT);
        assertEq(stakingToken.balanceOf(address(rewarder)), STAKE_AMOUNT);
    }

    function test_RevertWhen_StakingZero() public {
        vm.prank(USER1);
        vm.expectRevert("Cannot stake 0");
        rewarder.stake(0);
    }

    function test_RevertWhen_StakingBelowMinimum() public {
        vm.prank(USER1);
        vm.expectRevert("Below minimum stake amount");
        rewarder.stake(MIN_STAKE - 1);
    }

    function test_RevertWhen_StakingAboveMaximum() public {
        vm.prank(USER1);
        vm.expectRevert("Exceeds maximum stake amount");
        rewarder.stake(MAX_STAKE + 1);
    }

    function testWithdraw() public {
        // First stake
        vm.prank(USER1);
        rewarder.stake(STAKE_AMOUNT);
        
        // Then withdraw
        vm.prank(USER1);
        rewarder.withdraw(STAKE_AMOUNT);
        
        assertEq(rewarder.totalSupply(), 0);
        assertEq(rewarder.balanceOf(USER1), 0);
        assertEq(stakingToken.balanceOf(USER1), INITIAL_BALANCE);
    }

    function test_RevertWhen_WithdrawZero() public {
        vm.prank(USER1);
        vm.expectRevert("Cannot withdraw 0");
        rewarder.withdraw(0);
    }

    function testNotifyRewardAmount() public {
        vm.prank(OWNER);
        rewarder.notifyRewardAmount(REWARD_AMOUNT);
        
        assertGt(rewarder.periodFinish(), block.timestamp);
        assertGt(rewarder.rewardRate(), 0);
    }

    function test_RevertWhen_NotifyRewardAmountByNonOwner() public {
        vm.prank(USER1);
        vm.expectRevert("Ownable: caller is not the owner");
        rewarder.notifyRewardAmount(REWARD_AMOUNT);
    }

    function testEarnRewards() public {
        // Setup rewards
        vm.prank(OWNER);
        rewarder.notifyRewardAmount(REWARD_AMOUNT);
        
        // Stake tokens
        vm.prank(USER1);
        rewarder.stake(STAKE_AMOUNT);
        
        // Move forward in time
        vm.warp(block.timestamp + 1 days);
        
        // Check earned rewards
        uint256 earned = rewarder.earned(USER1);
        assertGt(earned, 0);
    }

    function testGetReward() public {
        // Setup rewards
        vm.prank(OWNER);
        rewarder.notifyRewardAmount(REWARD_AMOUNT);
        
        // Stake tokens
        vm.prank(USER1);
        rewarder.stake(STAKE_AMOUNT);
        
        // Move forward in time
        vm.warp(block.timestamp + 1 days);
        
        // Get initial balance
        uint256 initialBalance = rewardsToken.balanceOf(USER1);
        
        // Claim rewards
        vm.prank(USER1);
        rewarder.getReward();
        
        // Check rewards received
        assertGt(rewardsToken.balanceOf(USER1), initialBalance);
    }

    function testExit() public {
        // Setup rewards and stake
        vm.prank(OWNER);
        rewarder.notifyRewardAmount(REWARD_AMOUNT);
        
        vm.prank(USER1);
        rewarder.stake(STAKE_AMOUNT);
        
        // Move forward in time
        vm.warp(block.timestamp + 1 days);
        
        // Record balances before exit
        uint256 initialStakingBalance = stakingToken.balanceOf(USER1);
        uint256 initialRewardBalance = rewardsToken.balanceOf(USER1);
        
        // Exit
        vm.prank(USER1);
        rewarder.exit();
        
        // Verify all tokens returned and rewards claimed
        assertEq(stakingToken.balanceOf(USER1), initialStakingBalance + STAKE_AMOUNT);
        assertGt(rewardsToken.balanceOf(USER1), initialRewardBalance);
        assertEq(rewarder.balanceOf(USER1), 0);
    }

    function testSetRewardsDuration() public {
        uint256 newDuration = 14 days;
        
        // Can't change duration before current period finishes
        vm.prank(OWNER);
        rewarder.notifyRewardAmount(REWARD_AMOUNT);
        
        vm.prank(OWNER);
        vm.expectRevert("Previous rewards period must be complete before changing the duration for the new period");
        rewarder.setRewardsDuration(newDuration);
        
        // Move past period finish
        vm.warp(block.timestamp + 8 days);
        
        // Now we can change duration
        vm.prank(OWNER);
        rewarder.setRewardsDuration(newDuration);
        
        assertEq(rewarder.rewardsDuration(), newDuration);
    }

    function test_RevertWhen_SetRewardsDurationByNonOwner() public {
        vm.prank(USER1);
        vm.expectRevert("Ownable: caller is not the owner");
        rewarder.setRewardsDuration(14 days);
    }

    function testSetStakeLimits() public {
        uint256 newMin = 10 ether;
        uint256 newMax = 200 ether;
        
        vm.prank(OWNER);
        rewarder.setStakeLimits(newMin, newMax);
        
        assertEq(rewarder.minimumStakeAmount(), newMin);
        assertEq(rewarder.maximumStakeAmount(), newMax);
    }

    function test_RevertWhen_SetStakeLimitsByNonOwner() public {
        vm.prank(USER1);
        vm.expectRevert("Ownable: caller is not the owner");
        rewarder.setStakeLimits(10 ether, 200 ether);
    }

    function test_RevertWhen_SetInvalidStakeLimits() public {
        vm.startPrank(OWNER);
        
        // Test minimum = 0
        vm.expectRevert("Minimum stake must be greater than 0");
        rewarder.setStakeLimits(0, 100 ether);
        
        // Test maximum <= minimum
        vm.expectRevert("Maximum stake must be greater than minimum");
        rewarder.setStakeLimits(100 ether, 100 ether);
        
        vm.stopPrank();
    }
} 