// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Note that this pool has no minter key of HOG (rewards).
// Instead, the governance will call HOG distributeReward method and send reward to this pool at the beginning.

contract HogGenesisRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;
    address public feeAddress;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. HOG to distribute.
        uint256 lastRewardTime; // Last time that HOG distribution occurs.
        uint16 depositFeeBP; //depositfee
        uint256 accHogPerShare; // Accumulated HOG per share, times 1e18. See below.
        bool isStarted; // if lastRewardBlock has passed
    }

    IERC20 public hog;
    address public mim;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when HOG mining starts.
    uint256 public poolStartTime;

    // The time when HOG mining ends.
    uint256 public poolEndTime;

    // TESTNET
    uint256 public hogPerSecond = 0.66667 ether; // 2400 HOG / (1h * 60min * 60s)
    uint256 public runningTime = 1 hours; // 1 hours
    uint256 public constant TOTAL_REWARDS = 2400 ether;
    // END TESTNET

    // MAINNET
    // uint256 public hogPerSecond = 0.138888888 ether; // 12000 HOG / (24h * 60min * 60s)
    // uint256 public runningTime = 1 days; // 1 days
    // uint256 public constant TOTAL_REWARDS = 12000 ether;
    // END MAINNET

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _hog,
        address _mim,
        address _feeAddress,
        uint256 _poolStartTime
    ) {
        require(block.timestamp < _poolStartTime, "late");
        if (_hog != address(0)) hog = IERC20(_hog);
        if (_mim != address(0)) mim = _mim;
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        operator = msg.sender;
        feeAddress = _feeAddress;
    }

    modifier onlyOperator() {
        require(
            operator == msg.sender,
            "HogGenesisPool: caller is not the operator"
        );
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(
                poolInfo[pid].token != _token,
                "HogGenesisPool: existing pool?"
            );
        }
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint16 _depositFeeBP
    ) public onlyOperator {
        require(_depositFeeBP <= 100, "add: invalid deposit fee basis points");

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
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                accHogPerShare: 0,
                isStarted: _isStarted,
                depositFeeBP: _depositFeeBP
            })
        );
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's HOG allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP
    ) public onlyOperator {
        require(_depositFeeBP <= 100, "set: invalid deposit fee basis points");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(
        uint256 _fromTime,
        uint256 _toTime
    ) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime)
                return poolEndTime.sub(poolStartTime).mul(hogPerSecond);
            return poolEndTime.sub(_fromTime).mul(hogPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime)
                return _toTime.sub(poolStartTime).mul(hogPerSecond);
            return _toTime.sub(_fromTime).mul(hogPerSecond);
        }
    }

    // View function to see pending HOG on frontend.
    function pendingHog(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accHogPerShare = pool.accHogPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _hogReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            accHogPerShare = accHogPerShare.add(
                _hogReward.mul(1e18).div(tokenSupply)
            );
        }
        return user.amount.mul(accHogPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _hogReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            pool.accHogPerShare = pool.accHogPerShare.add(
                _hogReward.mul(1e18).div(tokenSupply)
            );
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user
                .amount
                .mul(pool.accHogPerShare)
                .div(1e18)
                .sub(user.rewardDebt);
            if (_pending > 0) {
                safeHogTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            if (address(pool.token) == mim) {
                user.amount = user.amount.add(_amount.mul(9900).div(10000));
            }
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.token.safeTransfer(feeAddress, depositFee);
                // pool.lpToken.safeTransfer(vaultAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accHogPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accHogPerShare).div(1e18).sub(
            user.rewardDebt
        );
        if (_pending > 0) {
            safeHogTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accHogPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe HOG transfer function, just in case a rounding error causes pool to not have enough HOG.
    function safeHogTransfer(address _to, uint256 _amount) internal {
        uint256 _hogBalance = hog.balanceOf(address(this));
        if (_hogBalance > 0) {
            if (_amount > _hogBalance) {
                hog.safeTransfer(_to, _hogBalance);
            } else {
                hog.safeTransfer(_to, _amount);
            }
        }
    }
    function setFeeAddress(address _feeAddress) external onlyOperator {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }
    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (HOG or lps) if less than 90 days after pool ends
            require(_token != hog, "hog");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }
}
