// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Pair.sol";
import "../contracts/PairFees.sol";
import "../contracts/interfaces/IERC20.sol";

contract MockToken is IERC20 {
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    constructor(string memory symbol_, uint8 decimals_) {
        _symbol = symbol_;
        _decimals = decimals_;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        _totalSupply += amount;
        _balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balanceOf[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(_balanceOf[msg.sender] >= amount, "Insufficient balance");
        _balanceOf[msg.sender] -= amount;
        _balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(_allowance[from][msg.sender] >= amount, "Insufficient allowance");
        require(_balanceOf[from] >= amount, "Insufficient balance");
        _allowance[from][msg.sender] -= amount;
        _balanceOf[from] -= amount;
        _balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract MockPairFactory {
    address public token0;
    address public token1;
    bool public stable;
    address public stakingFeeHandler;
    uint256 public stakingNFTFee;
    uint256 public MAX_TREASURY_FEE;
    address public dibs;

    constructor(
        address _token0,
        address _token1,
        bool _stable,
        address _stakingFeeHandler,
        uint256 _stakingNFTFee,
        uint256 _maxTreasuryFee,
        address _dibs
    ) {
        token0 = _token0;
        token1 = _token1;
        stable = _stable;
        stakingFeeHandler = _stakingFeeHandler;
        stakingNFTFee = _stakingNFTFee;
        MAX_TREASURY_FEE = _maxTreasuryFee;
        dibs = _dibs;
    }

    function getInitializable() external view returns (address, address, bool) {
        return (token0, token1, stable);
    }

    function getFee(bool _stable) external pure returns (uint256) {
        return 30; // 0.3% fee
    }
}

contract PairTest is Test {
    Pair public pair;
    PairFees public fees;
    MockToken public token0;
    MockToken public token1;
    MockPairFactory public factory;
    
    address public constant OWNER = address(0x123);
    address public constant USER1 = address(0x456);
    address public constant USER2 = address(0x789);
    address public constant STAKING_FEE_HANDLER = address(0xabc);
    address public constant DIBS = address(0xdef);
    
    uint256 public constant INITIAL_BALANCE = 1000000 ether;
    uint256 public constant STAKE_AMOUNT = 1000 ether;
    uint256 public constant SWAP_AMOUNT = 100 ether;
    uint256 public constant STAKING_NFT_FEE = 100; // 1%
    uint256 public constant MAX_TREASURY_FEE = 500; // 5%
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    function setUp() public {
        vm.startPrank(OWNER);
        
        // Deploy mock tokens
        token0 = new MockToken("Token0", 18);
        token1 = new MockToken("Token1", 18);
        
        // Deploy mock factory
        factory = new MockPairFactory(
            address(token0),
            address(token1),
            false, // volatile pair
            STAKING_FEE_HANDLER,
            STAKING_NFT_FEE,
            MAX_TREASURY_FEE,
            DIBS
        );
        
        // Deploy pair fees
        fees = new PairFees(address(token0), address(token1));
        
        // Deploy pair with factory as msg.sender
        vm.stopPrank();
        vm.prank(address(factory));
        pair = new Pair();
        
        // Setup initial balances
        vm.startPrank(OWNER);
        token0.mint(USER1, INITIAL_BALANCE);
        token1.mint(USER1, INITIAL_BALANCE);
        vm.stopPrank();
        
        // Approve pair to spend tokens
        vm.startPrank(USER1);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(pair.token0(), address(token0));
        assertEq(pair.token1(), address(token1));
        assertEq(pair.stable(), false);
        assertEq(pair.totalSupply(), 0);
        assertEq(pair.decimals(), 18);
        assertEq(pair.name(), "VolatileV1 AMM - Token0/Token1");
        assertEq(pair.symbol(), "vAMM-Token0/Token1");
    }

    function testMint() public {
        vm.startPrank(USER1);
        
        // First mint some liquidity
        uint256 amount0 = 100 ether;
        uint256 amount1 = 100 ether;
        
        // Transfer tokens to pair first
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        
        // Mint LP tokens
        pair.mint(USER1);
        
        assertEq(pair.totalSupply() > 0, true);
        assertEq(pair.balanceOf(USER1) > 0, true);
        assertEq(token0.balanceOf(address(pair)), amount0);
        assertEq(token1.balanceOf(address(pair)), amount1);
        
        vm.stopPrank();
    }

    function testBurn() public {
        vm.startPrank(USER1);
        
        // First mint some liquidity
        uint256 amount0 = 100 ether;
        uint256 amount1 = 100 ether;
        
        // Transfer tokens to pair first
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        
        // Mint LP tokens
        pair.mint(USER1);
        
        // Get initial balances
        uint256 initialBalance0 = token0.balanceOf(USER1);
        uint256 initialBalance1 = token1.balanceOf(USER1);
        uint256 lpBalance = pair.balanceOf(USER1);
        
        // Transfer LP tokens to pair for burning
        pair.transfer(address(pair), lpBalance);
        
        // Then burn
        pair.burn(USER1);
        
        // Check final state
        assertEq(pair.balanceOf(USER1), 0);
        assertEq(pair.totalSupply(), MINIMUM_LIQUIDITY);
        assertGt(token0.balanceOf(USER1), initialBalance0);
        assertGt(token1.balanceOf(USER1), initialBalance1);
        
        vm.stopPrank();
    }

    function testSwap() public {
        vm.startPrank(USER1);
        
        // First mint some liquidity
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;
        
        // Transfer tokens to pair first
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        
        // Mint LP tokens
        pair.mint(USER1);
        
        // Get initial balances
        uint256 initialBalance0 = token0.balanceOf(USER1);
        uint256 initialBalance1 = token1.balanceOf(USER1);
        
        // Then swap
        uint256 amountIn = 10 ether;
        token0.transfer(address(pair), amountIn);
        
        // Calculate expected amount out using the pair's getAmountOut function
        uint256 amountOut = pair.getAmountOut(amountIn, address(token0));
        pair.swap(0, amountOut, USER1, "");
        
        // Check final state
        assertLt(token0.balanceOf(USER1), initialBalance0);
        assertGt(token1.balanceOf(USER1), initialBalance1);
        
        vm.stopPrank();
    }

    function testSync() public {
        vm.startPrank(USER1);
        
        // First mint some liquidity
        uint256 amount0 = 100 ether;
        uint256 amount1 = 100 ether;
        
        // Transfer tokens to pair first
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        
        // Mint LP tokens
        pair.mint(USER1);
        
        // Then sync
        pair.sync();
        
        // Check reserves match balances
        assertEq(pair.reserve0(), token0.balanceOf(address(pair)));
        assertEq(pair.reserve1(), token1.balanceOf(address(pair)));
        
        vm.stopPrank();
    }

    function testClaimFees() public {
        vm.startPrank(USER1);
        
        // First mint some liquidity
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;
        
        // Transfer tokens to pair first
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        
        // Mint LP tokens
        pair.mint(USER1);
        
        // Get initial balances
        uint256 initialBalance0 = token0.balanceOf(USER1);
        uint256 initialBalance1 = token1.balanceOf(USER1);
        
        // Perform some swaps to generate fees
        uint256 amountIn = 100 ether;
        token0.transfer(address(pair), amountIn);
        uint256 amountOut0 = pair.getAmountOut(amountIn, address(token0));
        pair.swap(0, amountOut0, USER1, "");
        
        token1.transfer(address(pair), amountIn);
        uint256 amountOut1 = pair.getAmountOut(amountIn, address(token1));
        pair.swap(amountOut1, 0, USER1, "");
        
        // Claim fees
        (uint256 claimed0, uint256 claimed1) = pair.claimFees();
        
        // Check fees were claimed
        assertGt(claimed0, 0);
        assertGt(claimed1, 0);
        
        vm.stopPrank();
    }

    function test_RevertWhen_MintZeroLiquidity() public {
        vm.startPrank(USER1);
        
        // Try to mint with zero liquidity
        vm.expectRevert();
        pair.mint(USER1);
        
        vm.stopPrank();
    }

    function test_RevertWhen_BurnZeroLiquidity() public {
        vm.startPrank(USER1);
        
        // Try to burn with zero liquidity
        vm.expectRevert();
        pair.burn(USER1);
        
        vm.stopPrank();
    }

    function test_RevertWhen_SwapInsufficientOutput() public {
        vm.startPrank(USER1);
        
        // First mint some liquidity
        uint256 amount0 = 100 ether;
        uint256 amount1 = 100 ether;
        
        // Transfer tokens to pair first
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        
        // Mint LP tokens
        pair.mint(USER1);
        
        // Try to swap with insufficient output
        vm.expectRevert(abi.encodePacked("IOA"));
        pair.swap(0, 0, USER1, "");
        
        vm.stopPrank();
    }

    function test_RevertWhen_SwapInsufficientInput() public {
        vm.startPrank(USER1);
        
        // First mint some liquidity
        uint256 amount0 = 100 ether;
        uint256 amount1 = 100 ether;
        
        // Transfer tokens to pair first
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        
        // Mint LP tokens
        pair.mint(USER1);
        
        // Try to swap with insufficient input
        vm.expectRevert(abi.encodePacked("IIA"));
        pair.swap(1 ether, 0, USER1, "");
        
        vm.stopPrank();
    }
} 