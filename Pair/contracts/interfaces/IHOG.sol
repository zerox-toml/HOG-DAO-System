// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHOG {
    function getTaxRate() external view returns (uint256);
    function taxRecipient() external view returns (address);
} 