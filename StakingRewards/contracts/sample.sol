// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Sample is ERC20 {
    constructor() ERC20("Sample", "SAMPLE") {
        _mint(msg.sender, 1000000000000000000000000);
    }
}