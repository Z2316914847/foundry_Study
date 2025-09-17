```需求：
    使用 EIP2612 标准（可基于 Openzepplin 库）编写一个自己名称的 Token 合约。
      修改 TokenBank 存款合约 ,添加一个函数 permitDeposit 以支持离线签名授权（permit）进行存款, 并在TokenBank前端 加入通过签名存款。
      修改Token 购买 NFT NTFMarket 合约，添加功能 permitBuy() 实现只有离线授权的白名单地址才可以购买 NFT （用自己的名称发行 NFT，再上架） 。
      白名单具体实现逻辑为：项目方给白名单地址签名，白名单用户拿到签名信息后，传给 permitBuy() 函数，在permitBuy()中判断时候是经过许可的白名单  
      如果是，才可以进行后续购买，否则 revert 。
    要求：
      有 Token 存款及 NFT 购买成功的测试用例
      有测试用例运行日志或截图，能够看到 Token 及 NFT 转移。
      请填写你的 Github 项目链接地址。
```
```
需求
  在原来的 TokenBank 添加一个方法 depositWithPermit2()， 这个方式使用 permit2 进行签名授权转账来进行存款。
    在本地环境需要大家先部署 Permit2 合约
    修改 Token 存款前端 让用户可以在前端通过 permit2 的签名存款。
```
##### 需求1：遇到的问题：
- ERC20Permit只接受ERC712结构化数据结构体
- 怎么在构造函数中 初始化域分隔符
- ERC721结构化数据结构体哈希：keccak256(abi.encodePacked("\x19\x01", 域信息, 数据信息));
- 前端访问permitDeposit页面
- 怎么构建ERC2数据结构体
- 白名单 == 合约，合约中可以添加某地址为白名单，也可以删除某地地址 
- 白名单购买NFT实现逻辑  
##### 需求2：遇到的问题：
- 接口不仅可以定义方法，还可以定义结构体，事件
- 为什么 域 chainId 不用keccake256  
- 验证签名在permit2合约中实现
- 用户A把签名给bank（该签名是用户A的私钥签名的）

