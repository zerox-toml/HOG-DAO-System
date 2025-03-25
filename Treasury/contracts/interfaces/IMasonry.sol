// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title IMasonry
 * @notice Interface for the Masonry staking contract
 * @dev Defines the core functionality for staking, rewards, and governance
 */
interface IMasonry {
    /**
     * @notice Gets the staked balance of an address
     * @param _andras The address to check
     * @return uint256 The staked balance
     */
    function balanceOf(address _andras) external view returns (uint256);

    /**
     * @notice Gets the earned rewards of an address
     * @param _andras The address to check
     * @return uint256 The earned rewards
     */
    function earned(address _andras) external view returns (uint256);

    /**
     * @notice Checks if an address can withdraw their stake
     * @param _andras The address to check
     * @return bool indicating if withdrawal is allowed
     */
    function canWithdraw(address _andras) external view returns (bool);

    /**
     * @notice Checks if an address can claim their rewards
     * @param _andras The address to check
     * @return bool indicating if claiming is allowed
     */
    function canClaimReward(address _andras) external view returns (bool);

    /**
     * @notice Gets the current epoch number
     * @return uint256 The current epoch
     */
    function epoch() external view returns (uint256);

    /**
     * @notice Gets the timestamp of the next epoch
     * @return uint256 The next epoch timestamp
     */
    function nextEpochPoint() external view returns (uint256);

    /**
     * @notice Gets the current TOMB token price
     * @return uint256 The current price
     */
    function getTombPrice() external view returns (uint256);

    /**
     * @notice Sets the operator address
     * @param _operator The new operator address
     */
    function setOperator(address _operator) external;

    /**
     * @notice Sets the lockup periods for withdrawals and rewards
     * @param _withdrawLockupEpochs The number of epochs for withdrawal lockup
     * @param _rewardLockupEpochs The number of epochs for reward lockup
     */
    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    /**
     * @notice Stakes tokens in the contract
     * @param _amount The amount of tokens to stake
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Withdraws staked tokens
     * @param _amount The amount of tokens to withdraw
     */
    function withdraw(uint256 _amount) external;

    /**
     * @notice Exits the staking position by withdrawing all tokens and claiming rewards
     */
    function exit() external;

    /**
     * @notice Claims earned rewards
     */
    function claimReward() external;

    /**
     * @notice Allocates seigniorage rewards to stakers
     * @param _amount The amount of seigniorage to allocate
     */
    function allocateSeigniorage(uint256 _amount) external;

    /**
     * @notice Recovers unsupported tokens that were sent to the contract
     * @param _token The token to recover
     * @param _amount The amount to recover
     * @param _to The address to send the tokens to
     */
    function governanceRecoverUnsupported(address _token, uint256 _amount, address _to) external;
}
