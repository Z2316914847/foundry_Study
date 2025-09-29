```
需求1：
  创建一个 Foundry 工程，添加 Uniswap V2 核心及周边代码：

  阅读并分析 Uniswap V2 源代码，并为主要合约添加代码注释
  （可选）发布一篇文章阐述自己对 Uniswap 理解的文章，如代码解读等，积累自己的个人 IP
  在本地部署 Uniswap V2 核心及周边源代码 （注意：你需要 周边代码库 pairFor 方法中出现的 init_code_hash ）
  请贴出的 github 代码及文章链接（如果写了文章的话）

需求2：
  实现一个 LaunchPad 平台:
  • 修改之前最小代理工厂 1% 费用修改为 5%, 然后 5% 的 ETH 与相应的 Token 调
  用 Uniswap V2Router AddLiquidity 添加MyToken与 ETH 的流动性(如果是第一次添
  加流动性按mint 价格作为流动性价格)。
  • 除了之前的 mintMeme 可以购买 meme 提价一个方法: buyMeme(), 以便在 Unswap
  的价格优于设定的起始价格时,可调用该函数实现购买 Meme.

``` 

问题1：
  - 经常一起访问的变量放在相邻位置: reserve0、reserve1、blockTimestampLast 经常在 _update() 函数中一起使用
  - 没有TransferHelper.sol合约，原因：v2外围合约不存在TransferHelper.sol合约，你要安装@uniswap/lib库才行（npm install @uniswap/lib。或者我去V3外围合约的libraries文件夹中能找到。
  - 提取获取合约地址：create2: 
    ```
    new student{salt: _salt}();这段代码在EVM层面操作如下：

      create2(
        0,   // 指创建合约后向合约发送x数量wei的以太币
        add(bytecode, 32),   // bytecode：被实际部署的合约的字节码  .opcode的add方法,将bytecode偏移后32位字节处,因为前32位字节存的是bytecode长度
        mload(bytecode),   // opcode的方法,获得bytecode长度          salt   // 随机数,但要保证唯一性。
      )
    ```
  - 预测合约地址
    ```
      bytes32 hash = keccak256(
          abi.encodePacked(
              bytes1(0xff),  // 一个固定的前缀 
              factory,   // 部署合约的地址。
              _salt,          // salt值。什么值都可以，但要保证唯一性。
              keccak256(bytecode)  //  Pair 合约的初始化代码哈希
          )
      );
    ```
  - 预先知道地址用途：
    - 我们可以在合约还没部署之前，就把它的地址写道别的合约里。方便逻辑提前集成
    - 预先知道池子的地址（uniswap）
  - uniswap在首次添加流动时，为什么需要对代币进行排序：因为不止一次添加流动性。假设添加流动性方法：function(arg1,arg2)，首次我们设置arg1=eth，arg2=usdt，然后添加流动性。第二次我们设置arg1=usdt，arg2=eth，然后添加流动性。这时如果不对代币进行排序，就会出现问题。
  - 注释有问题：要遵守NatSpec注释格式
  - 为什么累计价格要有UQ112X112格式，而不是用整数格式保存累计价格。
    - 整数保存价格会导致精度损失（一个价格/另一个价格，有时候会产生小数点，soidity不支持小数点(浮点数)，这样小数点部分会被截断舍弃），导致价格计算不准确。
    - 累计价格(整数) X 时间 = 一个非常大的数，因为价格会有精度，这样累计价格乘以时间，会导致数值太大，超出Solidity的整数范围，造成溢出。

    
问题2：
  - 获取合约初始化代码哈希：forge inspect UniswapV2Pair bytecode
    这是预知合约地址的必要元素 :bytes32[keecak256(forge inspect UniswapV2Pair bytecode)]
  - 添加流动性池和铸造流动性LP token是不同的
  - 获得pair合约的初始化代码哈希
    ```
        bytes32 initCodeHash = factory.getInitCodeHash();
        console.log("Init code hash:", (initCodeHash));
        echo "obase=16; （initCodeHash）3032508986413993250020441025409081388907195763715555527658271401490369535019" | bc
    ```

```
uniswapV2不足：
  p     x       y
  1     100     100
  1.2   1100    909.1
        100     90.9
                资金利用率约9%（当价格波动20%）
  1.大额交易会造成价格大幅偏移，导致交易失败。
  2.大额交易，交易者需要支付更高的溢价。
  3.改善上面两种情况，只能等待巨鲸进场，提供巨大的流动性。
  3.资金利用率低(仅使用了9%的y轴资金)
uniswapV3改善V2不足
  1.LP 可将资金集中在预期交易频繁的区间（如 ETH $1800-$2200）。
``` 

### 2025-9-29 精进
##### Pair合约
 - Pair交易对 是由 Factory合约工厂 创建的。
 - Pair交易对是一个 ERC20Permit(离线授权：发送一个交易，即可完成 ERC20授权和转账 )。
 - Pair交易对有两个代币，分别是token0和token1，并且有两个储备量，分别是reserve0和reserve1。注意 交易对中的各个代币的储备量 == Pair地址在两个token的持币量。 
 - 函数在合约中的位子，我们根据函数使用频率来决定函数使用位置 -- 不懂得话，可以自己AI以下：根据 Solidity 风格指南，函数和事件和修饰器应该如何排序
 - Pair交易对几种重要方法：
   - 简单介绍
     - permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external：离线授权，验证签名是否有效，有效的化就授权转账。
     - mint(address to) external lock returns (uint liquidity): 给 用户to 铸造 LP token 
     - burn(address to) external lock returns (uint amount0, uint amount1): 用户to 销毁 LP token，并获得交易对中 一部分数量 的两种代币。
     - swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock returns (uint amount0In, uint amount1In): 用户 to 根据tokenA的数量在交易池中进行兑换tokenB。
     - skim(address to) external：使两个token的余额与储备相等。当有人不小心给 交易对 转了token，会导致 储备量 != 持币量，会影响后续价格计算错误。
     - sync() external：使两个token的储备与余额相匹配。
    - 详细介绍
      - permit()：不理解的话，你可以去看 task/day14文件夹，有permit和permit2详细介绍
      - mint():
        - 获取用户实际转入代币数量
        - 计算给项目方手续费（一般项目方不会要的，因为项目方看不起 这三瓜两枣的 流动性 手续费），这个方法只在 mint 和 burn 存在
          - 收取收取手续费计算逻辑
            - 判断是不是首次添加流动性，如果是（ k=0 ），则不收取手续费。如果不是（ k>0 ），则收取手续费。
            - 手续费 = 1/6 * (sqrt当前(reserve0 * reserve1) - sqrt上次(resever0 *resever1))
        - 计算 应该铸造多少流动性
          - 首次添加流动性(Lp token =0)
            - 为什么就用 lp token，而不是用其他他的，比如 k。因为，假如攻击者给这个发送代币，就会影响 k，所有不用 k 这个变量。而是使用 Lp token，因为它不受外部影响
            - 首次添加流动性，需要锁定 最小份额。不理解可以看代码，我有介绍
          - 非首次添加流动性(Lp token > 0)
            - 非首次添加流动性，不需要锁定 最小份额。
            - 计算 Lp token = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        - 铸造流动性，发给用户
        - 更新resever0，resever1，blockTimestampLast，K
        - 触发事件


