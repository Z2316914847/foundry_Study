```
需求1：
  编写一个 Bank 存款合约，实现功能：
  可以通过 Metamask 等钱包直接给 Bank 合约地址存款在 Bank 合约里记录了每个地址的存款金额
  用可迭代的链表保存存款金额的前 10 名用户
  请提交你的 github 仓库地址。
思路:
  获取比较节点的前节点1,当前节点,后节点1。
    1.如果当前节点小于用户存款,则更新用户节点状态
    2.将前节点设置为当前节点,下一个节点设置为当前节点,后节点设置为后节点1的后节点.后面一次循环
```
```
需求2：
  实现一个 AirdopMerkleNFTMarket 合约(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：
  基于 Merkel 树验证某用户是否在白名单中，在白名单中的用户可以使用上架（和之前的上架逻辑一致）指定价格的优惠 50% 的Token 来购买 NFT， 
  Token 需支持 permit 授权。
  要求使用 multicall( delegateCall 方式) 一次性调用两个方法：
    permitPrePay() : 调用token的 permit 进行授权
    claimNFT() : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT 。
请贴出你的代码 github ，代码需包含合约，multicall 调用封装，Merkel 树的构建以及测试用例。

思路：
  market里面需要有一个白名单（白名单仅仅是一个merkle树的根节点）
  market里有multicall方法（）
执行步骤：给market设置白名单，上架NFT，购买FT(购买前market需要获得代币授权，这样才好调用token中的transfer方法)
```

遇到的问题：
- 参数:
  - 参数是引用数据类型时(数组，结构体，string)，必须指定存储位置(storage, memory, calldata)，否则会报错。
  - memory和calldata的区别：只读不修改相数据用calldata(更省gas)，可修改数据用memory。
  - 参数A被修饰为calldata时，如果返回值中有参数A，在函数内部参数A必须强制转为memory，因为返回值必须从memory这里读取，否则会报错。
- 返回值：
  - 返回的动态数组（如 bytes[]）必须声明为 memory
  - 返回值总是会在内存中重新构造，不能直接返回 storage 或 calldata
- 低级调用返回值：(bool, bytes memory)
- 白名单必须有一个用户，因为空树（0个叶子节点）无法生成有效的 Merkle Root 和 Proof
- 为什么一个请求要用delegatecall触发两个方法？：假设user调用Bank合约的multicall方法，并且使用call：当完成第一次请求调用后，当前会话msg.sender结束，当执行第二次方法时，msg.sender就会改变为bank这个合约地址。使用delegatecall的话，当第一次请求结束后，msg.sender不会改变，仍然是user，所以第二次请求还是一user的地址请求
- NFTMarket.permitPrePay.selector 等效bytes4(keccak256("permitPrePay(uint256,uint256,uint8,uint32,uint32)"))
- 如何获取merkle上的兄弟节点