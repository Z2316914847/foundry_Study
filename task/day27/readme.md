实现一个通缩的 Token （ERC20）， 用来理解 rebase 型 Token 的实现原理：
    起始发行量为 1 亿，税后每过一年在上一年的发行量基础上下降 1%
    rebase 方法进行通缩
    balanceOf() 可反应通缩后的用户的正确余额。
    需要测试 rebase 后，正确显示用户的余额， 贴出你的 github 代码

注意：
  1.可以记录rebase执行过多少次，添加一个变量即可
  2.x%y：取余，比如：1000%300=100,1000/300=3(触发后面小数被截断)
  3.vm.warp(block.timestamp + 365 days) : 时间戳加上一年的时间
  4.vm.roll(block.number + 1) : 区块高度加1，即下一区块


## ample项目结构介绍
  1.核心合约：
    UFragments：ERC20代币合约、
    MedianOracle：预言机合约、
    UFragmentsPolicy：控制算法（通常是PID控制器），用于计算每次Rebase的幅度。它最终调用 Orchestrator 来触发rebase
    Orchestrator：协调UFragments和UFragmentsPolicy合约
    WAMPL：这是一个 “包装”（Wrapped）AMPL 的合约，类似于WETH（包装以太坊）。
  2.一次典型的rebase流程：
    1.（获取数据）UFragmentsPolicy 向 MedianOracle 查询AMPL的TWAP价格 
    2.（做出决策）UFragmentsPolicy 内部的算法比较市价和目标价，计算出需要调整的供应量 supplyDelta（例如，需要减少2%的供应）。
    3.（发起指令）UFragmentsPolicy 调用 Orchestrator 的方法，并传入 supplyDelta。
    4.（检查并执行） Orchestrator 检查是否满足条件（如是否已过24小时），如果满足，则调用 UFragments.rebase(supplyDelta)
    5.（状态更新）UFragments 合约内部更新 rebaseFactor，从此以后所有用户的 balanceOf() 查询结果都会按新的比例显示。

