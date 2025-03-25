// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOperator {
    function operator() external view returns (address);
    function isOperator() external view returns (bool);
} 