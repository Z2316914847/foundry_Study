部署自己的 Delegate 合约（需支持批量执行）到 Sepolia。
    修改之前的TokenBank 前端页面，让用户能够通过 EOA 账户授权给 Delegate 合约，并在一个交易中完成授权和存款操作。
    提交 GitHub 代码和测试网交易的浏览器链接

问题：
  1.如何生产authorized_list字段数据
  2.transport: http('http://127.0.0.1:8545')：http不带s
  3. anvil不支持EIP7702交易：EIP-7702 authorization lists are not supported before the Prague hardfork
  4.RPC限制速率：fork sepolia到anvil上：anvil --fork-url https://eth-sepolia.public.blastapi.io
    但是还是报错:details: 'EIP-7702 authorization lists are not supported before the Prague hardfork'
  5.终于解决了：
    问题所在：
      const executeHash = await walletClient.writeContract({
            account: eoa, 
            abi: DELAGATE_ABI,
            address:DELAGATE_ADDRESS,  // 问题所在  我们应该访问账户的智能合约地址
            functionName: 'execute',
            args: [calls],
            authorizationList: [authorization],
      });
    解决方案：
      const executeHash = await walletClient.writeContract({
            account: eoa, 
            abi: DELAGATE_ABI,
            address:eoa.address,  // 问题所在  我们应该访问账户的智能合约地址
            functionName: 'execute',
            args: [calls],
            authorizationList: [authorization],
      });