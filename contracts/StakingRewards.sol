// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "./AbsStakingPool.sol";
import "./LPETHToken.sol";
import { CurrencyTransferLib } from "./CurrencyTransferLib.sol";

contract StakingRewards is Ownable, AbsStakingPool {

    address public rewardToken;

    uint256 private rewardTokenBalance;

    constructor(
        uint256 _timeUnit,
        uint256 _rewardRatioNumerator,
        uint256 _rewardRatioDenominator,
        address _stakingToken,
        address _rewardToken,
        address _nativeTokenWrapper
    )
    AbsStakingPool(
        _nativeTokenWrapper,
        _stakingToken,
        _stakingToken == CurrencyTransferLib.NATIVE_TOKEN ? 18 : IERC20Metadata(_stakingToken).decimals(),
        _rewardToken == CurrencyTransferLib.NATIVE_TOKEN ? 18 : IERC20Metadata(_rewardToken).decimals()
    )
    {
        _transferOwnership(msg.sender);
        _setStakingCondition(_timeUnit, _rewardRatioNumerator, _rewardRatioDenominator);

        require(_rewardToken != _stakingToken, "Reward Token and Staking Token can't be same.");
        rewardToken = _rewardToken;
    }

    receive() external payable virtual {
        require(msg.sender == nativeTokenWrapper, "caller not native token wrapper.");
    }

    function depositRewardTokens(uint256 _amount) external payable virtual nonReentrant {
        _depositRewardTokens(_amount);
    }

    function withdrawRewardTokens(uint256 _amount) external virtual nonReentrant {
        _withdrawRewardTokens(_amount);
    }

    function getRewardTokenBalance() external view virtual override returns (uint256) {
        return rewardTokenBalance;
    }

    function _mintRewards(address _staker, uint256 _rewards) internal virtual override {
        LPETHToken(rewardToken).mint(_staker, _rewards);
//        require(_rewards <= rewardTokenBalance, "Not enough reward tokens");
//        rewardTokenBalance -= _rewards;
//        CurrencyTransferLib.transferCurrencyWithWrapper(
//            rewardToken,
//            address(this),
//            _staker,
//            _rewards,
//            nativeTokenWrapper
//        );
    }

    function _depositRewardTokens(uint256 _amount) internal virtual {
        require(msg.sender == owner(), "Not authorized");

        address _rewardToken = rewardToken == CurrencyTransferLib.NATIVE_TOKEN ? nativeTokenWrapper : rewardToken;

        uint256 balanceBefore = IERC20(_rewardToken).balanceOf(address(this));
        CurrencyTransferLib.transferCurrencyWithWrapper(
            rewardToken,
            msg.sender,
            address(this),
            _amount,
            nativeTokenWrapper
        );
        uint256 actualAmount = IERC20(_rewardToken).balanceOf(address(this)) - balanceBefore;

        rewardTokenBalance += actualAmount;
    }

    function _withdrawRewardTokens(uint256 _amount) internal virtual {
        require(msg.sender == owner(), "Not authorized");

        rewardTokenBalance = _amount > rewardTokenBalance ? 0 : rewardTokenBalance - _amount;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            rewardToken,
            address(this),
            msg.sender,
            _amount,
            nativeTokenWrapper
        );

        address _stakingToken = stakingToken == CurrencyTransferLib.NATIVE_TOKEN ? nativeTokenWrapper : stakingToken;
        require(
            IERC20(_stakingToken).balanceOf(address(this)) >= stakingTokenBalance,
            "Staking token balance reduced."
        );
    }

    function _canSetStakeConditions() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}