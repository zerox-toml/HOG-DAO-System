// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IPool.sol";

contract MockPool is IPool {
    address public override token0;
    address public override token1;
    uint112 private reserve0;
    uint112 private reserve1;
    uint256 private mockPrice;
    uint256 private observationCount;
    uint256 private _fee;
    uint256 private _feeSplit;
    address private _feeRecipient;

    constructor(address _token0, address _token1, uint256 _reserve0, uint256 _reserve1) {
        token0 = _token0;
        token1 = _token1;
        reserve0 = uint112(_reserve0);
        reserve1 = uint112(_reserve1);
        mockPrice = 1e18; // Default 1:1 price
        observationCount = 12; // Default 12 observations
        _fee = 30; // 0.3%
        _feeSplit = 5000; // 50%
        _feeRecipient = msg.sender;
    }

    function getReserves() external view override returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, uint32(block.timestamp));
    }

    function sync() external override {
        // Mock sync function - does nothing in test
        emit Sync(reserve0, reserve1);
    }

    function observationLength() external view override returns (uint256) {
        return observationCount;
    }

    function quote(address tokenIn, uint256 amountIn, uint256 granularity) external view override returns (uint256 amountOut) {
        require(granularity <= observationCount, "Not enough observations");
        if (tokenIn == token0) {
            return amountIn * mockPrice / 1e18;
        } else {
            return amountIn * 1e18 / mockPrice;
        }
    }

    function current(address tokenIn, uint256 amountIn) external view override returns (uint256 amountOut) {
        return this.quote(tokenIn, amountIn, 1);
    }

    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 points,
        uint256 window
    ) external view override returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](points);
        for (uint256 i = 0; i < points; i++) {
            prices[i] = mockPrice;
        }
        return prices;
    }

    function observations(uint256) external view override returns (uint256 timestamp, uint256 reserve0Cumulative, uint256 reserve1Cumulative) {
        return (block.timestamp, 0, 0);
    }

    function initialize(address, address, bool) external override {
        // Do nothing
    }

    function mint(address) external override returns (uint256) {
        return 0;
    }

    function burn(address) external override returns (uint256, uint256) {
        return (0, 0);
    }

    function swap(uint256, uint256, address, bytes calldata) external override {
        // Do nothing
    }

    function skim(address) external override {
        // Do nothing
    }

    function setFeeRecipient(address recipient) external override {
        _feeRecipient = recipient;
    }

    function setFeeSplit(uint256 split) external override {
        _feeSplit = split;
    }

    function setFee(uint256 newFee) external override {
        _fee = newFee;
    }

    function mintFee() external override {
        // Do nothing
    }

    function getAmountOut(uint256 amountIn, address tokenIn) external view override returns (uint256 amountOut) {
        return this.quote(tokenIn, amountIn, 1);
    }

    function metadata() external view override returns (
        uint256 decimals0,
        uint256 decimals1,
        uint256 _reserve0,
        uint256 _reserve1,
        bool stable,
        address t0,
        address t1
    ) {
        return (18, 18, reserve0, reserve1, true, token0, token1);
    }

    function fee() external view override returns (uint256) {
        return _fee;
    }

    function feeSplit() external view override returns (uint256) {
        return _feeSplit;
    }

    function feeRecipient() external view override returns (address) {
        return _feeRecipient;
    }

    // Test helper functions
    function setMockPrice(uint256 _mockPrice) external {
        mockPrice = _mockPrice;
    }

    function setObservationCount(uint256 _count) external {
        observationCount = _count;
    }

    function setReserves(uint256 _reserve0, uint256 _reserve1) external {
        reserve0 = uint112(_reserve0);
        reserve1 = uint112(_reserve1);
    }
} 