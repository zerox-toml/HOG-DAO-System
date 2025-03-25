// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPairFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function allPairs(uint index) external view returns (address);
    function stakingFeeHandler() external view returns (address);
    function dibs() external view returns (address);
    function MAX_TREASURY_FEE() external view returns (uint256);
    function stakingNFTFee() external view returns (uint256);
    function isPaused() external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function getInitializable() external view returns (address, address, bool);
    function getFee(bool _stable) external view returns(uint256);
}
