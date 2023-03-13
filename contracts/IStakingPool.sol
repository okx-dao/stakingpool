// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
/// 质押合约接口
interface IStakingPool {
    /// 当代币被质押时触发（原生代币或ERC20代币）
    event TokensStaked(address indexed staker, uint256 amount);

    /// 当质押的代币被提取时触发 （原生代币或ERC20代币）
    event TokensWithdrawn(address indexed staker, uint256 amount);

    /// 当质押者获取质押奖励时触发
    event RewardsClaimed(address indexed staker, uint256 rewardAmount);

    /// 当合约管理员更新timeUnit时触发（生成奖励频率）
    event UpdatedTimeUnit(uint256 oldTimeUnit, uint256 newTimeUnit);

    /// 当合约管理员更新rewardsPerUnitTime时触发 （每单位时间产生多少奖励）
    event UpdatedRewardRatio(
        uint256 oldNumerator, /// 老的奖励比率分子
        uint256 newNumerator, /// 新的奖励比率分子
        uint256 oldDenominator, /// 老的奖励比率分母
        uint256 newDenominator /// 新的奖励比率分母
    );

    /// 当合约管理员更新最低质押金额时触发
    event UpdatedMinStakeAmount(uint256 oldAmount, uint256 newAmount);

    /// 质押者信息数据结构
    struct Staker {
        uint256 amountStaked; /// 质押者质押的代币总数
        uint256 timeOfLastUpdate; /// 上一次奖励更新时间戳
        uint256 unclaimedRewards; /// 已累积的奖励，但用户尚未领取
        uint256 conditionIdOflastUpdate; /// 最后更新使用的奖励生成参数条件Id
    }

    /// 质押产生奖励条件约束
    struct StakingCondition {
        uint256 timeUnit; /// 指定的时间单位，以秒为单位。可以设置为1秒、1天、1小时等
        uint256 rewardRatioNumerator; /// 奖励比率分子（比如每质押20个ETH产生1个LPETH，则此参数应设置为1）
        uint256 rewardRatioDenominator; /// 奖励比率分母 （比如每质押20个ETH产生1个LPETH，则此参数应设置为20）
        uint256 startTimestamp; /// 条件开始时间戳
        uint256 endTimestamp; /// 条件结束时间戳
    }

    /// 质押代币
    function stake(uint256 amount) external payable;

    /// 赎回质押代币
    function withdraw(uint256 amount) external;

    /// 领取累积的奖励
    function claimRewards() external;

    /// 查看用户的质押金额和总奖励
    function getStakeInfo(address staker) external view returns (uint256 _tokensStaked, uint256 _rewards);
}