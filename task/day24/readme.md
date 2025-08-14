需求
  创建一个 Foundry 工程，添加 Uniswap V2 核心及周边代码：
    阅读并分析 Uniswap V2 源代码，并为主要合约添加代码注释
    （可选）发布一篇文章阐述自己对 Uniswap 理解的文章，如代码解读等，积累自己的个人 IP
    在本地部署 Uniswap V2 核心及周边源代码 （注意：你需要 周边代码库 pairFor 方法中出现的 init_code_hash ）
    请贴出的 github 代码及文章链接（如果写了文章的话）


需求：
  实现一个 LaunchPad 平台:
  修改之前最小代理工厂 1% 费用修改为 5%， 然后 5% 的 ETH 与相应的 Token 调用 UniswapV2Router AddLiquidity 添加MyToken与 ETH 的流动性（如果是第一次添加流动性按mint 价格作为流动性价格）。
  除了之前的 mintMeme() 可以购买 meme 外，添加一个方法: buyMeme()， 以便在 Unswap 的价格优于设定的起始价格时，用户可调用该函数来购买 Meme
  需要包含你的测试用例， 运行 Case 的日志，请贴出你的 github 代码。

我的想法是：将5%的费用和 5%的token保存在proxy合约中，proxy有一个函数添加流动性函数，5%的费用 ＋ 5%的token作为参数，传递给AddLiquidity函数。

遇到的问题：
  1.solidity不允许 uint256*浮点数，解决方案：uint256 * 8/100
  2.ERC20精度影响甚多：比如ERC20.mint( user1, 9.5),如果精度是1的话，只能铸造9个token，如果代币是精度是10000的话，铸造9500个token
  3.应该是地址.balance,不应该是实例.balance.
  4.用户 兑换代币 前必须保证用户有资金(token...)(池中)
  5.swap函数参数:用户期望代币数量、用户能接受最低代币数量，截止时间，用户资金

UniswapV2Migrator.sol: 外围合约，作用是让uniswarprouter合约更加简单链接到 core核心合约。
8-22号
  今天重点介绍 v2Pair 合约 Mint() 函数：添加流动性池
    1.为什么pair中需要保存代币数量：防止作恶，代码中有造成作恶原理介绍:
    
    