// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Masonry.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockTreasury {
    uint256 private currentEpoch;
    uint256 private nextEpochPoint;
    uint256 private hogPrice;

    constructor() {
        currentEpoch = 0;
        nextEpochPoint = block.timestamp + 6 hours;
        hogPrice = 1e18; // 1:1 price
    }

    function epoch() external view returns (uint256) {
        return currentEpoch;
    }

    function nextEpochPoint() external view returns (uint256) {
        return nextEpochPoint;
    }

    function getHogPrice() external view returns (uint256) {
        return hogPrice;
    }

    // Test helper functions
    function setEpoch(uint256 _epoch) external {
        currentEpoch = _epoch;
    }

    function setNextEpochPoint(uint256 _point) external {
        nextEpochPoint = _point;
    }

    function setHogPrice(uint256 _price) external {
        hogPrice = _price;
    }
}

contract MasonryTest is Test {
    Masonry public masonry;
    MockToken public hog;
    MockToken public share;
    MockTreasury public treasury;
    
    address public constant OWNER = address(0x123);
    address public constant OPERATOR = address(0x456);
    address public constant USER1 = address(0x789);
    address public constant USER2 = address(0xabc);
    
    uint256 public constant INITIAL_SHARE_BALANCE = 1000 ether;
    uint256 public constant STAKE_AMOUNT = 100 ether;
    uint256 public constant REWARD_AMOUNT = 10 ether;

    function setUp() public {
        vm.startPrank(OWNER);
        
        // Deploy mock tokens and treasury
        hog = new MockToken("HOG", "HOG");
        share = new MockToken("SHARE", "SHARE");
        treasury = new MockTreasury();
        
        // Deploy masonry
        masonry = new Masonry();
        masonry.initialize(IERC20(address(hog)), IERC20(address(share)), ITreasury(address(treasury)));
        masonry.transferOperator(OPERATOR);
        
        // Setup initial balances
        share.mint(USER1, INITIAL_SHARE_BALANCE);
        share.mint(USER2, INITIAL_SHARE_BALANCE);
        hog.mint(OPERATOR, REWARD_AMOUNT * 10);
        
        vm.stopPrank();
        
        // Approve masonry to spend shares
        vm.startPrank(USER1);
        share.approve(address(masonry), type(uint256).max);
        vm.stopPrank();
        
        vm.startPrank(USER2);
        share.approve(address(masonry), type(uint256).max);
        vm.stopPrank();
        
        // Approve masonry to spend rewards
        vm.startPrank(OPERATOR);
        hog.approve(address(masonry), type(uint256).max);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(address(masonry.hog()), address(hog));
        assertEq(address(masonry.share()), address(share));
        assertEq(address(masonry.treasury()), address(treasury));
        assertEq(masonry.operator(), OPERATOR);
        assertEq(masonry.totalSupply(), 0);
        assertEq(masonry.withdrawLockupEpochs(), 6);
        assertEq(masonry.rewardLockupEpochs(), 3);
    }

    function testStake() public {
        vm.prank(USER1);
        masonry.stake(STAKE_AMOUNT);
        
        assertEq(masonry.totalSupply(), STAKE_AMOUNT);
        assertEq(masonry.balanceOf(USER1), STAKE_AMOUNT);
        assertEq(share.balanceOf(address(masonry)), STAKE_AMOUNT);
    }

    function test_RevertWhen_StakeZero() public {
        vm.prank(USER1);
        vm.expectRevert("Masonry: Cannot stake 0");
        masonry.stake(0);
    }

    function testWithdraw() public {
        // First stake
        vm.prank(USER1);
        masonry.stake(STAKE_AMOUNT);
        
        // Advance epochs to pass lockup
        treasury.setEpoch(6);
        
        // Then withdraw
        vm.prank(USER1);
        masonry.withdraw(STAKE_AMOUNT);
        
        assertEq(masonry.totalSupply(), 0);
        assertEq(masonry.balanceOf(USER1), 0);
        assertEq(share.balanceOf(USER1), INITIAL_SHARE_BALANCE);
    }

    function test_RevertWhen_WithdrawZero() public {
        vm.prank(USER1);
        vm.expectRevert("Masonry: Cannot withdraw 0");
        masonry.withdraw(0);
    }

    function test_RevertWhen_WithdrawInLockup() public {
        // First stake
        vm.prank(USER1);
        masonry.stake(STAKE_AMOUNT);
        
        // Try to withdraw before lockup ends
        vm.prank(USER1);
        vm.expectRevert("Masonry: still in withdraw lockup");
        masonry.withdraw(STAKE_AMOUNT);
    }

    function testEarningRewards() public {
        // First stake
        vm.prank(USER1);
        masonry.stake(STAKE_AMOUNT);
        
        // Allocate rewards
        vm.prank(OPERATOR);
        masonry.allocateSeigniorage(REWARD_AMOUNT);
        
        // Check earned amount
        uint256 earned = masonry.earned(USER1);
        assertEq(earned, REWARD_AMOUNT);
    }

    function testClaimReward() public {
        // First stake
        vm.prank(USER1);
        masonry.stake(STAKE_AMOUNT);
        
        // Allocate rewards
        vm.prank(OPERATOR);
        masonry.allocateSeigniorage(REWARD_AMOUNT);
        
        // Advance epochs to pass lockup
        treasury.setEpoch(3);
        
        // Claim rewards
        vm.prank(USER1);
        masonry.claimReward();
        
        assertEq(hog.balanceOf(USER1), REWARD_AMOUNT);
    }

    function test_RevertWhen_ClaimRewardInLockup() public {
        // First stake
        vm.prank(USER1);
        masonry.stake(STAKE_AMOUNT);
        
        // Allocate rewards
        vm.prank(OPERATOR);
        masonry.allocateSeigniorage(REWARD_AMOUNT);
        
        // Try to claim before lockup ends
        vm.prank(USER1);
        vm.expectRevert("Masonry: still in reward lockup");
        masonry.claimReward();
    }

    function testExit() public {
        // First stake
        vm.prank(USER1);
        masonry.stake(STAKE_AMOUNT);
        
        // Allocate rewards
        vm.prank(OPERATOR);
        masonry.allocateSeigniorage(REWARD_AMOUNT);
        
        // Advance epochs to pass lockups
        treasury.setEpoch(6);
        
        // Exit
        vm.prank(USER1);
        masonry.exit();
        
        assertEq(masonry.balanceOf(USER1), 0);
        assertEq(share.balanceOf(USER1), INITIAL_SHARE_BALANCE);
        assertEq(hog.balanceOf(USER1), REWARD_AMOUNT);
    }

    function testSetLockUp() public {
        vm.startPrank(OPERATOR);
        
        uint256 newWithdrawLockup = 12;
        uint256 newRewardLockup = 6;
        masonry.setLockUp(newWithdrawLockup, newRewardLockup);
        
        assertEq(masonry.withdrawLockupEpochs(), newWithdrawLockup);
        assertEq(masonry.rewardLockupEpochs(), newRewardLockup);
        
        vm.stopPrank();
    }

    function test_RevertWhen_SetLockUpByNonOperator() public {
        vm.prank(USER1);
        vm.expectRevert("Operator: caller is not the operator");
        masonry.setLockUp(12, 6);
    }

    function test_RevertWhen_SetInvalidLockUp() public {
        vm.startPrank(OPERATOR);
        
        // Test withdraw lockup > 56
        vm.expectRevert("_withdrawLockupEpochs: out of range");
        masonry.setLockUp(57, 6);
        
        // Test withdraw lockup < reward lockup
        vm.expectRevert("_withdrawLockupEpochs: out of range");
        masonry.setLockUp(3, 6);
        
        // Test zero lockups
        vm.expectRevert("lockupEpochs must be greater than 0");
        masonry.setLockUp(0, 0);
        
        vm.stopPrank();
    }
} 