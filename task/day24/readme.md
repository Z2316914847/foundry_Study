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
        add(bytecode, 32),   // bytecode：被实际部署的合约的字节码，字节码所要占的位置太大，所以将部署的字节码被放到内存中，而在内存中复杂数据存储方式：数据长度(32字节)+数据内容(紧挨着一起)。bytecode在内存中可以理解为一个 内存指针，指向内存某块位置。
        mload(bytecode),   // 从 bytecode 的内存地址加载其长度（即前 32 字节）。这告诉 EVM 需要拷贝多长的字节码        
        salt   // 随机数,但要保证唯一性。
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
  - 累计价格使用场景
    - 预言机系统
    - 防止闪电贷攻击
    - 借贷协议
    - 合成资产协议
    - 保险协议
    - 治理和Dao
    - 跨连桥和桥接
    - 衍生品交易
  - TWAP使用：TWAP = (price0 * time0 + price1 * time1) / (time0 + time1)


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

-----------------------------------------------------

# 2025-9-29 精进
## 一：Pair合约
### Pair基础知识点 
  - Pair交易对 是由 Factory合约工厂 创建的。
  - Pair交易对是一个 ERC20Permit(离线授权：发送一个交易，即可完成 ERC20授权和转账 )。
  - Pair交易对是一个ERC20，他有 totalsuppply这个状态变量， totalsupply == LP token == sqrt(resever0*reserver1)
  - Pair交易对有两个代币，分别是token0和token1，并且有两个储备量，分别是reserve0和reserve1。注意 交易对中的各个代币的储备量 == Pair地址在两个token的持币量。 
  - 函数在合约中的位子，我们根据函数使用频率来决定函数使用位置 -- 不懂得话，可以自己AI以下：根据 Solidity 风格指南，函数和事件和修饰器应该如何排序
### Pair交易对几种重要方法：
#### 简单介绍
  - permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external：离线授权，验证签名是否有效，有效的化就授权转账。
  - mint(address to) external lock returns (uint liquidity): 给 用户to 铸造 LP token 
  - burn(address to) external lock returns (uint amount0, uint amount1): 用户to 销毁 LP token，并获得交易对中 一部分数量 的两种代币。
  - swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock returns (uint amount0In, uint amount1In): 用户 to 根据tokenA的数量在交易池中进行兑换tokenB。
  - skim(address to) external：使两个token的余额与储备相等。当有人不小心给 交易对 转了token，会导致 储备量 != 持币量，会影响后续价格计算错误。
  - sync() external：使两个token的储备与余额相匹配。
#### 详细介绍
      - permit()：不理解的话，你可以去看 task/day14文件夹，有permit和permit2详细介绍
      - mint(address to):
        - 获取用户实际转入代币数量
        - 计算给项目方手续费（一般项目方不会要的，因为项目方看不起 这三瓜两枣的 流动性 手续费），这个方法只在 mint 和 burn 存在
          - 收取手续费计算逻辑
            - 判断是不是首次添加流动性，如果是（ k=0 ），则不收取手续费。如果不是（ k>0 ），则收取手续费。
            - 手续费 ≈ （1/6） * totalSupply上次*（k当前-k上次）
        - 计算 应该铸造多少流动性
          - 首次添加流动性(Lp token = 0)
            - 为什么就用 lp token=0，而不是用其他的变量等于0呢？比如 k。不使用k,是因为，假如攻击者给这个发送代币，就会影响 k，所有不用 k 这个变量。而是使用 Lp token，因为它不受外部影响
            - 首次添加流动性，需要锁定 最小份额。不理解可以看代码，我有介绍
          - 非首次添加流动性(Lp token > 0)
            - 非首次添加流动性，不需要锁定 最小份额。
            - 计算 Lp token = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        - 铸造流动性，发给用户
        - 更新resever0当前，resever1当前，resever0累计价格，resever1累计价格,当前时间戳，K
          - 累计价格0 + = [(resever1*2**112)/resever0]*(block.timestamp当前 - block.timestamp上次)
          - 累计价格1 + = [(resever0*2**112)/resever1]*(block.timestamp当前 - block.timestamp上次)
          - 距离上次更新时间间隔 = block.timestamp - blockTimestampLast
          - K = reserve0当前 * reserve1当前
          - 有人会问，累计价格有什么用：具体用途在本文档 问题1最后面介绍了。
        - 触发事件
      - burn(address to):
        - 首先的明白这两点，这样看pair合约中的 burn方法才不会迷糊 : 
          - Pair合约地址本身是没有 LP token的，Pair里的 LP token 是 发给提供流动性的用户 和项目方的。
          - 用户手里的LP token必须授权给Router合约，然后Router合约将 LP token 转给Pair合约。这样一来，Pair合约就有了 LP token，这样 Pair合约 才
        - 获取需要销毁的 LP token 数量
        - 计算给项目方手续费：同上
        - 计算用户应的代币数量：
          - 计算方式：resever0 = LP销毁*resever0上次/totalsupply上次，resever1 同理计算
        - 调用erc20的burn方法，销毁 LP token
        - 给用户转账
        - 更新resever0当前，resever1当前，resever0累计价格，resever1累计价格,当前时间戳，K
        - 触发事件
      - swap(uint amount0Out, uint amount1Out, address to, bytes calldata data):
        - 首先的明白
          - 兑换后，必须保证 K后 >= K前（有大于号，是因为兑换收取了 手续费）
          - amount0Out 和 amount1Out 其中一个必定为0，另一个必定为用户想要兑换的代币数量。
          - data 这个是闪电贷需要的数据。
        - 用户所需的代币转移。
        - 转发给闪电贷
        - 判断 K后 >= K前，如果不满足，则触发 revert。
        - 更新resever0当前，resever1当前，resever0累计价格，resever1累计价格,当前时间戳，K
        - 触发事件
      - skim():
        - 这个方法是为了解决 储备量 > 持币量 的问题。比如攻击者给 Pair转代币，导致后续计算错误。
      - sync():
        - 这个是为了解决 储备量 != 持币量 的问题。当 存储量 != 持币量 时，就要尽快调用这个方法。防止后续造成损失。

#### Factry合约
##### Factory基础知识点
    - Factory合约注意功能 管理feeTo的权限者地址 和 部署 pair交易对。
    - 在内存中 数据存储存储方式
  ##### Factory重要方法
    - 不用 简单 和 详细 介绍了，因为就一个方法（createpair(tokenA,tokenB)）比较重要
      - 将两个 token地址 进行排序，小的作为token0，大的作为token1。
      - 计算 Pair合约 的字节码。（注意create2部署是需要合约字节码，而预测是需要合约字节码的哈希值，我们应当注意这里两者）
      - 部署 Pair交易对
      - 初始化 Pair交易对
      -触发事件
      - 注意Pair合约的 Lp token 代币精度是 18。

#### Router合约
  ##### Router基础知识点
    - Router合约是与pair交易对进行交互的合约，常用于添加流动性、移除流动性、兑换、获取交易对信息......
    - WETH合约概念
    - 
  ##### Router重要方法
    - **简单介绍**
      - addLiquidity(address tokenA, address tokenB, uint amountAExpect, uint amountBExpect, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity): 添加ToeknA-ToeknB的流动性。
      - 添加ToeknA-ETH的流动性。
      - removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB): 移除流动性TokenA-TokenB。
      - 移除流动性TokenA-TETH。
      - 移除流动性TokenA-TokenB，增加了 permit 功能。
      - 移除流动性TokenA-ETH，增加了 permit 功能。
      - 移除流动性TokenA-ETH，增加了 fee-to-transfer功能（注意：这里V2没有TokenA-TokenB-fee-to-transfer方法，原因是：实际应用场景较少，一般都是 Token-ETH ）。
      - 移除流动性TokenA-ETH，增加了 fee-to-transfer功能 + permit 功能。
      - swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts): 兑换：根据确切TokenA，获取 TokenB。用户只需要输入确切的TokenA数量和最低数量的TokenB数量和兑换地址即可。
      - swapTokensForExactTokens(): 兑换: 获取确切 TokenB，需要多少tokenA。用户只需要确切的TokenB数量和用户想要确切TokenB愿意支付最大的TokenA数量和兑换地址即可。
      - 兑换2：根据确切数量的ETH的兑换token
      - 兑换2-2：根据需要获得确切数量的ETH 传入 需要token的数量
      - swapExactTokensForETH(): 兑换：根据确切 token 兑换 Token
      - swapETHForExactTokens(): 兑换：根据需要获得确切的 Token 传入 需要 ETH的数量 
      - swapExactTokensForTokensSupportingFeeOnTransferTokens(): 兑换：根据确切 TokenA 兑换TokenB（支持 fee-to-transfer功能），直接交换	
      - swapExactETHForTokensSupportingFeeOnTransferTokens(): 兑换：根据确切 ETH 兑换Token（支持 fee-to-transfer功能）。
      - swapExactTokensForETHSupportingFeeOnTransferTokens(): 兑换：根据确切 token 兑换 ETH（支持 fee-to-transfer功能）。
    - **详细介绍**
      - addLiquidity(): TokenA-TokenB 流动性添加
        - 部署 Pair交易对
        - 计算出 两个代币数量
          - 首次添加流动性(Pair交易对刚被部署)
            - 试图返回 两个代币数量 == 期望数量（此时 Pair交易对是刚创建的，代币价格不会有波动，所以返回期望的数量即可）。
          - 非首次添加流动性(Pair交易对已经存在，只不过再次添加流动性)
            - 试图返回 两个代币数量（只不过这里要计算：有人会问，为什么要计算两个代币数量呢？我们直接使用 两个代币期望的数量 不就好了。 你错了，你应该考虑更多，在你添加流动时时，代币价格时时刻波动的，你的 两个代币数量期望值 只不过是某一时刻的价格。这样说理解了了吧。）
              - 计算逻辑描述不出来，只能说：只可意会不可言传。自己看代码吧
        - 转账（ transferFrom() ）两种token的amount数量到pair交易对合约，如果用户代币数量不足，则转账失败，抛出异常
        - 调用 Pair交易对中的 mint()方法添加流动性
      - addLiquidityETH(): TokenA-ETH 流动性添加
        - 部署 Pair交易对( 注意：TokenA-WETH )
        - 计算出 两个代币数量（基于原理同上）
        - 转账（同上）
          - 注意 ETH 不是ERc20代币，没有授权、TransferFrom功能，所以用户无法授权ETH给用户，只能转账给Router合约。
          - 有人会问，为什么WETH中，为什么不给用户存款，然后用户通过授权将 WETH 授权给 Router合约。答：因为用户交易已经进到合约里了，我就问你，用户怎么在次去授权WETH给Router合约？你懂了吧。所以这样设计（WETH中直接给Router合于存款）是合理的
        - 调用 Pair交易对中的 mint()方法添加流动性
      - removeLiquidity(): TokenA-TokenB 流动性移除
        - 获取 Pair交易对的地址
        - 将流动性代币 LP Token 转给 Pair交易对合约
        - 调用 Pair交易对中的 burn()方法 移除流动性
      - removeLiquidityETH(): TokenA-ETH 流动性移除
        - 调用removeLiquidity( ，WETH， ， ， ，address(this), )方法。注意参数不同
        - 将两个代币数量 转给用户（是不是有疑问？这里为什么又要转代币给用户？因为调用调用removeLiquidity这个中to的地址是 Router合约地址）。
      - removeLiquidityWithPermit(): TokenA-TokenB 流动性移除，增加 permit 功能
        - 验证离线签名
          - 将流动性代币 LP Token 转给 Pair交易对合约
        - 调用 removeLiquidity()方法。
      - removeLiquidityETHWithPermit(): TokenA-ETH 流动性移除，增加 permit 功能
        - 验证离线签名
          - 将流动性代币 LP Token 转给 Pair交易对合约
        - 调用 removeLiquidityETH()方法
      - removeLiquidityETHSupportingFeeOnTransferTokens(): TokenA-ETH 流动性移除，增加 fee-to-transfer功能（有些代币在转账时会收取手续费）
        - 调用removeLiquidity( ，WETH， ， ， ，address(this), )方法。注意参数不同
        - 将两个代币数量 转给用户
      - removeLiquidityWithPermitSupportingFeeOnTransferTokens(): TokenA-TokenB 流动性移除，增加 fee-to-transfer功能 + permit 功能
        - 验证离线签名
          - 将流动性代币 LP Token 转给 Pair交易对合约
        - 调用 removeLiquidityETHSupportingFeeOnTransferTokens()方法
      - swapExactTokensForTokens(): 兑换：根据确切Token，获取 Token
        - 兑换这一些列方法，我们首先的明白参数的含义：
          - amountIn: 用户想要兑换的Token数量
          - amountOutMin: 用户期望的兑换Token数量最小值
          - path: 兑换路径，即用户想要兑换的Token的地址顺序。这个Path是一个数组，在这个方法中，Path第一个元素是用户 付出token的地址，最后一个元素是用户想要兑换的token的地址。
          - to: 兑换后代币的接收地址
          - deadline: 兑换的截止时间
        - 计算出能兑换的Token数量A
          - (resever0+x)*(resever1+y)=resever0*resever1： 已知x，求y
        - 判断兑换出的Token数量A是否大于用户能接受的最小数量
        - 将用户代币 Token转给 Pair交易对合约
        - 调用 Pair交易对中的 swap()方法 进行兑换
      - swapTokensForExactTokens(): 兑换: 获取确切TokenB数量，需要多少tokenA
        - 计算出需要多少个TokenA
        - 判断兑换出的Token数量A 是否 小于 用户能接受的最大数量（）如果小于的话，就交易成功，否则交易失败）。这里有人会问，如果合约计算出来的数量远远小于用户能接受的最大数量后，用户授权给Router合约的剩余代币怎么处理，答，这些代币Router合约是自己动用的，需要用户自己处理剩余的代币
        - 将用户代币 Token转给 Pair交易对合约
        - 调用 Pair交易对中的 swap()方法 进行兑换
      - swapExactETHForTokens(): 兑换：根据确切ETH，获取 Token
        - 和swapExactTokensForTokens差不多，只不过swapExactETHForTokens这个方法多了一步：ETH转换为WETH，然后 WETH 转给 Pair交易地址。然后调用 Pair交易对中的 swap()方法 进行兑换
      - swapTokensForExactETH()：兑换：获取确切 ETH数量，需要多少tokenA
        - 和swapTokensForExactTokens差不过，只不过swapTokensForExactETH这个方法多了一步：大概原因是：Pair将WETH转给Router合约了，然后router合约将WETH转换为ETH，然后Route合约r再将ETH转给用户
      - swapExactTokensForETH(): 兑换：根据确切Token，获取 ETH
        - 计算出需要多少个TokenA
        - 将用户代币 Token转给 Pair交易对合约
        - 调用 Pair交易对中的 swap()方法 进行兑换
        - 将WETH转为ETH，Router将ETH转给用户
      - swapETHForExactTokens(): 兑换：根据确切ETH，获取 Token
        - 计算出需要多少个ETH
        - 判断 如果计算出来的ETH数量大于用户能接受的最大数量，则交易失败。
        - 将ETH转为WETH，将WEETH转给Pair合约
        - 调用 Pair交易对中的 swap()方法 进行兑换
        - 多余ETH返回给用户
      - 兑换 支持收费的方法 和上面差不多，只不过多了一步收费的手续费。这里就不介绍了。想要了解可以看源代码。注意：其实吧，假如调用了 支持收费的方法，就说明用户已经有些了解：能获得的token肯定少于其他不支持收费的token，那么用户就会将滑点设大点。
      - 其他方法：quote、getAmountOut、getAmountsOut、getAmountIn、getAmountsIn。这些方法时提供给前端用的，用来计算能获得多少资产（确切输入能获得多少输出，或者确切输出能获得多少输入）。
        - quote(): 给定数量的某个tokenA和该交易池储备对，返回等量的tokenB数量
        - getAmountOut(): 给定输入Token的数量，计算输出Token的数量，
        - getAmountsOut(): 给定输入Token的数量，计算输出Token的数量，支持多路径兑换
        - getAmountIn(): 给定输出Token的数量，计算输入Token的数量
        - getAmountsIn(): 给定输出Token的数量，计算输入Token的数量，支持多路径兑换


