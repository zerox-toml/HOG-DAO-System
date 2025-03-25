// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPool.sol";
import "./owner/Operator.sol";

contract Oracle is Operator {
    using SafeMath for uint256;

    address public token0;
    address public token1;
    IPool public pair;

    constructor(IPool _pair) public {
        pair = _pair;
        token0 = pair.token0();
        token1 = pair.token1();
        uint256 reserve0;
        uint256 reserve1;
        (reserve0, reserve1, ) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: No reserves");
    }

    function update() external {
        pair.sync();
    }

    function consult(
        address _token,
        uint256 _amountIn
    ) external view returns (uint256 amountOut) {
        if (_token == token0) {
            amountOut = _quote(_token, _amountIn, 12);
        } else {
            require(_token == token1, "Oracle: Invalid token");
            amountOut = _quote(_token, _amountIn, 12);
        }
    }

    function twap(
        address _token,
        uint256 _amountIn
    ) external view returns (uint256 amountOut) {
        if (_token == token0) {
            amountOut = _quote(_token, _amountIn, 2);
        } else {
            require(_token == token1, "Oracle: Invalid token");
            amountOut = _quote(_token, _amountIn, 2);
        }
    }

    // Note the window parameter is removed as its always 1 (30min), granularity at 12 for example is (12 * 30min) = 6 hours
    function _quote(
        address tokenIn,
        uint256 amountIn,
        uint256 granularity // number of observations to query
    ) internal view returns (uint256 amountOut) {
        uint256 observationLength = IPool(pair).observationLength();
        require(
            granularity <= observationLength,
            "Oracle: Not enough observations"
        );

        uint256 price = IPool(pair).quote(tokenIn, amountIn, granularity);
        amountOut = price;
    }
}