// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public hog;
    address public operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event HogAddressUpdated(address indexed oldHog, address indexed newHog);
    event EmergencyWithdraw(address indexed token, address indexed to, uint256 amount);

    modifier onlyOperator() {
        require(msg.sender == operator, "operator: caller is not the operator");
        _;
    }

    constructor(address _hog) {
        require(_hog != address(0), "HOG address cannot be zero");
        hog = _hog;
        operator = msg.sender;
    }

    function transferOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(operator, newOperator);
        operator = newOperator;
    }

    function setHog(address _hog) public onlyOperator {
        require(_hog != address(0), "HOG address cannot be zero");
        address oldHog = hog;
        hog = _hog;
        emit HogAddressUpdated(oldHog, _hog);
    }

    function deposit(address token, uint256 amount) public onlyOperator nonReentrant {
        require(token != address(0), "Token address cannot be zero");
        require(amount > 0, "Amount must be greater than 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address token, address to, uint256 amount) public onlyOperator nonReentrant {
        require(token != address(0), "Token address cannot be zero");
        require(to != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(token).safeTransfer(to, amount);
    }

    function emergencyWithdraw(address token, address to) public onlyOperator nonReentrant {
        require(token != address(0), "Token address cannot be zero");
        require(to != address(0), "Recipient cannot be zero address");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(token).safeTransfer(to, balance);
        emit EmergencyWithdraw(token, to, balance);
    }

    function governanceRecoverUnsupported(IERC20 token, address to) public onlyOwner nonReentrant {
        require(to != address(0), "Recipient cannot be zero address");
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to recover");
        token.safeTransfer(to, balance);
    }
} 