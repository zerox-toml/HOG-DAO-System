// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GHOG is ERC20Burnable, Ownable {
    address public operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() ERC20("GHOG", "GHOG") {
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "operator: caller is not the operator");
        _;
    }

    function transferOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(operator, newOperator);
        operator = newOperator;
    }

    function mint(address to, uint256 amount) public onlyOperator returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        _burn(account, amount);
    }
} 