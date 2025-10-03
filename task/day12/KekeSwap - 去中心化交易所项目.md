

## KekeSwap - 去中心化交易所项目

##### 项目描述：

```solidity
KekeSwap 是一个完整的去中心化交易所（DEX），目标用户是 DeFi 用户和流动性提供者。
该项目包括 MEME token发射平台,AMM 自动做市商交易、多层次流动性挖矿、代币质押奖
励和等模块功能，旨在为目标用户解决去中心化交易流动性不足、收益机制单一等问题，为用
户提供安全高效的 DeFi 交易和收益服务
```

##### 核心贡献：

- 主导 AMM 内核与 Router 的架构与性能优化，基于 CREATE2 的确定性 Pair 部署与多
  跳批量接口，实现交易路径一次打包执行并兼容 FOT 代币，降低综合 Gas 与失败率
- 设计并实现双重挖矿与二次质押经济模型，提供时间衰减的动态奖励分配，增强长期参
  与激励与抗鲸鱼效应。
- 合约优化：对合约进行性能优化和安全审计，提升合约的执行效率和安全性

##### 项目难点

- 高性能AMM交易系统优化（技术挑战 : 传统 AMM 系统 Gas 消耗高，交易成本昂贵 解决方案 ）
  - 确定性地址&预计算Pair：使用create2，以 keccak256(abi.encodepacked( token0_addr, token1_addr)) 作为 salt，部署部署 Pair，支持离线预测计算 Pair 地址与减少部署与首次交互开销。
    - 支持离线预测计算地址：预先知道地址
    - 减少部署开销(减少一次sload)：意思是：
      - 假设使用create部署合约：用户A部署Pair合约后，用户B进行交易/添加流动性，必须去factory调用getPair(TokenA,TokenB)，那马factory合约必须维护一个映射，那么后面用户在 Router 每次地址查询，都要执行一次额外的 Sload 操作，这就会消耗很多gas。
      - 使用create2部署合约：Router 每次查询地址，不必调用factory合约中的方法，可以直接在 Router 合约中预测合约地址，每次查询减少一次 Sload，添加流动性是，减少Sstore。
    - 首次交互开销：create需要多一步判断，而 create2 直接交互。减少判断这一步，降低开销。
  - Gas优化：

    - 存储布局优化：
      - pair 合约将 reserve0、reserve1、blockTimetampLast 打包早同一存储槽中，使得 累计价格 存储槽也得到改善，并通过 _update 精确更新，减少 Sstore 次数，优化 swap/mint/burn状态写入成本。
    - 设计 getResever()函数
      - 之前设计是：在mint/burn/swap函数直接访问状态变量resever0和resever1，直接从s存储中sload，每一次Gas消耗 = 2900。而mint函数中 调用resever0和resever1变量一共有5次。这回导致gas1消耗量极高
      - 优化后：单独写一个函数 getResever()，在mint/burn/swap函数中使用 getResever()方法，将存储数据拷贝到内存，每次一次访问内存数据Gas消耗 = 3。
    - Router中撤销触发事件
      - 之前设计是：在mint/burn/swap函数中会触发事件。导致gas消耗
      - 优化后：取消Router合约中mint/burn/swap函数中的事件。因为Pair交易对合约中mint/burn/swap函数中已经触发了事件。
  - 撤销流动性/兑换：销毁和兑换时 支持代币转账收费功能 和 兑换时支持多跳。Router 的 *swap* 循环处理 *path* 实现多跳交易。支持兑换时，因多跳产生的转账收费余额结算，避免因 手续费导致金额偏差。提供 ETH 路径与完整add/remove liquidity 函数。
    - swap循环处理Path实现多跳交易：设计amounts和Path两个数组，并根据确切的输入或者确切的输出，实现多条交易
    - 支持兑换时，因多跳产生的转账收费余额结算，避免因 手续费导致金额偏差：处理方法就是，先记录Pair地址在这个token实际余额A，然后用户转账，再次记录转账后pair地址在这个token实际余额B，然后 B-A=C，C就是Pair得到的实际余额，然后根据确切输入 C，计算出用户可能获得的代币数量D，如果代币数量D>=用户能接受的最低值，那就调用pair中的swap，否则，回退交易
  - 滑点与到期保护：所有的 swap 接口包含 amountOutMin/amountInMax与deadline，避免 MEV/滑点风险。
- 多层次流动性挖矿经济模式设计（技术挑战 : 设计可持续的代币经济学模型，防止大户垄断和通胀失控 解决方案 ）
  - 双重挖矿（LP+单币）
  - 动态奖励与时间衰减
  - syrupBar二次质押与复利

##### 项目面试题：

1. 存储槽打包（打包优化和访问优化）：

   ```solidity
   // 两个token在交易对中的储备量
   uint112 private reserve0;
   uint112 private reserve0;
   // 相对于上一次更新储备量的时间间隔？？？？我看源代码并不是时间间隔，而是当下时间
   uint32 private blockTimestampLast;
   ```

2. 在你的项目里，你为什么选择 create2 而不是传统的 create 和更先进的 create3。

   - 他们之间的区别

     - create时传统放入合约部署方式，合约地址是由 部署者地址 + 部署者nonce 决定

       ```soliity
       # 是msg.sender,不是tx.origin,是msg_sender.nonce
       create(sender_address,sender_nonce)
       ```

     - create2（EIP-1014引入），合约地址是由下面因素决定

       ```solidity
       create2(0xff，sender_address，salt，keccak-256(init_code))
       ```

     - create不可以预测 被部署合约地址 而create2可以预测 被部署合约地址：

       - 为什么说 create 不可以预测地址，create2 可以预测地址呢？因为 nonce 不好得知，如果使用 create 部署合约地址的话，那么这个合约地址就不好预测。而 create2 就解决了不好预测地址的缺点。

   - Factory的需求

     - Factory 希望添加流动性时，TokenA—TokenB会生成唯一的交易对合约地址。
       - 如果使用create部署合约的话，TokenA—TokenB首次添加流动性得到一个合约地址A，TokenA—TokenB再次添加流动性得到另一个合约地址B，这就导致每次TokenA—TokenB添加流动性得到的合约地址都不同。
       - 使用create2部署合约的话，就完美解决了create所产生的问题

   - 提到了create3：create3是一个库，create3是结合create和create2。create3部署的合约地址只和salt有关。就算改变被部署的合约代码，只要salt没变，那么被部署的合约地址就不会变。

3. 使用create2相较于create还有什么有点

   ```solidity
   create2比create更省Gas，不管是首次首次添加流动性，还是后续的添加流动性/兑换。原因：项目难点中的第一条。
   ```

4. 提到将`reserve0, reserve1, blockTimestampLast`打包到同一个存储槽进行优化。这是一个非常关键的优化。请详细解释：

   - 原始设计是：将者三个变量占用三个槽
   - 我的优化是：resever0和resever1数据类型变为uint112，blockTimestampLast数据类型uint32
     - 并且设计一个 _update() 方法，在 mint/burn/swap 都有 _update() ，update() 同时修改resever0、resever1、blockTimestampLast，节省Gas：一次读取获取三个变量，一次打包三个变量，写入存储槽中。
   - Gas节省计算（20k-5.8k gas）：

5. 你实现了对FOT（手续费代币）的兼容。这是一个非常棘手的问题。

   -  `swapSupportingFeeOnTransferTokens`函数的核心逻辑是什么？它是如何计算实际收到代币数量的？
   - **挑战**： 在实现多跳交易（`path`）时，如何确保中间跳的FOT代币手续费不会破坏最终输出金额的预期？
   - **用户体验**： 这个设计是否会导致用户的`amountOutMin`参数失效？你是如何在代码中处理这个风险的？”