// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/MeerkatPair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MeerkatPairTest is Test {
    MeerkatPair meerkatPair;
    address token0;
    address token1;

    function setUp() public {
        // Deploy two mock ERC20 tokens
        token0 = address(new MockERC20("Token0", "TK0"));
        token1 = address(new MockERC20("Token1", "TK1")); 

        // Deploy the MeerkatPair contract
        meerkatPair = new MeerkatPair();
        meerkatPair.initialize(token0, token1);
    }

    function testMint() public {
        // Mint some tokens for the pair
        MockERC20(token0).mint(address(meerkatPair), 1000 * 10 ** 18);
        MockERC20(token1).mint(address(meerkatPair), 1000 * 10 ** 18);

        // Mint liquidity
        uint liquidity = meerkatPair.mint(address(this));

        assertGt(liquidity, 0, "Liquidity should be greater than 0");
    }

    function testBurn() public {
        // Mint some tokens for the pair
        MockERC20(token0).mint(address(meerkatPair), 1000 * 10 ** 18);
        MockERC20(token1).mint(address(meerkatPair), 1000 * 10 ** 18);
        meerkatPair.mint(address(this));

        // Burn liquidity
        (uint amount0, uint amount1) = meerkatPair.burn(address(this));

        assertGt(amount0, 0, "Amount0 should be greater than 0");
        assertGt(amount1, 0, "Amount1 should be greater than 0");
    }

    function testSwap() public {
        // Mint some tokens for the pair
        MockERC20(token0).mint(address(meerkatPair), 1000 * 10 ** 18);
        MockERC20(token1).mint(address(meerkatPair), 1000 * 10 ** 18);
        meerkatPair.mint(address(this));

        // Swap tokens
        uint amountOut = 100 * 10 ** 18;
        meerkatPair.swap(amountOut, 0, address(this), "");

        uint balanceAfterSwap = MockERC20(token1).balanceOf(address(this));
        assertGt(balanceAfterSwap, 0, "Balance after swap should be greater than 0");
    }
}

// Mock ERC20 token for testing
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }

    
}