// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOracle {
    function update() external;
    function consult(address _token, uint256 _amountIn) external view returns (uint256 amountOut);
    function twap(address _token, uint256 _amountIn) external view returns (uint256 _amountOut);
} 