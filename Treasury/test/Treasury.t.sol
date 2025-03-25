// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Treasury.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract TreasuryTest is Test {
    Treasury public treasury;
    MockERC20 public hog;
    MockERC20 public otherToken;
    
    address public constant OWNER = address(0x123);
    address public constant OPERATOR = address(0x456);
    address public constant USER1 = address(0x789);
    address public constant USER2 = address(0xABC);
    
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant DEPOSIT_AMOUNT = 100 ether;

    function setUp() public {
        vm.startPrank(OWNER);
        
        // Deploy mock tokens
        hog = new MockERC20("HOG", "HOG");
        otherToken = new MockERC20("Other Token", "OTHER");
        
        // Deploy treasury
        treasury = new Treasury(address(hog));
        
        vm.stopPrank();
        
        // Mint initial tokens
        hog.mint(OPERATOR, INITIAL_BALANCE);
        otherToken.mint(OPERATOR, INITIAL_BALANCE);
        
        // Approve tokens for treasury
        vm.startPrank(OPERATOR);
        hog.approve(address(treasury), INITIAL_BALANCE);
        otherToken.approve(address(treasury), INITIAL_BALANCE);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(address(treasury.hog()), address(hog));
        assertEq(treasury.owner(), OWNER);
        assertEq(treasury.operator(), OWNER);
    }

    function testTransferOperator() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        assertEq(treasury.operator(), OPERATOR);
    }

    function test_RevertWhen_TransferOperatorByNonOwner() public {
        vm.prank(USER1);
        vm.expectRevert("Ownable: caller is not the owner");
        treasury.transferOperator(OPERATOR);
    }

    function test_RevertWhen_TransferOperatorToZeroAddress() public {
        vm.prank(OWNER);
        vm.expectRevert("operator: zero address given for new operator");
        treasury.transferOperator(address(0));
    }

    function testSetHog() public {
        address newHog = address(0xDEF);
        
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        treasury.setHog(newHog);
        
        assertEq(address(treasury.hog()), newHog);
    }

    function test_RevertWhen_SetHogByNonOperator() public {
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        treasury.setHog(address(0xDEF));
    }

    function test_RevertWhen_SetHogToZeroAddress() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        vm.expectRevert("HOG address cannot be zero");
        treasury.setHog(address(0));
    }

    function testDeposit() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        treasury.deposit(address(hog), DEPOSIT_AMOUNT);
        
        assertEq(hog.balanceOf(address(treasury)), DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_DepositByNonOperator() public {
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        treasury.deposit(address(hog), DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_DepositZeroAmount() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        vm.expectRevert("Amount must be greater than 0");
        treasury.deposit(address(hog), 0);
    }

    function test_RevertWhen_DepositZeroAddress() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        vm.expectRevert("Token address cannot be zero");
        treasury.deposit(address(0), DEPOSIT_AMOUNT);
    }

    function testWithdraw() public {
        // First deposit
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        treasury.deposit(address(hog), DEPOSIT_AMOUNT);
        
        // Then withdraw
        vm.prank(OPERATOR);
        treasury.withdraw(address(hog), USER1, DEPOSIT_AMOUNT);
        
        assertEq(hog.balanceOf(address(treasury)), 0);
        assertEq(hog.balanceOf(USER1), DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_WithdrawByNonOperator() public {
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        treasury.withdraw(address(hog), USER1, DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_WithdrawZeroAmount() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        vm.expectRevert("Amount must be greater than 0");
        treasury.withdraw(address(hog), USER1, 0);
    }

    function test_RevertWhen_WithdrawToZeroAddress() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        vm.expectRevert("Recipient cannot be zero address");
        treasury.withdraw(address(hog), address(0), DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_WithdrawInsufficientBalance() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        vm.expectRevert("Insufficient balance");
        treasury.withdraw(address(hog), USER1, DEPOSIT_AMOUNT);
    }

    function testEmergencyWithdraw() public {
        // First deposit
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        treasury.deposit(address(hog), DEPOSIT_AMOUNT);
        
        // Then emergency withdraw
        vm.prank(OPERATOR);
        treasury.emergencyWithdraw(address(hog), USER1);
        
        assertEq(hog.balanceOf(address(treasury)), 0);
        assertEq(hog.balanceOf(USER1), DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_EmergencyWithdrawByNonOperator() public {
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        treasury.emergencyWithdraw(address(hog), USER1);
    }

    function test_RevertWhen_EmergencyWithdrawToZeroAddress() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        vm.expectRevert("Recipient cannot be zero address");
        treasury.emergencyWithdraw(address(hog), address(0));
    }

    function test_RevertWhen_EmergencyWithdrawZeroBalance() public {
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        vm.expectRevert("No tokens to withdraw");
        treasury.emergencyWithdraw(address(hog), USER1);
    }

    function testGovernanceRecoverUnsupported() public {
        // First deposit some unsupported token
        vm.prank(OWNER);
        treasury.transferOperator(OPERATOR);
        
        vm.prank(OPERATOR);
        treasury.deposit(address(otherToken), DEPOSIT_AMOUNT);
        
        // Then recover it
        vm.prank(OWNER);
        treasury.governanceRecoverUnsupported(otherToken, USER1);
        
        assertEq(otherToken.balanceOf(address(treasury)), 0);
        assertEq(otherToken.balanceOf(USER1), DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_GovernanceRecoverUnsupportedByNonOwner() public {
        vm.prank(USER1);
        vm.expectRevert("Ownable: caller is not the owner");
        treasury.governanceRecoverUnsupported(otherToken, USER1);
    }

    function test_RevertWhen_GovernanceRecoverUnsupportedToZeroAddress() public {
        vm.prank(OWNER);
        vm.expectRevert("Recipient cannot be zero address");
        treasury.governanceRecoverUnsupported(otherToken, address(0));
    }

    function test_RevertWhen_GovernanceRecoverUnsupportedZeroBalance() public {
        vm.prank(OWNER);
        vm.expectRevert("No tokens to recover");
        treasury.governanceRecoverUnsupported(otherToken, USER1);
    }
} 