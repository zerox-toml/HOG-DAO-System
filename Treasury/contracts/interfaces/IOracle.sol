// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title IOracle
 * @notice Interface for price oracles in the protocol
 * @dev Defines the core functionality for price updates and consultations
 */
interface IOracle {
    /**
     * @notice Updates the oracle's price data
     */
    function update() external;

    /**
     * @notice Consults the current price for a token
     * @param _token The token to get the price for
     * @param _amountIn The amount of tokens to get the price for
     * @return amountOut The price in terms of the quote token
     */
    function consult(address _token, uint256 _amountIn) external view returns (uint256 amountOut);

    /**
     * @notice Gets the time-weighted average price for a token
     * @param _token The token to get the TWAP for
     * @param _amountIn The amount of tokens to get the TWAP for
     * @return _amountOut The TWAP in terms of the quote token
     */
    function twap(address _token, uint256 _amountIn) external view returns (uint256 _amountOut);
}
