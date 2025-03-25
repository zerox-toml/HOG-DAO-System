// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Operator
 * @notice Manages operator privileges for the protocol
 * @dev Implements operator functionality with transfer and renounce capabilities
 */
contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    /**
     * @notice Gets the current operator address
     * @return address of the operator
     */
    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @notice Modifier to restrict function access to the operator only
     */
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    /**
     * @notice Checks if the caller is the operator
     * @return bool indicating if the caller is the operator
     */
    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    /**
     * @notice Transfers operator privileges to a new address
     * @param newOperator_ The new operator address
     */
    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    /**
     * @notice Internal function to transfer operator privileges
     * @param newOperator_ The new operator address
     */
    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(_operator, newOperator_);
        _operator = newOperator_;
    }

    /**
     * @notice Renounces operator privileges
     */
    function _renounceOperator() public onlyOwner {
        emit OperatorTransferred(_operator, address(0));
        _operator = address(0);
    }
}
