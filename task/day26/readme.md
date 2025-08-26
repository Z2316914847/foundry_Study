需求：
    编写 StakingPool 合约，实现 Stake 和 Unstake 方法，允许任何人质押ETH来赚钱 KK Token。其中 KK Token 是每一个区块产出 10 个，产出的 KK Token 需要根据质押时长和质押数量来公平分配。

    （加分项）用户质押 ETH 的可存入的一个借贷市场赚取利息.

    参考思路：找到 借贷市场 进行一笔存款，然后查看调用的方法，在 Stake 中集成该方法

思路：
  注意：区块产生的奖励主动发给StakingPool合约
  更新奖励池：每次用户操作质押、解质押、领取奖励都会更新奖励池, 质押获得的token都会发给用户
  质押
    1.首次质押：更新这些内容：用户.token = msg.value, 用户.rewardDebt=0, 用户.startTime = block.timestamp, 总质押 += msg.value， 累计份额=0，最新区块=block.number
    2.非首次质押：
      1.用户第一次质押：更新这些内容：用户.token += msg.value, 用户.rewardDebt=0, 用户.startTime = block.timestamp,累计份额，最新区块=block.number
      2.用户第二次质押：更新这些内容：用户.token += msg.value, 用户.rewardDebt=0, 用户.startTime = block.timestamp,累计份额，最新区块=block.number，发送添加质押之前的奖励给用户，用户.rewardDebt = 累计 - 用户.rewardDebt


问题：
  1.累计份额会有很多小数，累计份额先扩大x倍，在返回奖励时在除以x倍。避免了精度损失
  2.更新累计份额时，为什么要判断：block.number <= lastRewardBlock。因为lastRewardBlock有关累计份额，防止极端情况lastRewardBlock>block.number，导致累计份额计算错误(丢失奖励：因为lastRewardBlock>block.number，会导致accRewardPerShare -=最新accRewardPerShare )，所以判断，防止奖励持续丢失。
  3.sushi源代码带查看 - 质押 - 获取奖励
  4.compound源代码带查看 - 借贷

