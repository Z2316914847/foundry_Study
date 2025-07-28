安装viem ：pnpm add viem

安装node：pnpm install --save-dev @types/node

安装doten：pnpm install dotenv

安装：npm install @ethersproject/wallet

创建:.env文件，添加环境变量

安裝命令行工具：npm install viem readline


需求：
    编写一个脚本（可以基于 Viem.js 、Ethers.js 或其他的库来实现）来模拟一个命令行钱包，钱包包含的功能有：生成私钥、查询余额（可人工转入金额）
    构建一个 ERC20 转账的 EIP 1559 交易用 1 生成的账号，对 ERC20 转账进行签名
    发送交易到 Sepolia 网络。

遇到的问题：
    EIP1559提案：它彻底改变了以太坊的交易费用机制，旨在解决 Gas 费波动性，用户体验和网络经济问题。
    新的费用结构：
        基础费用（base Fee）:费用的大小根据网络拥堵程度自动变化。基础费被用于销毁，而非支付给矿工的。消减矿工恶意抬高价格的动机。
        小费（priority Fee）：支付给矿工的小费
        最大费用（max Fee）：用户可以设置的最大费用，实际费用不会超过这个值。
    2.运行ts文件，运行不起来：
        npx ts-node	ts文件名 
            npx:Node.js 自带的包执行工具，无需全局安装即可运行本地或远程 npm 包
            ts-node：一个 TypeScript 执行环境，能够直接运行 .ts 文件而无需手动编译
            ts文件名：具体要运行的文件名
    3.privateKeyToAccount():根据私钥生成账户对象，账户对象.address能获取到账户地址，账户.privateKey获取不到私钥。可以通过这种方式获取私钥：const privateKey = `0x${randomBytes(32).toString('hex')}` as `0x${string}`


