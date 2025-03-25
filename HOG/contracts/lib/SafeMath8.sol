// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title SafeMath8
 * @notice Wrappers over Solidity's arithmetic operations with added overflow checks for uint8
 * @dev Implements safe arithmetic operations for uint8 values
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath8` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath8 {
    /**
     * @notice Returns the addition of two unsigned integers, reverting on overflow
     * @param a First number
     * @param b Second number
     * @return The sum of a and b
     * @dev Counterpart to Solidity's `+` operator
     */
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @notice Returns the subtraction of two unsigned integers, reverting on overflow
     * @param a First number
     * @param b Second number
     * @return The difference of a and b
     * @dev Counterpart to Solidity's `-` operator
     */
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @notice Returns the subtraction of two unsigned integers, reverting with custom message on overflow
     * @param a First number
     * @param b Second number
     * @param errorMessage Custom error message
     * @return The difference of a and b
     * @dev Counterpart to Solidity's `-` operator
     */
    function sub(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b <= a, errorMessage);
        uint8 c = a - b;
        return c;
    }

    /**
     * @notice Returns the multiplication of two unsigned integers, reverting on overflow
     * @param a First number
     * @param b Second number
     * @return The product of a and b
     * @dev Counterpart to Solidity's `*` operator
     */
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) {
            return 0;
        }

        uint8 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @notice Returns the integer division of two unsigned integers, reverting on division by zero
     * @param a First number
     * @param b Second number
     * @return The quotient of a and b
     * @dev Counterpart to Solidity's `/` operator
     */
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @notice Returns the integer division of two unsigned integers, reverting with custom message on division by zero
     * @param a First number
     * @param b Second number
     * @param errorMessage Custom error message
     * @return The quotient of a and b
     * @dev Counterpart to Solidity's `/` operator
     */
    function div(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b > 0, errorMessage);
        uint8 c = a / b;
        return c;
    }

    /**
     * @notice Returns the remainder of dividing two unsigned integers, reverting on division by zero
     * @param a First number
     * @param b Second number
     * @return The remainder of a divided by b
     * @dev Counterpart to Solidity's `%` operator
     */
    function mod(uint8 a, uint8 b) internal pure returns (uint8) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @notice Returns the remainder of dividing two unsigned integers, reverting with custom message on division by zero
     * @param a First number
     * @param b Second number
     * @param errorMessage Custom error message
     * @return The remainder of a divided by b
     * @dev Counterpart to Solidity's `%` operator
     */
    function mod(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
