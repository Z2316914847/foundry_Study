

## 随手笔记

### 一、以太坊核心概念

1. 以太坊诞生原因：比特币出块太久(10分钟)，比特币挖矿耗电严重。

2. 区块链结构：区块头和区块体。

   - 区块头包含：父区块哈希、随机数、目标难度、根哈希、时间戳、版本号
   - 区块体包含：交易

3. 以太坊交易结构

   1. legacy：原始交易

      ```
      {
        "from": "0xSenderAddress",
        "to": "0xRecipientAddress",
        "value": "1000000000000000000",  // 1 ETH in Wei
        "gas": 21000,
        "gasPrice": "20000000000"  // 20 Gwei
      }
      ```

      

   2. EIP1559：EIP1559 提出的时间是2021年8月引入的（伦敦升级的一部分），目的是为了防止矿工gas作恶。

      ```
      {
        "from": "0xSenderAddress",
        "to": "0xRecipientAddress",
        "value": "1000000000000000000",  // 1 ETH in Wei
        "maxFeePerGas": "30000000000",  // 30Gwei，用户最大程度能接受的支付 每个单位Gas费用
        "maxPriorityFeePerGas": "2000000000",  // 2 Gwei，每个单位 愿意给的gas小费
      ）
        "gasLimit": 21000
      }
      ```

      

   3. EIP2930：EIP-2930交易引入了访问列表（Access List）功能，以优化Gas费和提高交易效率。

      ```
      # Access List：提前声明交易将访问的存储和合约地址，减少Gas费
      {
        "from": "0xSenderAddress",
        "to": "0xRecipientAddress",
        "value": "1000000000000000000",  // 1 ETH in Wei
        "gas": 21000,
        "gasPrice": "20000000000",  // 20 Gwei
        "accessList": [
          {
            "address": "0xContractAddress",
            "storageKeys": ["0xStorageKey1", "0xStorageKey2"]
          }
        ]
      }
      ```

   4. EIP4844：是一个尚未在以太坊主网上激活的提案，旨在大幅提升以太坊的扩展性。包含 数据分片 和Blob数据，其中Blob数据是 EIP-4844 引入了新的交易类型，包含“blob”数据，这些数据不会永久存储在以太坊节点中，而是短期存储，提高数据处理效率。

      ```
      # Blob详细了解：https://learnblockchain.cn/article/7586
      {
        "from": "0xSenderAddress",
        "to": "0xRecipientAddress",
        "value": "1000000000000000000",  // 1 ETH in Wei
        "gas": 21000,
        "maxFeePerGas": "30000000000",  // 30 Gwei
        "maxPriorityFeePerGas": "2000000000",  // 2 Gwei
        "blobData": "0xBlobData"
      }
      ```

4. 合约内部创建合约

   - 使用create创建合约：create创建的合约地址跟 用户地址 和 用户地址发起的交易数有关（nonce）。

     ```solidity
     Car car = new Car{}(param)  # param是构造函数参数
     keccake256（sender,nonce）
     ```

   - 使用create2创建合约：create2创建的合约地址跟 salt值 有关。

     ```solidity
     # 使用create2方式创建合约
     Car car = new Car{salt:saltXXX}(param)   # salt是一个唯一值
     # 预测Car地址,如果上面的saltXXX和下面saltYYY相等，那么 car1 == address（car）
     car1= address(uint160(uint256(keccake256(abi.encodePacked(
     	0xff，
     	sender，
     	saltYYY，
     	keccak256(Car_init_code)
     	)))))
     ```

   - 注意：不管create还是create2：都是想部署目标合约。create3也是想部署目标合约。只不过create3创建目标合约地址，只和slat和nonce有关。

     ```solidity
     // 假如有这种情况，有一个这样的合约A，它在ETH主网上的部署了，现在合约A想去BNB主网上部署，但是合约A想升级一些逻辑，这样便要修改合约A代码。如果修改了代码，那么在BNB主网的合约A地址 != ETH主网的合约A地址（create创建的地址只和sender和nonce有关，create2创建的地址只和0xx，sender、salt，init_code有关），这个时候有一种解决办法，就是使用create3,如下介绍
     
     // create3逻辑：首先在两个链上都会部署create3合约（称为factory）。用户调用create3的deploy（slat,init_code,value）就可以得到合约A的地址(value:向合约A发送ETH)。现在你会问，这里没用到nocne，并且还是用了init_code。哈哈哈哈哈，我知道你的疑问。你接下来看deploy方法的逻辑。
     
     function deploy( 
     		bytes32 salt, 
     		bytes memory creationCode,  // 这个作为交易数据
     		uint256 value
         ) internal returns (address deployed) {
         
         	// 1.固定值，create3给出的固定值
             bytes memory proxyChildBytecode = PROXY_BYTECODE;
     
     		// 2.获取地址，这个地址用于发送交易，这个交易就是创建目标合约
             address proxy;
             assembly {
                 proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
             }
             require(proxy != address(0), "DEPLOYMENT_FAILED");
     
     		// 3.发送交易
             deployed = getDeployed(salt);
             (bool success, ) = proxy.call{value: value}(creationCode);
             require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
         }
     ```

     

5. 当new时，我们实际上发送了一个特殊的交易，这个交易在 EVM 中创建和存储新合约的字节码

6. 在没有网络的环境下，以太坊能转账吗？

   - 不能完成一笔有效的以太坊转账，因为转账这个过程可以拆解为 **离线构造交易** 和 **联网广播交易**两个步骤，第一个步骤可以在没有网络的情况下完成。
   - 区块链是一个分布式网络，一笔交易生效，必须经历以下流程（2-5步必须要有网络）：创建交易-》广播交易-》网络传播-》矿工打包-》区块确认

7. 以太坊介绍：以太坊的核心是由Go语言（以及其他语言，例如Rust）编写的软件程序，官方执行客户端叫 **Geth**（Go Ethereum）。共识成客户端叫 **Prysm/Lighthouse**。当我们运行 **Geth** 程序时，我们的计算机就会成为以太坊网络中的一个节点，他会下载并验证整个区块链的历史数据，与网络中的其他节点保持同步。当用户调用官方的质押存款合约（deposit contract），将32Eth从普通账户发送到一个无法直接取回的质押合约中，我们的节点会进入一个激活队列，等待被正式纳入验证者集合

8. 以太坊程序和以太坊虚拟机

   |        | 角色   | 职责                   | 比喻                 |
   | ------ | ------ | ---------------------- | -------------------- |
   | 客户端 | 管理者 | 网络，交易，共识，状态 | 整个工厂和管理系统   |
   | 虚拟机 | 执行者 | 执行合约代码，计算Gas  | 工厂里的中央生产机器 |

   **EVM** 是以太坊客户端程序内部的一个核心组件。客户端处理所有“外部”事务（网络、共识），而 EVM 则处理所有 “内部” 的计算逻辑（合约执行）。

9. 以太坊程序和solidity代码关系

   - 总览：以太坊程序和solidity代码的关系就像是：“出租车” 和 “乘客” 的关系。solidity代码不是以太坊程序本身的一部分，而是由以太坊程序来执行和处理的 “**高级指令**”

10. 注意：我们部署的合约会返回一个地址。起始是将合约的字节码发布到链上（生产一个地址）

    - 我们部署的合约，其实是一个特殊交易，这个过程会发送什么：
      1. 执行交易：EVM开始处理这笔交易。由于`to`字段为空，EVM知道这是一个创建合约的请求。
      2. 运行初始化代码：EVM会执行`data`字段中的代码。这段代码包括两部分：
         - 初始化逻辑（Init Code）：运行合约的`constructor`函数，设置变量的初始状态。
         - 返回最终字节码（Runtime Code：solidity代码编译后得到运行时字节码）：初始化完成后，代码必须将合约的 **运行时字节码** 返回给EVM。
      3. 计算合约地址：新合约的地址由部署者的地址（`from`）和该部署者的 `nonce` 确定性计算出来。公式类似于：
      4. 存储合约：EVM将返回的 **运行时字节码** 与新计算出的 合约地址 关联起来（意思就是将运行时字节码 存储到 合约地址中），并永久存储在全球状态中。
      5. 交易确认：包含此交易的区块被确认后，合约就正式“存活”在区块链上了，任何人都可以通过它的地址与之交互。
    - 注意：用户发生一个交易，与这个合约互动，EVM会根据交易中的 **to** 地址,从区块链状态中查找并加载该地址对应的 **合约字节码（运行时字节码）**。然后EVM会根据data中的数据去执行操作。

11. 注意：部署合约起始是一个特殊交易（to为空，它的`data`字段里包含了合约的完整字节码）

12. ![1757069194694](C:\Users\28448\AppData\Roaming\Typora\typora-user-images\1757069194694.png)

--------------------

### 二、solidity

1. 以太坊虚拟机
   1. 概述：EVM时以太坊中 **智能合约** 的运行环境，EVM 不仅时沙箱环境，而且实际上时完全隔离的，这意味着在EVM内部运行的代码无法访问网络，文件系统或其他进程。智能合约甚至对其他智能合约的访问也有限。
   2. 账户：每个账户都有一个持久的键值存储，将256位字映射到256位字，称为存储。(这个存储：用于存储合约的状态变量（State Variables），且数据会永久保存在区块链上（除非被主动修改或删除）)。
   3. 交易：交易是从一个账户发送到另一个账户的消息。如果目标账户未设置（交易没有接受者或者接收者设置为null），则交易创建一个新合约（新合约地址生产方式：发送者地址和交易数量 'nonce'）。
   4. gas：EVM执行操作时，要消耗gas
   5. 存储、临时存储、内存和栈
      - 存储（storage）：每个账户都会有一个称为 **存储** 的数据区域，存储是一个将256位字映射到256位字的键值存储。
        - 为什么说每个账户都有一个叫 **存储** 的区域呢？因为，你可以这样理解，智能合约是一个账户，那么智能合约的状态变量就是放到这个账户的 **存储** 位置（slot1、slot2、slot3...）。初始化和修改存储的成本更高。所以有了memory、calldata、sunshine存储
        - 为什么存储时一个256位字呢？因为，你可以这样理解，solt计算就是基于keccake-256(abi.encodePacked( key, mapping_slot )),而keccake-256返回的就是256位。注意 **合约地址和区块哈希还有日志的索引参数存储超过32字节** 也是基于keccake-256算法得出来的。
      - 临时存储（Transient Storage）：临时存储和存储主要区别时，临时存储在每个交易结束时，临时存储的状态变量会被重置到交易之前的状态，**临时存储的状态变量读取和写入消耗的gas成本低于存储。**
        - 临时存储和常量不同，临时存储和常量**都是**在编写的时候，就赋值，但常量的值是不可以变得，而临时存储的值是可以变得，但是交易结束后，临时存储又会重置到交易之前的状态
      - 内存（memory）：它的生命周期仅限于单次外部交易或合约调用的执行过程。一旦执行结束，Memory中的数据就会被清空，**不会**被永久保存到区块链上。
        - 注意内存是线性的（可以按字节级别寻址，但读取限制为256位宽），当读取或者写入时触及到内存限制大小（256位）后，内存会按字（256位）扩展，在扩展时，必须支付gas费用。内存的成本随着其增长而增长（其增长时平方级的）。
      - 栈：栈深度最大为1024项，其中每项又是256位的字。EVM仅可以访问到栈顶元素，可以将顶部16个元素中的一个复制到栈顶，或者将栈顶元素和顶部16个元素中的其中一个交换。显然可以将栈顶元素移到存储和内存中。但在未先移除栈顶元素的情况下，无法直接访问栈中更深处的任意元素。
        - 为什么栈深度最大为1024项？因为防止攻击。恶意合约会写一个超复杂的合约，以大量消耗节点的内存，这样变拖垮节点了。如果不限制的话，当读取或者写入数据超过内存时，大量扩展内存，会消耗海量Gas。其实1024以及很大了，一个合约根本用不了这么多。
        - 为什么每项又是256位的字？因为，你设置的状态变量，address（虽然时160位，但通常嵌入到256位字里存放），uint256，keccake256都是256位，所以每项设置位256位的字。
   6. 指令集：就是EVM操作码，一共有FF个opcode（256个）
   7. 停用和自毁：
      - 在 **Cancun** 升级之前（2024-3-13），从区块链中移除代码的唯一方式是，该地址上的合约执行 **selfdestruct** 操作。存储在该地址上的剩余以太坊将会发送到指定地址。然后存储和代码将从状态中移除。假如有人给移除的合约发送以太坊，那么以太坊将会永远丢失（因为这个合约地址将创建不了，因位这个合约地址生产是由：sender+交易的nonce共同决定）。
      - 在EVM升级到 Cancun 之后，仅会执行发送以太币，并不会移除存储和代码。**selfdestruct 操作码在 solidity版本 0.8.18就被废弃了**

2. 合约的结构

   1. 状态变量：状态变量（stroage）是其永久存储在合约存储汇总，或者临时存储（Transient）在每个交易中，交易结束时会被清除的瞬时变量。

   2. 函数：函数通常在合约内部定义，但也可以在合约外部定义（这个函数称为 **自由函数**，他是在solidity版本0.7.0引入的，式 `顶层函数` 或 `库函数`，自由函数将纯计算逻辑提取到顶层，有因为不能访问状态，所以它非常安全）。

      - 自由函数始终具有隐式的（internal）可见性。
      - 自由函数可以被同一文件的合约直接调用。跨文件访问自由函数，只需要导入自由函数文件即可。
      - 自由函数没有上下文，因此无法访问 `msg.sender`、`msg.value` 或 `this`。即自由函数**不能**访问或修改任何状态变量（storage）。它们只能是 `pure` 或 `view` 函数。

      ```solidity
      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.7.1 <0.9.0;
      
      function sum(uint[] memory arr) pure returns (uint s) { 
      	// 可执行代码
      }
      
      contract ArrayExample {
          bool found;
          function f(uint[] memory arr) public {
              // 这在内部调用自由函数。
              // 编译器会将其代码添加到合约中。
              uint s = sum(arr);
              require(s >= 10);
              found = true;
          }
      }
      ```

   3. 函数修饰器（modifier）：可以以声明方式改变函数的行为。函数修饰器不能重载，修饰器可以被子合约基础，修饰器可以被子合约 **重写**。

      ```solidity
      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.4.22 <0.9.0;
      
      contract Purchase {
          address public seller;
          
      	// 修改器，是可以有参数的
          modifier onlySeller() { 
              require( condition, "");
              _;
          }
          modifier Buy(addrees addr) { 
              require( condition, "");
              _;
          }
      	// 使用函数修饰器，把 修饰器功能 添加到 abort函数 中
          function abort() public view onlySeller { // 修改器使用
              // ...
          }
      }
      ```

   4. 事件：事件是能方便地调用以太坊虚拟机日志功能的接口：应用程序（Dapp）可以通过以太坊客户端的 RPC 接口订阅和监听这些事件。当我们调用事件时，事件的参数会被存储在交易的日志中——区块链中的一种特殊数据结构（topic放有index修饰的参数，data放没有index修饰的参数）。这些日志与发出日志的合约地址有关联。

      - 注意：一个toplic只能容纳32字节（256位），如果索引参数存储超过32字节（引用类型：string/bytes动态长度/动态数组/结构体），不会直接存储原始数据，而是存储该数据的keccake-256哈希值。再次复习，使用keccake-256有：日志索引参数存储超多32字节、区块哈希、合约地址、交易树。
      - 匿名事件（慎用）：使用 `anonymous` 修改器声明事件。这意味着无法按名称过滤特定的匿名事件，只能按合约地址过滤。匿名事件的优点是它们的部署和调用成本更低。它还允许你声明四个索引参数而不是三个。

      ```solidity
      // 定义事件
      event Transfer(address index addr1, address addr2, uint amount); 
      // 匿名事件 - 无签名哈希 Topic 0，多一个可索引位
      event AnonymousTransfer(address indexed from, address indexed to, address indexed token, uint256 value) anonymous;
      
      
      ```

   5. 错误：允许你为失败情况定义描述性名称和数据。与字符串描述相比，错误的成本更低，并且允许你编码额外的数据。

      - 注意：错误不能被重载和重写，但可以被继承。
      - 注意：错误的实例只能通过revert语句创建，或者作为require函数的第二个参数。
      - 错误创建的数据会在回滚时传递给调用者。
      - 如果错误不提供任何参数，那么错误只需要4个字节的数据，这使得gas消耗低。如果错误带有参数，那么错误只需要 4字节 + 参数所占字节数。
      - 说到错误，必须提一嘴require/assert/revert
        - require用于执行逻辑前检查输入、合约变量是否满足条件、检查返回值是否满足条件。不满足条件的话，会抛出异常（这类异常为 **Error错误**），同时EVM层会使用 **revert操作码** 回滚交易，并将剩余Gas返回给调用者。
        - assert(boll condition)通常用来检查内部逻辑，程序时希望condition为真的，不满足条件的话，也会抛出异常（这类异常为 **Panic错误**），在solidity版本0.8.0之前，EVM层会使用 **Invalid** 操作码，消耗掉未用完的Gas。在solidity版本0.8.0之后，EVM层会使用 **REVERT** 操作码回滚交易，并将剩余Gas返回给调用者。
        - revert()类型有：直接使用revert()，也可以带有参数revert(string memory reason)，也可以搭配错误使用revert transferFail(arg1,arg2)。revert函数是用来撤销交易，EVM层执行revert操作码 回滚交易，并将剩余Gas返回给调用者，将错误数据传递调用者.数据并不会上链存储。

      ```
      // SPDX-License-Identifier: GPL-3.0
      pragma solidity ^0.8.27;
      // 在外部自定义错误，也可以在合约内部定义错误
      error InsufficientBalance(uint256 available, uint256 required);
      
      contract TestToken {
          mapping(address => uint) balance;
          function transferWithRevertError(address to, uint256 amount) public {
              if (amount > balance[msg.sender])
                  revert InsufficientBalance({
                      available: balance[msg.sender],
                      required: amount
                  });
              balance[msg.sender] -= amount;
              balance[to] += amount;
          }
          function transferWithRequireError(address to, uint256 amount) public {
              require(amount <= balance[msg.sender], InsufficientBalance(balance[msg.sender], amount));
              balance[msg.sender] -= amount;
              balance[to] += amount;
          }
          // ...
      }
      ```

   6. 结构体类型：结构体可以在映射和数组中使用。结构体不能包含自身类型的成员。

   7. 枚举类型：枚举可用于创建具有有限“常量值”集合的自定义类型，没怎么用过。

      - 注意：枚举默认为uint8最多可以容纳256个值，如果枚举超过256个，会自动升级为uint16、uint32等。枚举默认值为第一个定义的选项。

      ```
      // 定义枚举
      enum ActionChoices { GoLeft, GoRight, GoStraight, SitStill }
      // 给枚举添加新的类型
      ActionChoices choice;
      // 使用枚举中的类型
      ActionChoices constant defaultChoice = ActionChoices.GoStraight;
      
      
      // 使用场景:状态机（State Machine）、权限或角色控制、配置选项
      enum Status { Pending, Approved, Rejected }
      Stat权限或角色控制us public status;
      
      function approve() public {
          status = Status.Approved; // 语义明确
      }
      ```

3. 类型（细节自己去看，我只写我没注意到的细节）

   1. uint和int分别是uint26和int256的别名。

   2. 获取uint8最大值和最小值

      ```solidity
      uint112(-1) // 0.8.0 之前版本  112位全为1，这是位运算，最开始全为0，然后减1，然后变成全为1
      type(uint112).max // 0.8.0之后版本，112位全为1
      type(uint112).min
      ```

   3. solidity中尚未完全支持定长浮点型。它们可以被声明，但不能被赋值。

   4. `payable(0)` 是有效的

   5. 对于 `uint160`、整数字面量、`bytes20` 和合约类型，允许显式转换为 `address`

   6. address 和 address payable之间的区别是在solidity版本 0.5.0引入的。

   7. 账户地址全用英文大写和全用英文小写，地址具有等效的。这是EIP-55引入的标准。

   8. payable(address)相较于address有两个额外的成员：send和transfer，都是2300gas限制，transfer函数内部调用了send函数，并且transfer函数给send函数做了返回检查。我想说的是：如果transfer转账失败，则会交易回退。而send转账失败，send函数会返回一个false，并不会抛出异常和回滚交易。所以用send发起转账，一定要检查返回值。我的建议是用**call>transfer>send**，因为call可以设置消耗gas和转账ETH数量。

   9. call/delegatecall/staticcall他们都接受一个 bytes memory 参数。

      -  注意：staticcall 基本上与 `call` 相同，但如果被调用的函数以任何方式修改状态，则会回退。

   10. address.code 和 address.codehash

       - address.code获取该地址的 EVM 字节码（bytes memory）。
       - address.codeHash 获取该地址代码的 keccake-256哈希

   11. bytes.length返回字节数组的长度（只读）。

   12. 用户自定义值类型：户定义值类型使用 `type C is V` 定义，其中 `C` 是新引入类型的名称，`V` 必须是内置值类型（“基础类型”）。 函数 `C.wrap` 用于将基础类型转换为自定义类型。类似地，函数 `C.unwrap` 用于将自定义类型转换为基础类型。

   13. 函数可见性默认是 internal 。而这个关键词是最严格的，因为准备internal修饰的函数，只能供合约内部访问，连子合约都不能访问父类被修饰internal的函数。

       - 理解函数可见性关键字：public，external、private、internal
       - 状态变量可见性没有internal关键字
       - 函数类型转换：pure函数可以转换为view和non-payable、view函数只能转换为non-payable函数、payable函数只能转换位non-payable。有人会问，为什么函数类型要转换，因为有些夫合约的函数默认是pure关键字修饰，但是子合约向重写函数的某些功能（让外部能调用这个函数，获取变量值），便有了函数类型转换。

   14. 在 Solidity 中，一个**外部函数（external）或公共函数（public）** 不仅仅是一个可执行的代码块，它本身也是一个**值**。这个值拥有两个属性（成员），你可以直接访问它们以获取关于这个函数的关键信息。

       - `.address` 返回函数的合约地址。

       - `.selector` 返回 ABI 函数选择器

         ```solidity
         // SPDX-License-Identifier: GPL-3.0
         pragma solidity >=0.6.4 <0.9.0;
         
         // 如何使用函数的两个成员
         contract Example {
             function f() public payable returns (bytes4) {
                 assert(this.f.address == address(this));
                 return this.f.selector;
             }
         
             function g() public {
                 this.f{gas: 10, value: 800}();
             }
         }
         ```

   15. solidity计划支持Lambda或内联函数，但尚未支持。

   16. 引用类型：string/bytes动态长度/动态数组/结构体。使用引用类型时，必须明确该值的数据区域（memory、storage、calldata）

       - 注意：calldata专门用于存储**函数调用时传入的原始数据**。它是以太坊交易（Transaction）中 `data` 字段的底层表示，具有**只读、临时性、低 Gas 成本**的特点。
       - 不能修改 `calldata` 中的数据（编译时会报错），也就是说参数被calldata修饰后，在函数内，这个参数不能被修改，只能被读。
       - 仅在函数执行期间存在，执行完毕后消失。memory也是函数执行期间有效。

   17. 临时存储（transient）目前不支持作为引用类型数据位置。

   18. 数据位置之间的赋值行为

       - 在 `storage` 和 `memory` 之间（或从 `calldata`）的赋值总是会创建一个独立的副本
       - 从 `memory` 到 `memory` 的赋值仅创建引用。这意味着对一个内存变量的更改在所有其他引用相同数据的内存变量中也是可见的。

   19. bytes和string也是数组。

   20. 函数bytes.concat 和 string.concat：链接两个字符串

   21. 使用new操作符创建动态长度的内存数组，它与存储数组不同，内存数据**不能**调整大小

   22. 悬空的存储数组元素引用：应避免这种情况，如果你将对数组元素的引用存储在局部变量中，然后从包含数组中 `.pop()`，则可能会发生悬空引用。

   23. 数组切片仅可用于 calldata 数组。

       ```solidity
       arr[start,end]  // start和wen时uint256类型，start默认位0，end默认为数组长度
       ```

4. 单位和全局可用变量：前面文件就是介绍这个，你也可以查看 [文档](https://learnblockchain.cn/docs/solidity/units-and-global-variables.html)

5. 表达式和控制结构（细节自己去看，我只写我没注意到的细节）

   1. 外部函数调用：以太坊底层（EVM）有一个危险特性：如果你调用一个**不存在代码的地址**（比如一个普通钱包），它会告诉你“调用成功”，但你的钱却永远丢失在了那个空地址里。我想说的是，当发送一个合约，但是由于操作错误，把合约地址写错（这个合约地址不存在），这时候EVM有个危险特性，调用一个不存在代码的地址，EVM会告诉我们“调用成功”。然后悲剧就发生了。这时候 solidity防止这种事故，Solidity 编译器会在你的代码编译后，**自动插入一个检查**：在调用合约之前，先用 `extcodesize` 操作码（返回账户代码大小）检查目标地址**是否真的有合约**，如果没有代码，就立即让交易失败回滚（`revert`），从而保护你的资金。

      - 注意：在 **低级调用** 的情况下不会执行此检查，这些调用是基于地址而不是合约实例
      - 注意：为什么低级别调用不检查：因为当使用低级别调用时，你直接与 EVM 底层交互，编译器将 所有控制权和责任都交给了开发者。
      - 注意：一个是基于合约实例调用，一个是基于地址调用。

   2. 函数调用包含{ }时，它的参数顺序可以任意

      ```solidity
      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.4.0 <0.9.0;
      
      contract C {
          mapping(uint => uint) data;
      
          function f() public {
              set({value: 2, key: 3});
          }
      
          function set(uint key, uint value) public {
              data[key] = value;
          }
      }
      ```

   3. 元组赋值

      ```solidity
      ( , , )= fun()  // 原来这个叫元组
      ```

   4. `unchecked` 块可以在块内的任何地方使用，但不能替代一个块。它也不能嵌套。无法使用 `unchecked` 块禁用对零除法或零取模的检查。位运算符不执行溢出或下溢检查。

6. 合约（细节自己去看，我只写我没注意到的细节）

   1. 瞬时存储：瞬态存储变量不能在声明时初始化，即不能在声明时赋值，因为该值将在创建交易结束时被清除，从而使初始化无效。 瞬态变量将根据其底层类型进行 **默认值** 初始化。 `constant` 和 `immutable` 变量与瞬态存储冲突，因为它们的值要么是内联的，要么直接存储在代码中。

   2. 瞬态存储变量与存储具有完全独立的地址空间，因此瞬态状态变量的顺序不会影响存储状态变量的布局，反之亦然。 不过，它们需要不同的名称，因为所有状态变量共享相同的命名空间。

   3. 一个合约最多有一个receive函数，并且不带参数，不返回任何内容，必须是external和payable。他是虚拟的，可以从写，并且可以有修饰器。

   4. 矿工区块奖励和selfdestrcut发送以太币，合约必须接受，即使合约没有receive，fallback，函数没有payable修饰。

   5. 一个合约最多有一个fallback函数，他必须时ecternal，他是虚拟的，可以重写，并且可以有修饰器。回退函数也可以接受以太币（在没有receive和匹配函数时），但必须标明payable。

   6. 函数重载

      - 当执行f(10)时，会报错，因为10可以隐式转为int8/uint256。
      - 当执行f(300)时，者两个f函数算重载，不会报错。因为300不发转为uint8。

      ```solidity
      contract A {
          function f(uint8 val) public pure returns (uint8 out) {
              out = val;
          }
      
          function f(uint256 val) public pure returns (uint256 out) {
              out = val;
          }
      }
      ```

   7. 应用程序可以通过节点的RPC接口订阅和监听这些事件。具体解析 **可以看第二章solidity的合约结构中的事件部分**

   8. event.selector:返回一个bytes32值，包含事件签名的keccake-256哈希。

   9. 错误具体解析笔记：具体解析 **可以看第二章solidity的合约结构中的错误部分**

   10. 自定义错误必须与revert语句和require语句一起使用。如果在使用过程中，被评估为false的话，则当前调用中的所有更改都会被回滚，错误数据会传回调用者。

   11. event.selector:返回一个bytes32值，包含事件签名的keccake-256哈希。

   12. private不能被子类访问到，internal可以被资料访问到。

   13. 具有 `private` 可见性的函数不能是 `virtual`，因为子类都看不到和无法访问private，那么带有private的函数，不能带有virtual。

   14. 所有接口函数被自动视为virtual。

   15. 在版本 0.7.0 之前，你必须将构造函数的可见性指定为 `internal` 或 `public`。

   16. 父类构造函数有参数，子类处理的两种方式。

       ```solidity
       // SPDX-License-Identifier: GPL-3.0
       pragma solidity >=0.7.0 <0.9.0;
       
       contract Base {
           uint x;
           constructor(uint x_) { x = x_; }
       }
       
       // 要么直接在继承列表中指定...
       contract Derived1 is Base(7) {
           constructor() {}
       }
       
       // 或通过派生构造函数的“修改器”...
       contract Derived2 is Base {
           constructor(uint y) Base(y * y) {}
       }
       ```

   17. 库是一种特殊的合约，其设计的核心目的是 代码复用和Gas优化，然后被多个其他合约反复调用，而无需在每个合约中重新部署相同的代码。

       - 库不能拥有状态变量（但可以用有常量constant和不可变量immutable），不能继承合约，也不能被继承，不能介绍以太币，不能被销毁。

       - Internal函数，这些函数式库代码的一部分，会直接嵌入调用合约的字节码中，调用他们不会产生delegatecall和call，就像调用合约内部的函数一样，**因此Gas极低**。

       - external/public函数，这些函数需要先部署库合约，然后通过 `DELEGATECALL` 来执行。调用时，代码在库合约的上下文中运行，但**状态改变会作用于调用合约**。

       - 库的两种调用方式

         ```solidity
         // 方式一，这个库不需要单独部署，它的代码会被直接嵌入到使用他的合约的字节码中
         using LibName for DataType;。
         // 方式二，这个库必须单独部署到链上，并拥有一个特定的地址
         LibName.functionName()
         ```

   18. 库的函数签名和选择器：

   19. 库的调用保护：说的是只能通过delegatecall调用库，为什么只能通过delegatecall调用库呢？，假如，有人直接向已部署的库合约地址发送一笔交易，这次调用会使用call，而不是dalegatecall，因为库函数预期是在调用者的上下文中运行（读写调用者的存储），但现在它却在**库自己的上下文**中运行。这回导致，状态变更失败，验证可能会导致调用者资金丢失，最坏的情况，可能会导致库出现不可预见的错误和漏洞。

       - 注意：怎么实现一定是delegatecall呢？solidity编译器通过 **内嵌检查** 来实现调用保护。
         - 对于public/extrenal库函数，编译器会自动在每一个public和external库函数的开始处插入一段检查代码，检查逻辑是：如果当前正在执行的环境等于合约自身的地址，那就回退交易（revert）
         - 为什么对internal没有保护，因为internal函数被嵌入到合约的字节码中，internal不是部署在库的地址上等待被调用的独立代码。internal的生命周期和调用合约绑定在一起。

7. 内联汇编：下次再看

8. 以太坊虚拟机一共有几个可以存储数据区域：存储、临时存储、内存和栈