// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/GHOG.sol";

contract GHOGTest is Test {
    GHOG public ghog;
    
    address public constant OWNER = address(0x1231);
    address public constant OPERATOR = address(0x456);
    address public constant USER1 = address(0x789);
    address public constant USER2 = address(0xabc);
    
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant MINT_AMOUNT = 100 ether;
    uint256 public constant BURN_AMOUNT = 50 ether;

    function setUp() public {
        vm.startPrank(OWNER);
        ghog = new GHOG();
        ghog.transferOperator(OPERATOR);
        vm.stopPrank();
        
        // Mint initial tokens to USER1
        vm.prank(OPERATOR);
        ghog.mint(USER1, INITIAL_BALANCE);
    }

    function testInitialState() public {
        assertEq(ghog.name(), "GHOG");
        assertEq(ghog.symbol(), "GHOG");
        assertEq(ghog.owner(), OWNER);
        assertEq(ghog.operator(), OPERATOR);
        assertEq(ghog.totalSupply(), INITIAL_BALANCE);
        assertEq(ghog.balanceOf(USER1), INITIAL_BALANCE);
    }

    function testTransferOperator() public {
        vm.startPrank(OWNER);
        
        // Transfer operator role
        ghog.transferOperator(OPERATOR);
        assertEq(ghog.operator(), OPERATOR);
        
        // Verify old operator can't mint
        vm.stopPrank();
        vm.prank(OWNER);
        vm.expectRevert("operator: caller is not the operator");
        ghog.mint(USER2, MINT_AMOUNT);
        
        // Verify new operator can mint
        vm.prank(OPERATOR);
        ghog.mint(USER2, MINT_AMOUNT);
        assertEq(ghog.balanceOf(USER2), MINT_AMOUNT);
    }

    function test_RevertWhen_TransferOperatorToZeroAddress() public {
        vm.prank(OWNER);
        vm.expectRevert("operator: zero address given for new operator");
        ghog.transferOperator(address(0));
    }

    function test_RevertWhen_TransferOperatorByNonOwner() public {
        vm.prank(USER1);
        vm.expectRevert("Ownable: caller is not the owner");
        ghog.transferOperator(OPERATOR);
    }

    function testMint() public {
        vm.prank(OPERATOR);
        bool success = ghog.mint(USER2, MINT_AMOUNT);
        
        assertTrue(success);
        assertEq(ghog.balanceOf(USER2), MINT_AMOUNT);
        assertEq(ghog.totalSupply(), INITIAL_BALANCE + MINT_AMOUNT);
    }

    function test_RevertWhen_MintByNonOperator() public {
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        ghog.mint(USER2, MINT_AMOUNT);
    }

    function testBurn() public {
        vm.prank(USER1);
        ghog.burn(BURN_AMOUNT);
        
        assertEq(ghog.balanceOf(USER1), INITIAL_BALANCE - BURN_AMOUNT);
        assertEq(ghog.totalSupply(), INITIAL_BALANCE - BURN_AMOUNT);
    }

    function testBurnFrom() public {
        // First approve operator to burn
        vm.prank(USER1);
        ghog.approve(OPERATOR, BURN_AMOUNT);
        
        // Then operator burns
        vm.prank(OPERATOR);
        ghog.burnFrom(USER1, BURN_AMOUNT);
        
        assertEq(ghog.balanceOf(USER1), INITIAL_BALANCE - BURN_AMOUNT);
        assertEq(ghog.totalSupply(), INITIAL_BALANCE - BURN_AMOUNT);
    }

    function test_RevertWhen_BurnFromByNonOperator() public {
        // First approve USER2 to burn
        vm.prank(USER1);
        ghog.approve(USER2, BURN_AMOUNT);
        
        // Then USER2 tries to burn (should fail)
        vm.prank(USER2);
        vm.expectRevert("operator: caller is not the operator");
        ghog.burnFrom(USER1, BURN_AMOUNT);
    }

    function test_RevertWhen_BurnFromInsufficientBalance() public {
        // First approve operator to burn
        vm.prank(USER1);
        ghog.approve(OPERATOR, INITIAL_BALANCE + 1);
        
        // Then operator tries to burn more than balance
        vm.prank(OPERATOR);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        ghog.burnFrom(USER1, INITIAL_BALANCE + 1);
    }
} 