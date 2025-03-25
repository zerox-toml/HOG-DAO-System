// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Oracle.sol";
import "../contracts/mocks/MockPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract OracleTest is Test {
    Oracle public oracle;
    MockPool public pool;
    MockToken public token0;
    MockToken public token1;
    
    address public constant OWNER = address(0x123);
    address public constant USER = address(0x456);
    
    uint256 public constant INITIAL_LIQUIDITY = 1000000 ether;
    uint256 public constant CONSULT_AMOUNT = 1000 ether;

    function setUp() public {
        vm.startPrank(OWNER);
        
        // Deploy mock tokens
        token0 = new MockToken("Token0", "TKN0");
        token1 = new MockToken("Token1", "TKN1");
        
        // Deploy mock pool with initial liquidity
        pool = new MockPool(
            address(token0),
            address(token1),
            INITIAL_LIQUIDITY,
            INITIAL_LIQUIDITY
        );
        
        // Deploy oracle
        oracle = new Oracle(IPool(address(pool)));
        
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(oracle.token0(), address(token0));
        assertEq(oracle.token1(), address(token1));
        assertEq(address(oracle.pair()), address(pool));
    }

    function testUpdate() public {
        // Update should call sync on the pool
        oracle.update();
        // Note: In this test, sync() doesn't do anything in the mock pool
    }

    function testConsult() public {
        // Test with default 1:1 price
        uint256 amountOut = oracle.consult(address(token0), CONSULT_AMOUNT);
        assertEq(amountOut, CONSULT_AMOUNT);
        
        // Test with modified price (2:1)
        pool.setMockPrice(2e18);
        amountOut = oracle.consult(address(token0), CONSULT_AMOUNT);
        assertEq(amountOut, CONSULT_AMOUNT * 2);
        
        // Test reverse direction
        amountOut = oracle.consult(address(token1), CONSULT_AMOUNT);
        assertEq(amountOut, CONSULT_AMOUNT / 2);
    }

    function testTWAP() public {
        // Test with default 1:1 price
        uint256 amountOut = oracle.twap(address(token0), CONSULT_AMOUNT);
        assertEq(amountOut, CONSULT_AMOUNT);
        
        // Test with modified price (2:1)
        pool.setMockPrice(2e18);
        amountOut = oracle.twap(address(token0), CONSULT_AMOUNT);
        assertEq(amountOut, CONSULT_AMOUNT * 2);
        
        // Test reverse direction
        amountOut = oracle.twap(address(token1), CONSULT_AMOUNT);
        assertEq(amountOut, CONSULT_AMOUNT / 2);
    }

    function test_RevertWhen_ConsultInvalidToken() public {
        address invalidToken = address(0xdead);
        vm.expectRevert("Oracle: Invalid token");
        oracle.consult(invalidToken, CONSULT_AMOUNT);
    }

    function test_RevertWhen_TWAPInvalidToken() public {
        address invalidToken = address(0xdead);
        vm.expectRevert("Oracle: Invalid token");
        oracle.twap(invalidToken, CONSULT_AMOUNT);
    }

    function test_RevertWhen_NotEnoughObservations() public {
        // Set observation count lower than required granularity
        pool.setObservationCount(1);
        
        vm.expectRevert("Oracle: Not enough observations");
        oracle.consult(address(token0), CONSULT_AMOUNT);
    }

    function test_RevertWhen_ConstructWithEmptyReserves() public {
        // Deploy new pool with zero reserves
        MockPool emptyPool = new MockPool(
            address(token0),
            address(token1),
            0,
            0
        );
        
        vm.expectRevert("Oracle: No reserves");
        new Oracle(IPool(address(emptyPool)));
    }
} 