## VaultVerse - 去中心化数字藏品管理系统

理解这个项目首先需要具备以下知识：

- **ERC20**（ERC777-》ERC1363-》ERC1155-》ERC20Permit / ERC20Permit2）
  - ERC777：优化ERC20缺点：不能携带消息和不能通知目标合约。
    - ERC777通过实现了send(to,value,data)方法，可以携带消息
    - ERc77接入全局注册表，实现通知目标合约。全局注册表原理：目标合约地址去全局注册表合约在注册，说我已经实现了全局注册表某个特定方法(用于处理逻辑，防止资金调入黑洞)，这样全局注册表就知道目标合约实现了它某个特定方法。然后ERC777去全局注册表找是否存在目标合约，如果找到了，那ERC777就调用目标合约那个特定方法，如果没找到，那ERC777就交易回滚revert，消耗gas不返回。
  - ERC1363：目标合约必须实现 tokensReceived(to,amount) 方法。
  - ERC1155：优化ERC20和ERC721，好像是合二为一。
  - ERC20 Permit：为什么会诞生这个协议：**因为之前**用户给Bank合约存款，需要两步（首先在ERC20代币中授权，然后用户再次调用Bank合约中的存款合约函数（这个函数调用ERC20TransferFrom函数完成代币转移））才能完成。**有 ERC20 Permit 后**，用户只需要一步就可以完成存款（离线签名发送给Bank合约的Permit函数（permit函数代码逻辑有授权和转账），这里有个前提是：这个 授权 必须在 ERC20 Permit合约中验证离线签名）。**注意**：离线签名信息中要有 Nonce（目的：防止重放攻击）。**注意：**签名涉及资产的话，要好好保存，因为如果被恶意的攻击者获得，可能会导致用户资产损失。如果签名是对消息的化，那应该没啥影响。
  - ERC20 Permit2：让所有的代币ERC20都能离线授权功能（有一些古老的代币没有实现ERCPermit），这便是ERC20Permit2诞生原因。**注意**：离线授权是让ERC20具有离线授权代币给其他人，permit只适用于最近的ERC20代币，而Permit2让所有ERC20代币都有了离线授权功能。**注意**：真实测试网上的permit2地址：0x000000000022D473030F116dDEE9F6B43aC78BA3
- **ERC721**：
- **EIP191**：主要功能区分交易签名交易和消息签名交易，以下是要理解的内容
  - EIP191消息结构Hash（还待签名）：bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domin, messageHash)); 
  - 交易消息结构Hash（还待签名）：bytes32 hash = keccak256(abi.encodePacked(messageHash)); 
  - EIP191签名的消息应用场景：链下授权（ERC20 Permit）、去中心化登入、多签钱包交易确认
- **EIP712**：EIP712存在的目的：就是让EIP191消息在前端写法标准化（同一规定：前端数据传给后端，数据结构要统一）。不过EIP712不止是消息签名交易他还是交易签名交易（意思就是说，EIP712标准化了，规定前端发送数据要按照这个标准）
- **白名单实现原理**：写一个白名单合约来维护白民单，只有管理员可以添加、删除、白名单地址，判断是否该地址是否是白名单。
- **空投**（MerkleTree实现原理，如何判断查找地址是否在MekleTree树中、多次交易打包成一个MultiCall）
  - MerkleTree 实现原理：数据(地址)做abi.encodePacked后，进行 keccak256 计算哈希，得到叶子节点，然后将叶子节点进行排序，然后相邻的叶子节点组合在进行hash，最后得到一个 Root哈希值，将这个这个Root包装成对象，返回给用户。
  - 判断数据(地址)是否在MerkleTree树中：这里又两步
    - 首先获取叶子节点：数据(地址)做abi.encodePacked后，进行 keccak256 计算哈希，得到叶子节点Leaf_new。判断叶子节点Leaf_new是否在merkleTree叶子节点数组中，如果不在的话，返回一个空的Proof数组，如果在的话就返回一个Proof数组( 一般项目方会发布出来：某地址对应某个Proof )。
    - 然后叶子节点+Proof组转，变为Root_new，如果 Root_new  == Root_before。那么该数据(地址)就在该MerkleTree树中，反正不在

##### 项目概述：

- 通过智能合约实现数字藏品生命周期管理（铸造、购买、上架、下架），集成了盲盒、空投、流动性挖矿等特色功能，提升了藏品流通性与用户参与度。基于 Rect + TypeScript + viem构建完整的Defi生态系统。

##### 核心贡献：

- 开发合约基础功能模块，支持任意 NTF 上架、购买、下架及手续费集成，保证交易流动性合规性。
- 实现多种代币支付兼容，支持原生代币（Native Token）与 ETH 作为 NFT 交易货币。
- 集成 EIP712标准 ，开发了ERC20 Permit，链上验证签名功能，优化用户交互体验·
- 设计链下 MerKleTree 白名单构建方案，开发链上白名单验证 与 NFT 购买功能 （MultiCall），保障白名单用户权益。

##### 项目难点：

- 开发合约基础功能模块，支持白名单 NTF 上架、购买、下架及手续费集成，保证交易流动性合规性。

  - 支持白名单 NTF 上架
    - 设计 list(address _nftContract, uint256 _tokenId, uint256 _price)
    - Matket上架 **任意NFT** 有哪些问题：没有验证NFT合约的真实性、没有防止恶意合约的攻击、有没有多重安全检查
      - 如何验证NFT合约的真实性：Market合约设计NFT白名单，只允许白名单的nft可以上架
      - 如何防止恶意NFT合约的攻击：请查看src：ppt-发布的文章-上架任意NFT合约
  - 购买NFT：
    - 这里想到一个问题，交易失败，会造成回退，这个回退是回退当前执行的合约的状态，调用这的状态不会回退。
    - 设计 buyNFT(address *nftContract*, uint256 *tokenId*)：注意NFT先转买家，再将token/eth转给卖家。记得加个锁，防止重入攻击，记得是先转NfT，在转钱。如果先转钱，在转NFT有可能会造成买家资产损失（加个锁也没用）
  - 下架：设计cancelListing(address *nftContract*, uint256 *tokenId*)
    - 手续费集成（2%）： 用户从 VaultVerse 市场购买 NFT 时，会收取2%的手续费（用户实际付款：102%），并将收取费发给手续费接受地址（手续费 不是发给 VaultVerse市场合约地址）

- 实现多种代币支付兼容，支持原生代币（Native Token）与 ETH 作为 NFT 交易货币。

  - 只支持 **原生代币** 和 **ETH** 代币作为交易货币

- 集成 EIP712标准 ：开发了ERC20 Permit，链上验证签名功能，优化用户交互体验

  - EIP712标准意思就是：规定前端发送数据 要按照 EIP712格式 标准发给合约，EIP712格式就是 

    ```viem
    // ERC712 域：包含 token name、version、chainId、合约地址
    // 域 ≈ 场景的意思（合约不同啊，合约的版本不同啊，链的不同啊，合约地址不同啊）
    // 防止 重入攻击：因为不同的合约地址，不同的链，不同的版本，不同的域，别人就能区分你来自哪里，
    //   假如 域A 来自美国，但我只能提供 域B 中国人访问，这样就防止了攻击
    const domain = {
       name: name as string,         // 合约名称，一般来说合约名称 == 代币名称
       version: '1',                                // 版本号
       chainId,                                     // 链id
       verifyingContract: TOKEN_ADDRESS as Address, // 关键修正，合约地址
    };
    
    // ERC712 类型 ：描述结构体字段
    const types = {
       Permit: [
         { name: 'owner', type: 'address' },
         { name: 'spender', type: 'address' },
         { name: 'value', type: 'uint256' },
         { name: 'nonce', type: 'uint256' },
         { name: 'deadline', type: 'uint256' },
       ],
    };
    
    // ERC712 消息：具体要签名的数据
    const message = {
       owner: account,
       spender: TOKENBANK_ADDRESS,
       value: value,
       nonce: BigInt(nonce as string),
       deadline,
    };
    
    // 4. 用户签名
    const signature = await walletClient.signTypedData({
       account,
       domain,
       types,
       primaryType: 'Permit',  // 签名类型
       message,
    });
    
          
    // 5. 拆分 signature
    const { v, r, s } = splitSignature(signature);
    ```

- 设计链下 MerKleTree 白名单构建方案：开发链上白名单验证 与 NFT 购买功能 （MultiCall），保障白名单用户权益（白名单用户享受50%优惠力度）。

  - 开发链上白名单验证
    - 具体验证逻辑：参考上面提的的必备知识：空投
  - 开发NFT 购买功能 （MultiCall）：购买NFT（使用了MultiCall）执行逻辑如下
    - 调用permitPrePay( )：使用了permit2离线授权
    - 调用claimNFT( ):内含验证购买者是否为白名单用户 和 转移代币 和 转移NFT

##### 项目面试题：

- 你是如何将两个请求变为一个：

  ```
  // 一个Call代表一个请求
  struct Call {
          address target;
          bytes callData;
  }
  
  // 创建两个请求，请求在数组中
  NFTMarket.Call[] memory calls = new NFTMarket.Call[](2);
          calls[0].target = address(market);
          calls[0].callData = abi.encodeWithSelector(
              // bytes4(keccak256("permitPrePay(uint256,uint256,uint8,uint32,uint32)")), 
              market.permitPrePay.selector,  // 等效上面bytes4
              discountPrice,
              deadline,
              v,
              r,
              s
          );
  
          // token.approve(address(market), discountPrice);
          calls[1].target = address(market);
          calls[1].callData = abi.encodeWithSelector(
              bytes4(keccak256("claimNFT(address,uint256,address,bytes32[])")), 
              // market.claimNFT.selector,  // 等效上面bytes4
              address(nft),
              nftId,
              token,
              merkleProof
          );
  ```

- 后期扩展：支持任意ERC20购买NFT

