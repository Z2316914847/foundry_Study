

## CrytoCLI — 命令行钱包项目介绍

##### 地址：https://github.com/Z2316914847/foundry_Study/blob/main/task/day13/viem_cli.ts

##### 项目概述：

- CryptoCLI 是基于TypeScript 和 Viem 库构建的命令行界面（CLI）加密货币钱包，专门为开发者、区块链学习者和高级用户设计，提供了在终端中安全管理加密资产的能力，支持以太坊sepolia测试网的 ETH 和ERC20 代币操作。项目摒弃了图形界面，专注与代码的透明性，教育意义和自动化集成能力。

##### 主要功能：

- 生产新钱包：使用加密安全随机数生成器创建密钥和账户，支持密钥导入和控制账户，生产密钥时明确用户进行离线存储。
- 资产查询：实时查询指定地址的ETH余额，输入代币合约地址，查询任何ERC20代币余额
- 资产转账：支持任何地址发送ETH，与智能合约交互，实现代币的转移（支持模拟交易simulateContract）

##### 针对项目面试题：

1. 你为什么选择使用viem，而不是使用ethers.js或者web3.js

   - viem相较于其他两个，viem更加轻量、更加高性能、更稳定wagmi)
     - 轻量性：同等模块下ethers.js包大概80kb，而viem只有30kb
     - 高性能：性能也是强悍，viem 还通过仅在需要时执行重的异步任务
     - 稳定性：关于viem的稳定性，现在很多人使用wagmi，而wagmi有许许多多的模块依赖viem，所以viem的稳定性很重要，关于viem的稳定性主要来源于，在每一个以太坊分叉的以太坊节点运行viem的测试套件，

2. 你在项目中提到会生成私钥，你的项目如何确保私钥的安全性（用户私钥在内存中如何管理的）？

   - 在签名完成后，立即用随机数据或空值覆盖存储私钥的变量：
   - 限制私钥变量作用域

3. 你提到ERC20转账，解释下simulateContract和WriteContract的作用，以及为什么需要先模拟在执行。

   ```solidity
   simulateContract顾名思义：模拟验证合约，意思是在正在改变区块链状态之前，先进行模拟预测该交易的结果，结果体现在，交易是否成功，假如模拟成功那就执行WriteContract方法改变区块链状态，假如模拟失败，根据合约对应的错误ABI，在Viem执行try/catch。
   为什么要模拟：取消不必要的用户Gas消耗，并计算出这次交易真实消耗的Gas，并将真实消耗的Gas告知用户。
   ```

4. 你在发送以太坊或代币时，如何确保用户不会支付过高的 Gas？

   ```solidity
   我这里是写死的：maxPriorityFeePerGas(每个单位 愿意给的gas小费) = 0.01Gwei，maxFeePerGas(用户最大程度能接受的支付 每个单位Gas费用 )=20000GWei。也可以动态获取，使用viem中的public.estimateFeesPerGas方法计算出 区块链上 maxPriorityFeePerGas 和 maxFeePerGas，其中 maxFeePerGas >= BaseFee + maxPriorityFeePerGas。
   maxPriorityFeePerGas：每个单位 愿意给的gas小费，激励矿工优先打包你的交易。
   maxFeePerGas：用户最大程度能接受的支付 每个单位Gas费用。
   
   说到这了，你就介绍一下ERP-1559后的交易吧：在EIP1559之前，用户自己设置GasPrice，而EIP1559之后，系统动态调节baseFee，这样用户只需要设置 maxPriorityFeePerGas 即可，即GasPrice=（baseFee + maxPriorityFeePerGas）* 消耗gas量。EIP559之后好处就是，用户不用猜测BaseFee和maxPriorityFeePerGas。因为EIP1559之前交易实际gas消耗量对用户来说不清楚的（不清楚的原因：用户不清楚BaseFee和maxPriorityFeePerGas，这样矿工虚报提高gasPrice，导致用户的交易一致在等待，用户只能被动提高gasPrice），而EIP1559之后交易实际gas消耗量对用户来说是清楚的（清楚的原因：用户清楚BaseFee，用户可以自己设置maxPriorityFeePerGas）
   ```

5. 假如你的项目要支持多链，你会如何让设计架构。

   ```solidity
   项目暂时没有多链想法，如果要支持多链的话，可以配置一个多链配置选项，让用户自己选择使用那个链。
   ```

6. 升级方面：助记词（BIP32-》BIP44-》BIP39），多链，客户端

7. 第一次：用户编写代码，将代码变成字节码，用户签署一个to为空的特殊交易，

