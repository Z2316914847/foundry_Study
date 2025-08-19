创建一个 Foundry 工程，添加 Uniswap V2 核心及周边代码：

阅读并分析 Uniswap V2 源代码，并为主要合约添加代码注释
（可选）发布一篇文章阐述自己对 Uniswap 理解的文章，如代码解读等，积累自己的个人 IP
在本地部署 Uniswap V2 核心及周边源代码 （注意：你需要 周边代码库 pairFor 方法中出现的 init_code_hash ）
请贴出的 github 代码及文章链接（如果写了文章的话）

问题：
  1.没有TransferHelper.sol合约，原因：v2外围合约不存在TransferHelper.sol合约，你要安装@uniswap/lib库才行（npm install @uniswap/lib。或者我去V3外围合约的libraries文件夹中能找到。
  2.提取获取合约地址：create2
    1.new student{salt: _salt}();
    2.bytes32 hash = keccak256(
        abi.encodePacked(
            bytes1(0xff),  // 一个固定的前缀 
            factory,   // 部署合约的地址。
            _salt,          // salt值。什么值都可以，但要保证唯一性。
            keccak256(bytecode)  //  Pair 合约的初始化代码哈希
        )
    );
  3.预先知道地址用途：
    1.我们可以在合约还没部署之前，就把它的地址写道别的合约里。方便逻辑提前集成
    2.预先知道池子的地址（uniswap）
  4.uniswap在首次添加流动时，为什么需要对代币进行排序：因为不止一次添加流动性。假设添加流动性方法：function(arg1,arg2)，首次我们设置arg1=eth，arg2=usdt，然后添加流动性。第二次我们设置arg1=usdt，arg2=eth，然后添加流动性。这时如果不对代币进行排序，就会出现问题。
  5.预先计算地址和实际部署地址区别
      预先知道地址：只有salt是随机的，其他值都是已经固定下来的
        address(uint(keccak256(
          abi.encodePacked(
              bytes1(0xff),  // 一个固定的前缀 ,区分与其他地址生成方式
              factory,   // 部署合约的地址。
              _salt,          // salt值。什么值都可以，但要保证唯一性。
              keccak256(bytecode)  //  Pair 合约的初始化代码哈希
          )
        )));
      实际部署地址：
        create2(
          0,   // 指创建合约后向合约发送x数量wei的以太币
          add(bytecode, 32),   // bytecode：被实际部署的合约的字节码  .opcode的add方法,将bytecode偏移后32位字节处,因为前32位字节存的是bytecode长度
          mload(bytecode),   // opcode的方法,获得bytecode长度
          salt   // 随机数,但要保证唯一性。
        )
  6.注释有问题：要遵守NatSpec注释格式


需求
  实现一个 LaunchPad 平台:
  • 修改之前最小代理工厂 1% 费用修改为 5%, 然后 5% 的 ETH 与相应的 Token 调
  用 Uniswap V2Router AddLiquidity 添加MyToken与 ETH 的流动性(如果是第一次添
  加流动性按mint 价格作为流动性价格)。
  • 除了之前的 mintMeme 可以购买 meme 提价一个方法: buyMeme(), 以便在 Unswap
  的价格优于设定的起始价格时,可调用该函数实现购买 Meme.

问题：
  1.获取合约初始化代码哈希：forge inspect UniswapV2Pair bytecode


factory weth
pair合约字节码
v2Linrary不是要pair字节码吗，我们可以在factory合约写个函数，来获取pair合约字节码