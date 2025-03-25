// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title ContractGuard
 * @notice Prevents reentrancy attacks by ensuring functions can only be called once per block
 * @dev Implements a guard mechanism to prevent multiple calls from the same sender or origin in a single block
 */
contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    /**
     * @notice Checks if the transaction origin has already executed a function in this block
     * @return bool indicating if the origin has already executed
     */
    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    /**
     * @notice Checks if the message sender has already executed a function in this block
     * @return bool indicating if the sender has already executed
     */
    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    /**
     * @notice Modifier to ensure a function can only be called once per block
     */
    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}
