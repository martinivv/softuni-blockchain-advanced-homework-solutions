// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IOptimizedStakingContract} from "./IOptimizedStakingContract.sol";
import {IERC20} from "./IERC20.sol";

error ZeroAmount();
error NotEnoughStaked();

/**
 * @dev The original contract had a CRITICAL bug: in `updateReward()` it used memory instead of storage
 *      for `UserInfo` (or `StakerData` here), meaning reward calculations were done but never saved to storage
 *
 *
 * THIS CONTRACT IS USED FOR EDUCATIONAL PURPOSES ONLY.
 * DO NOT USE IT IN PRODUCTION ENVIRONMENTS.
 */
contract OptimizedStakingContract is IOptimizedStakingContract {
    IERC20 public immutable STAKING_TOKEN;
    uint256 public immutable REWARD_RATE;

    mapping(address staker => StakerData) public stakers;

    constructor(address _stakingToken, uint256 _rewardRate) {
        STAKING_TOKEN = IERC20(_stakingToken);
        REWARD_RATE = _rewardRate;
    }

    /* ============================================================================================== */
    /*                                         PUBLIC METHODS                                         */
    /* ============================================================================================== */

    function stake(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        StakerData storage staker = stakers[msg.sender];

        STAKING_TOKEN.transferFrom(msg.sender, address(this), amount);

        _updateReward(staker);
        staker.stakedAmount += amount;

        emit Stake(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        StakerData storage staker = stakers[msg.sender];
        if (staker.stakedAmount < amount) revert NotEnoughStaked();

        _updateReward(staker);
        staker.stakedAmount -= amount;

        STAKING_TOKEN.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function claimReward() external {
        StakerData storage staker = stakers[msg.sender];

        _updateReward(staker);

        uint256 reward = staker.rewardsAccumulated;

        if (reward > 0) {
            staker.rewardsAccumulated = 0;

            STAKING_TOKEN.transfer(msg.sender, reward);

            emit RewardClaim(msg.sender, reward);
        }
    }

    /* ============================================================================================== */
    /*                                          VIEW METHODS                                          */
    /* ============================================================================================== */

    function getPendingReward(address account) external view returns (uint256 pending) {
        StakerData storage staker = stakers[account];

        pending = staker.rewardsAccumulated;

        if (staker.stakedAmount > 0) {
            pending += _calculateNewRewards(staker.stakedAmount, staker.lastUpdateBlock);
        }
    }

    /* ============================================================================================== */
    /*                                         PRIVATE METHODS                                        */
    /* ============================================================================================== */

    function _updateReward(StakerData storage staker) private {
        if (staker.stakedAmount > 0) {
            staker.rewardsAccumulated += _calculateNewRewards(staker.stakedAmount, staker.lastUpdateBlock);
        }
        staker.lastUpdateBlock = block.number;
    }

    function _calculateNewRewards(uint256 _stakedAmount, uint256 _lastUpdateBlock) private view returns (uint256) {
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        return (_stakedAmount * REWARD_RATE * blocksSinceLastUpdate) / 1e18;
    }
}
