需求：
  假设你（项目方）正在EVM 链上创建一个Meme 发射平台，每一个 MEME 都是一个 ERC20 token ，你需要编写一个通过最⼩代理方式来创建 Meme的⼯⼚合约，
  以减少 Meme 发行者的 Gas 成本，编写的⼯⼚合约包含两个方法：
    • deployMeme(string symbol, uint totalSupply, uint perMint, uint price), Meme发行者调⽤该⽅法创建ERC20 合约（实例）, 参数描述如下： symbol 表示新创建代币的代号（ ERC20 代币名字可以使用固定的），totalSupply 表示总发行量， perMint 表示一次铸造 Meme 的数量（为了公平的铸造，而不是一次性所有的 Meme 都铸造完）， price 表示每个 Meme 铸造时需要的支付的费用（wei 计价）。每次铸造费用分为两部分，一部分（1%）给到项目方（你），一部分给到 Meme 的发行者（即调用该方法的用户）。
    • mintMeme(address tokenAddr) payable: 购买 Meme 的用户每次调用该函数时，会发行 deployInscription 确定的 perMint 数量的 token，并收取相应的费用。
  要求：
    包含测试用例（需要有完整的 forge 工程）：   
    费用按比例正确分配到 Meme 发行者账号及项目方账号。
    每次发行的数量正确，且不会超过 totalSupply.
    请包含运行测试的截图或日志
    请贴出你的代码工程链接。

遇到的问题
  1.组成
    1.部署代理逻辑合约
    2.创建代理合约
  2.ERC167提出规则：最小代理：所有meme代币共享一个实现合约，大幅降低部署gas成本
  3.为什么参数位string类型要加memory修饰符？
  4.token合约只能触发一次 initialize
  5.测试文件创建的用户eth=0，所有要给他转eth
  6.address.methods{value: 1 ether}()：被执行的方法必须带有pauable修饰这个函数