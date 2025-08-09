NFT代理合约地址:
Market代理合约地址：
NFT合约地址:
Market合约地址:
<!-- ----------------------------------------------------------- -->

编写一个可升级的 ERC721 合约. 
实现⼀个可升级的 NFT 市场合约：
  实现合约的第⼀版本和这个挑战的逻辑一致。
  逻辑合约的第⼆版本，加⼊离线签名上架 NFT 功能⽅法（签名内容：tokenId， 价格），实现⽤户⼀次性使用 setApproveAll 给 NFT 市场合约，每个 NFT 上架时仅需使⽤签名上架。部署到测试⽹，并开源到区块链浏览器，在你的Github的 Readme.md 中备注代理合约及两个实现的合约地址。
  要求：
    包含升级的测试用例（升级前后的状态保持一致）
    包含运行测试用例的日志。
  请提交你的 Github 仓库地址。

  

问题：
  1.安装可升级模块到lib文件夹中：forge install OpenZeppelin/openzeppelin-contracts-upgradeable
  2.分离式签名和紧凑行签名
    分离式签名：uint8 v, bytes32 r, bytes32 s
    紧凑行签名：bytes signature
  3.签名需要的数据类型为bytes32
  4.以太坊EVM内置ecrecover(messageHash, v, r, s), openzeppelin模块：ECDSA.recover(sigHash, signature)
    都用于从签名和消息哈希中恢复签名者的地址，但它们的实现方式和安全性有所不同。
  5.可升级合约怎么写测试合约
  6.UUPSUpgradeable合约源码不存在upgradeTo方法，如果要升级合约用upgradeToAndCall(升级合约地址，"");
  7.代理合约的逻辑合约地址获取方法：要通过存储槽位获取地址
  8.签名编码顺序rsv: bytes memory signature  = abi.encodePacked(v, r, s);
  9.签名方式:原始签名/以太坊签名紧凑型签名
  10.获取签名的用户地址
    address signature = ECDSA.recover(hash, signature)
    address signature = ecrecover(hash, v, r, s);
  11.怎么调用openzeeplin升级合约中的方法:contractV2(address(proxy)).funthod();


代理合约
  1.通过fallback函数中的汇编代码，可以实现在合约升级时，
  2.通过fallback函数中使用 delagatecall低级调用，实现委托调用，前提是逻辑合约的存储布局必须与代理合约存储布局一致
  3.逻辑合约初始化规则：
    逻辑合约的初始化只能由代理合约来执行逻辑合约的初始化。为什么只能由代理合约来初始化逻辑合约呢？因为必须保证所有状态变量存储在代理合约中，而不是在逻辑合约中状态变量被设置。
    逻辑合约不能自己初始化：因为逻辑合约自己初始化后，会有自己的存储布局，这样逻辑合约的存储布局会和代理合约的存储布局冲突，所以逻辑合约步骤自己初始化。
    逻辑合约中的状态变量是“声明”而非“实际存储”：它们定义了存储布局，但数据实际保存在代理合约中。
  4.逻辑合约的构造函数：
    逻辑合约中的构造函数要写一个 启用禁用逻辑合约被初始化（防止被初始化）代码：这个代码执行之后，所有关于逻辑合约的初始化操作便不能执行。因为这段代码会控制初始化存储地址，只能通过代理合约的初始化函数来解除这段代码对初始化存储地址的控制。
    逻辑合约可以有构造函数，但是构造函数不能初始化状态变量(也包括immunetable不可变变量)。
