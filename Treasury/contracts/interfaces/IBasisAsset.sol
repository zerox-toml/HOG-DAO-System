// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title IBasisAsset
 * @notice Interface for basis asset tokens in the protocol
 * @dev Defines the core functionality for minting, burning, and operator management
 */
interface IBasisAsset {
    /**
     * @notice Mints new tokens to a recipient
     * @param recipient The address to receive the tokens
     * @param amount The amount of tokens to mint
     * @return bool indicating success
     */
    function mint(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Burns tokens from the caller's balance
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burns tokens from a specified address
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address from, uint256 amount) external;

    /**
     * @notice Checks if the caller is the operator
     * @return bool indicating if the caller is the operator
     */
    function isOperator() external returns (bool);

    /**
     * @notice Gets the current operator address
     * @return address of the operator
     */
    function operator() external view returns (address);

    /**
     * @notice Transfers operator privileges to a new address
     * @param newOperator_ The new operator address
     */
    function transferOperator(address newOperator_) external;
}
