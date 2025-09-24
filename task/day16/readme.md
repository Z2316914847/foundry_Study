```
需求：
  假设你（项目方）正在EVM 链上创建一个Meme 发射平台（工厂合约），每一个 MEME 都是一个 ERC20 token ，工厂合约中你需要编写一个通过最⼩代理方式来创建 Meme，
  以减少 Meme 发行者的 Gas 成本，编写的⼯⼚合约包含两个方法：
    • deployMeme(string symbol, uint totalSupply, uint perMint, uint price), Meme发行者调⽤该⽅法创建ERC20 合约（实例）, 参数描述如下： symbol 表示新创建代币的代号（ ERC20 代币名字可以使用固定的），totalSupply 表示总发行量， perMint 表示一次铸造 Meme 的数量（为了公平的铸造，而不是一次性所有的 Meme 都铸造完）， price 表示每个 Meme 铸造时需要的支付的费用（wei 计价）。每次铸造费用分为两部分，一部分（1%）给到项目方（你），一部分给到 Meme 的发行者（即调用该方法的用户）。
    • mintMeme(address tokenAddr) payable: 购买 Meme 的用户每次调用该函数时，会发行 deployInscription 确定的 perMint 数量的 token，并收取相应的费用。
  要求：
    包含测试用例（需要有完整的 forge 工程）：   
    费用按比例正确分配到 Meme 发行者账号及项目方账号。
    每次发行的数量正确，且不会超过 totalSupply.
    请包含运行测试的截图或日志
    请贴出你的代码工程链接。

思路
  项目方：就是部署proxy合约的用户
  meme发行者：就是调用deployMeme方法的用户
  其实这个项目主要是为了让用户理解最小代理
    为什么要用最小代理：假如机构想部署非常多合约A（部署N个合约A），合约A功能非常复杂。我们知道合约功能越复杂，部署时所消耗的Gas就越多，现在机构就会想，这gas消耗太大了，并且折磨多合约部署下去，会造成以太坊区块链存储爆炸。现在有一个用户想到利用最小代理来解决这个问题，下面介绍最小代理工作原理。
    最小代理工作原理：
      首先：我们必须理解 delagatecall 低级别调用的原理，理解 逻辑合约 和 存储数据的合约。
      然后：现在你就想：token合约是逻辑合约，最小代理创建的合约就是存储数据的合约。
      然后：现在机构只要部署一个token合约和一个proxy合约（内含生产 存储数据合约 的函数，然后机构部署一个简单的的存储数据合约，然后通过delagatecall调用逻辑合约，就能实现合约A的全部功能）
```




遇到的问题
  - .组成: 部署代理逻辑合约、创建代理合约
  - ERC167提出规则：最小代理：所有meme代币共享一个实现合约，大幅降低部署gas成本
  - 为什么参数位string类型要加memory修饰符？
  - token合约只能触发一次 initialize
  - 测试文件创建的用户eth=0，所有要给他转eth
  - address.methods{value: 1 ether}()：被执行的方法必须带有pauable修饰这个函数