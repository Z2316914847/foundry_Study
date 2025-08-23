编写一个合约去获取 LaunchPad 发行的 Meme 的TWAP 价格， 请在测试中模拟不同时间的多个交易。
提交你的 github

为什么合约不自己获取合约累计价格，而是采用预言机方式获取twap价格？
  1.我们自己的合约无法自己主动获取外部实时数据。
  2.twap计算需要大量历史数据，以及涉及在自己的合约里存储数据，消耗高gas
  3.预言机网络通常由多个节点组成，减少单点故障分析，提供更可靠的价格数据。
预言机有哪些：
  1.Chainlink
  2.Pyth Network(Solana)
  3.API3

预言机获取twap价格全过程：https://d2f70xi62kby8n.cloudfront.net/data-feeds-infographic.svg?auto=compress%2Cformat



需求：
  在测试网上部署两个自己的 ERC20 合约 MyToken ，再部署两个 Uniswap，并创建两个Uniswap V2 流动池（称为 PoolA 和 PoolB），让PoolA 和 PoolB 形成价差，创造套利条件。
  编写合约执行闪电兑换，可参考 V2 的ExampleFlashSwap。
  提示：你需要在 UniswapV2Call中，用从PoolA 收到的 TokenA 在PoolB 兑换为 TokenB 并还回到 uniswapV2 Pair 中。
  解题要求：
  贴出你的代码库链接
  上传执行闪电兑换的日志，能够反应出闪电兑换成功执行。

注意一个uniswap不可能有两个一样的池子，所以我们需要两个不同的uniswapV2Router合约，在这两个不同的uniswapV2Router各自创建不同的池子。


思路：
  用户调用闪电贷合约的贷款方法fun1，fun1调用pair合约的swap方法，swap方法中调用闪电贷uniswapV2Call方法(调用这个方法之前，pair合约默认接收到token0，所以闪电贷合约会接受到来自pair合约的token1代币)，进入到uniswapV2Call方法后，闪电贷将得到的token1又去另一个池子2兑换为token0，如果池子2得到的token0>池子贷出来的token0，则说明套利成功，闪电贷合约将token0借出来的token0还给pair合约，将剩余的token0发给用户。


问题
1.pair合约中的回调逻辑必须在这个前面，不让pair会说没有收到用户的token0(因为用户用token0购买的token1，所以需要先把token0转给pair合约).
  // 用于回调合约来实现一些特定的业务逻辑或其他自定义功能(闪电贷....)，回调函数必须在查询balance0和balance1之前调用。
  if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
  // 合约拥有两种token的数量， 转移token0/token1后，池子中有两个代币的数量
  balance0 = IERC20(_token0).balanceOf(address(this));
  balance1 = IERC20(_token1).balanceOf(address(this));
2.传递数据：用abi.encodePacked()