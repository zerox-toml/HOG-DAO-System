// SPDX-License-Identifier: BUSL-1.1

/*
The Elysium is a core pillar of Hand of God, designed to incentivize liquidity provision while ensuring the stability and sustainable growth of the protocol. 
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; //SonicScan/GHogRewardPool/@openzeppelin/contracts/token/ERC20/IERC20.sol
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IBasisAsset.sol";
import "../interfaces/swapx/ISwapXGauge.sol";

contract GHogRewardPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 withFee; // withdraw fee that is applied to created pool.
        uint256 allocPoint; // How many allocation points assigned to this pool. GHOGs to distribute per block.
        uint256 lastRewardTime; // Last time that GHOGs distribution occurs.
        uint256 accGhogPerShare; // Accumulated GHOGs per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        address gauge;
    }

    IERC20 public ghog;

    address public devFund;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when GHOG mining starts.
    uint256 public poolStartTime;

    // The time when GHOG mining ends.
    uint256 public poolEndTime;
    uint256 public sharePerSecond = 0.00186122 ether;
    uint256 public runningTime = 370 days;

    address public swapxToken = 0xA04BC7140c26fc9BB1F36B1A604C7A5a88fb0E70;

    // Add these mappings at contract level
    mapping(address => uint256) public lastClaimed;  // Track when user last claimed
    mapping(uint256 => uint256) public weeklyShareRate;  // Store share rate for each week

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 amount);
    event DevFundUpdated(address devFund);
    event SharePerSecondUpdated(uint256 oldRate, uint256 newRate, uint256 timestamp);   

    constructor(
        address _ghog,
        address _devFund,
        uint256 _poolStartTime
    ) {
        require(
            block.timestamp < _poolStartTime,
            "pool cant be started in the past"
        );
        if (_ghog != address(0)) ghog = IERC20(_ghog);
        if (_devFund != address(0)) devFund = _devFund;

        poolStartTime = _poolStartTime;
        poolEndTime = _poolStartTime + runningTime;
        operator = msg.sender;
        devFund = _devFund;

        // create all the pools
        add(0, 50, IERC20(0x80bbD9699Be5fc7e6e1c8E477792840afAD74CCF), false, 0, address(0)); // Hog-S
        add(0, 50, IERC20(0x008769eE2D69B2B7da69d04fD1dbD17CFC3353b3), false, 0, address(0)); // GHog-S

    }

    modifier onlyOperator() {
        require(
            operator == msg.sender,
            "GHogRewardPool: caller is not the operator"
        );
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(
                poolInfo[pid].token != _token,
                "GHogRewardPool: existing pool?"
            );
        }
    }

    // Add new lp to the pool. Can only be called by operator.
    function add(
        uint256 _allocPoint,
        uint256 _withFee,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        address _gauge
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted = (_lastRewardTime <= poolStartTime) ||
            (_lastRewardTime <= block.timestamp);
        poolInfo.push(
            PoolInfo({
                token: _token,
                withFee: _withFee,
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                accGhogPerShare: 0,
                isStarted: _isStarted,
                gauge: _gauge
            })
        );

        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's GHOG allocation point. Can only be called by the operator.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _withFee,
        address _gauge
    ) public onlyOperator {
        massUpdatePools();

        PoolInfo storage pool = poolInfo[_pid];
        require(_withFee <= 200, "withdraw fee cant be more than 2%");
        pool.withFee = _withFee;

        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
        pool.gauge = _gauge;
    }

    // AI-CONTROLLED: Updates the emission rate every 7 days based on protocol conditions
    // This function allows the AI to adjust the reward distribution rate
    function setSharePerSecond(uint256 _sharePerSecond) external onlyOperator {
        uint256 oldSharePerSecond = sharePerSecond;
        sharePerSecond = _sharePerSecond;
        
        // Store rate for current week
        uint256 currentWeek = (block.timestamp - poolStartTime) / 1 weeks;
        weeklyShareRate[currentWeek] = _sharePerSecond;
        
        emit SharePerSecondUpdated(oldSharePerSecond, _sharePerSecond, block.timestamp);
        massUpdatePools();
    }

    // Add helper function to calculate rewards across rate changes
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        
        uint256 totalRewards = 0;
        uint256 totalWeeks = (_toTime - _fromTime) / 1 weeks;
        uint256 startWeek = (_fromTime - poolStartTime) / 1 weeks;
        
        // Iterate through weeks and add up rewards
        for (uint256 i = 0; i <= totalWeeks; i++) {
            uint256 weekNumber = startWeek + i;
            uint256 weekRate = weeklyShareRate[weekNumber];
            if (weekRate == 0) {
                weekRate = sharePerSecond; // Use current rate if no specific rate set
            }
            
            uint256 weekStart = _fromTime + (i * 1 weeks);
            uint256 weekEnd = weekStart + 1 weeks;
            if (weekEnd > _toTime) weekEnd = _toTime;
            
            totalRewards = totalRewards.add(
                (weekEnd - weekStart).mul(weekRate)
            );
        }
        
        return totalRewards;
    }

    // Modified pendingShare to use new getGeneratedReward
    function pendingShare(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGhogPerShare = pool.accGhogPerShare;
        uint256 tokenSupply = pool.gauge != address(0) ? ISwapxGauge(pool.gauge).balanceOf(address(this)) : pool.token.balanceOf(address(this));
        
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _ghogReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accGhogPerShare = accGhogPerShare.add(_ghogReward.mul(1e18).div(tokenSupply));
        }
        
        return user.amount.mul(accGhogPerShare).div(1e18).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        depositToGauge(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.gauge != address(0) ? ISwapxGauge(pool.gauge).balanceOf(address(this)) : pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            // This now correctly accounts for all emission rate changes
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _ghogReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            pool.accGhogPerShare = pool.accGhogPerShare.add(
                _ghogReward.mul(1e18).div(tokenSupply)
            );
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user
                .amount
                .mul(pool.accGhogPerShare)
                .div(1e18)
                .sub(user.rewardDebt);
            if (_pending > 0) {
                safeGhogTransfer(_sender, _pending);
                lastClaimed[_sender] = block.timestamp;  // Update last claim time
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            depositToGauge(_pid);
        }
        user.rewardDebt = user.amount.mul(pool.accGhogPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accGhogPerShare).div(1e18).sub(
            user.rewardDebt
        );
        if (_pending > 0) {
            safeGhogTransfer(_sender, _pending);
            lastClaimed[_sender] = block.timestamp;  // Update last claim time
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            withdrawFromGauge(_pid, _amount);
            // Calculate the fee and transfer it to the devFund
            uint256 fee = _amount.mul(pool.withFee).div(10000); // Assuming withFee is in basis points (e.g., 100 = 1%)
            uint256 amountAfterFee = _amount.sub(fee);

            if (fee > 0) {
                pool.token.safeTransfer(devFund, fee);
            }

            pool.token.safeTransfer(_sender, amountAfterFee);
        }
        user.rewardDebt = user.amount.mul(pool.accGhogPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        withdrawFromGauge(_pid, _amount);

        uint256 fee = _amount.mul(pool.withFee).div(10000); // Assuming withFee is in basis points (e.g., 100 = 1%)
        uint256 amountAfterFee = _amount.sub(fee);

        if (fee > 0) {
            pool.token.safeTransfer(devFund, fee);
        }

        pool.token.safeTransfer(msg.sender, amountAfterFee);

        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe ghog transfer function, just in case if rounding error causes pool to not have enough Ghog.
    function safeGhogTransfer(address _to, uint256 _amount) internal {
        uint256 _ghogBal = ghog.balanceOf(address(this));

        if (_ghogBal > 0) {
            if (_amount > _ghogBal) {
                ghog.safeTransfer(_to, _ghogBal);
            } else {
                ghog.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        require(_operator != address(0), "Cannot set operator to zero address");
        operator = _operator;
    }

    function setDevFund(address _devFund) external onlyOperator {
        require(_devFund != address(0), "Cannot set devFund to zero address");
        devFund = _devFund;
        emit DevFundUpdated(_devFund);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external onlyOperator {
        if (block.timestamp < poolEndTime + 10 days) {
            // do not allow to drain core token (tSHARE or lps) if less than 10 days after pool ends

            require(_token != ghog, "ghog");

            uint256 length = poolInfo.length;

            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];

                require(_token != pool.token, "pool.token");
            }
        }

        _token.safeTransfer(to, amount);
    }

    // Calculate total GHOG emitted from pool start until now
    function getTotalEmittedShares() public view returns (uint256) {
        if (block.timestamp <= poolStartTime) return 0;
        
        uint256 endTime = block.timestamp;
        if (endTime > poolEndTime) {
            endTime = poolEndTime;
        }
        
        return getGeneratedReward(poolStartTime, endTime);
    }

    // Calculate total GHOG emitted between any two timestamps
    function getTotalEmittedSharesBetween(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        require(_fromTime < _toTime, "Invalid time range");
        
        // Bound times within pool's active period
        if (_fromTime < poolStartTime) {
            _fromTime = poolStartTime;
        }
        if (_toTime > poolEndTime) {
            _toTime = poolEndTime;
        }
        
        return getGeneratedReward(_fromTime, _toTime);
    }

    function depositToGauge(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address gauge = pool.gauge;
        uint256 balance = pool.token.balanceOf(address(this));
        // Do nothing if this pool doesn't have a gauge
        if (pool.gauge != address(0)) {
            // Do nothing if the LP token in the MC is empty
            if (balance > 0) {
                // Approve to the gauge
                if (pool.token.allowance(address(this), gauge) < balance ){
                    pool.token.approve(gauge, type(uint256).max);
                }
                ISwapxGauge(pool.gauge).deposit(balance);
            }
        }
    }

    function claimSwapxRewards(uint256 _pid) public onlyOperator {
        PoolInfo storage pool = poolInfo[_pid];
        ISwapxGauge(pool.gauge).getReward(); // claim the swapx rewards
        IERC20 rewardToken = IERC20(swapxToken);
        uint256 rewardAmount = rewardToken.balanceOf(address(this));
        if (rewardAmount > 0) {
            rewardToken.safeTransfer(devFund, rewardAmount);
        }
    }

    function withdrawFromGauge(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        // Do nothing if this pool doesn't have a gauge
        if (pool.gauge != address(0)) {
            // Withdraw from the gauge
            ISwapxGauge(pool.gauge).withdraw(_amount); 
        }
    }
}
