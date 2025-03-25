// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/BHOG.sol";

contract BHOGTest is Test {
    BHOG public bhog;
    
    address public constant OWNER = address(0x123);
    address public constant OPERATOR = address(0x456);
    address public constant USER1 = address(0x789);
    address public constant USER2 = address(0xabc);
    
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant MINT_AMOUNT = 100 ether;
    uint256 public constant BURN_AMOUNT = 50 ether;

    function setUp() public {
        vm.startPrank(OWNER);
        bhog = new BHOG();
        bhog.transferOperator(OPERATOR);
        vm.stopPrank();
        
        // Mint initial tokens to USER1
        vm.prank(OPERATOR);
        bhog.mint(USER1, INITIAL_BALANCE);
    }

    function testInitialState() public {
        assertEq(bhog.name(), "BHOG");
        assertEq(bhog.symbol(), "BHOG");
        assertEq(bhog.owner(), OWNER);
        assertEq(bhog.operator(), OPERATOR);
        assertEq(bhog.totalSupply(), INITIAL_BALANCE);
        assertEq(bhog.balanceOf(USER1), INITIAL_BALANCE);
    }

    function testMint() public {
        vm.prank(OPERATOR);
        bool success = bhog.mint(USER2, MINT_AMOUNT);
        
        assertTrue(success);
        assertEq(bhog.balanceOf(USER2), MINT_AMOUNT);
        assertEq(bhog.totalSupply(), INITIAL_BALANCE + MINT_AMOUNT);
    }

    function test_RevertWhen_MintByNonOperator() public {
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        bhog.mint(USER2, MINT_AMOUNT);
    }

    function testBurn() public {
        vm.prank(USER1);
        bhog.burn(BURN_AMOUNT);
        
        assertEq(bhog.balanceOf(USER1), INITIAL_BALANCE - BURN_AMOUNT);
        assertEq(bhog.totalSupply(), INITIAL_BALANCE - BURN_AMOUNT);
    }

    function test_RevertWhen_BurnInsufficientBalance() public {
        vm.prank(USER1);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        bhog.burn(INITIAL_BALANCE + 1);
    }

    function testBurnFrom() public {
        // First approve operator to burn
        vm.prank(USER1);
        bhog.approve(OPERATOR, BURN_AMOUNT);
        
        // Then operator burns
        vm.prank(OPERATOR);
        bhog.burnFrom(USER1, BURN_AMOUNT);
        
        assertEq(bhog.balanceOf(USER1), INITIAL_BALANCE - BURN_AMOUNT);
        assertEq(bhog.totalSupply(), INITIAL_BALANCE - BURN_AMOUNT);
    }

    function test_RevertWhen_BurnFromByNonOperator() public {
        // First approve USER2 to burn
        vm.prank(USER1);
        bhog.approve(USER2, BURN_AMOUNT);
        
        // Then USER2 tries to burn (should fail)
        vm.prank(USER2);
        vm.expectRevert("operator: caller is not the operator");
        bhog.burnFrom(USER1, BURN_AMOUNT);
    }

    function test_RevertWhen_BurnFromInsufficientBalance() public {
        // First approve operator to burn
        vm.prank(USER1);
        bhog.approve(OPERATOR, INITIAL_BALANCE + 1);
        
        // Then operator tries to burn more than balance
        vm.prank(OPERATOR);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        bhog.burnFrom(USER1, INITIAL_BALANCE + 1);
    }

    function testTransfer() public {
        vm.prank(USER1);
        bhog.transfer(USER2, BURN_AMOUNT);
        
        assertEq(bhog.balanceOf(USER1), INITIAL_BALANCE - BURN_AMOUNT);
        assertEq(bhog.balanceOf(USER2), BURN_AMOUNT);
    }

    function test_RevertWhen_TransferInsufficientBalance() public {
        vm.prank(USER1);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        bhog.transfer(USER2, INITIAL_BALANCE + 1);
    }
} 