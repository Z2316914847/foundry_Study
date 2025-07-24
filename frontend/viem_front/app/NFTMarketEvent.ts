import {
    createPublicClient,
    formatEther,
    getContract,
    http,
    publicActions,
    type Log,
} from "viem";
import { foundry } from "viem/chains";
import dotenv from "dotenv";
// import ERC20_ABI from './abis/MyERC20.json' with { type: 'json' };

dotenv.config();

const NFTMARKET_ADDRESS = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9";

const NFTMARKET_ABI = [
        {
            "type": "constructor",
            "inputs": [],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "buyNFT",
            "inputs": [
                {
                    "name": "nftContract",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [],
            "stateMutability": "payable"
        },
        {
            "type": "function",
            "name": "buyNFTWith_Token",
            "inputs": [
                {
                    "name": "nftContract",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "token",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "amount",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [],
            "stateMutability": "payable"
        },
        {
            "type": "function",
            "name": "cancelListing",
            "inputs": [
                {
                    "name": "nftContract",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "list",
            "inputs": [
                {
                    "name": "nftContract",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "price",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "listings",
            "inputs": [
                {
                    "name": "",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [
                {
                    "name": "seller",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "price",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "event",
            "name": "Canceled",
            "inputs": [
                {
                    "name": "nftContract",
                    "type": "address",
                    "indexed": true,
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "indexed": true,
                    "internalType": "uint256"
                }
            ],
            "anonymous": false
        },
        {
            "type": "event",
            "name": "Listed",
            "inputs": [
                {
                    "name": "nftContract",
                    "type": "address",
                    "indexed": true,
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "indexed": true,
                    "internalType": "uint256"
                },
                {
                    "name": "seller",
                    "type": "address",
                    "indexed": false,
                    "internalType": "address"
                },
                {
                    "name": "price",
                    "type": "uint256",
                    "indexed": false,
                    "internalType": "uint256"
                }
            ],
            "anonymous": false
        },
        {
            "type": "event",
            "name": "Purchased",
            "inputs": [
                {
                    "name": "nftContract",
                    "type": "address",
                    "indexed": true,
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "indexed": true,
                    "internalType": "uint256"
                },
                {
                    "name": "buyer",
                    "type": "address",
                    "indexed": false,
                    "internalType": "address"
                },
                {
                    "name": "seller",
                    "type": "address",
                    "indexed": false,
                    "internalType": "address"
                },
                {
                    "name": "price",
                    "type": "uint256",
                    "indexed": false,
                    "internalType": "uint256"
                }
            ],
            "anonymous": false
        }
    ];

const publicClient = createPublicClient({
    chain: foundry, // 替换为你的链
    transport: http(process.env.RPC_URL),
})

async function watchMarketEvents() {
    console.log('开始监听 NFTMarket 事件...')
  
    // 监听 Listed 事件
    const unwatchListed = publicClient.watchContractEvent({
      address: NFTMARKET_ADDRESS,
      abi: NFTMARKET_ABI,
      eventName: 'Listed',
      onLogs: (logs) => {
        logs.forEach((log: any) => {
          const args = log.args || log;
          const { nftContract, tokenId, seller, price } = args;
          console.log(`[上架] NFT合约: ${nftContract}, TokenID: ${tokenId}`);
          console.log(`卖家: ${seller}, 价格: ${price} wei`);
          console.log(`交易哈希: ${log.transactionHash}\n`);
        //   logs.forEach((log: any) => {
        //     console.log('log结构:', log);
        //   });
        });
      },
    })
  
    // 监听 Purchased 事件
    const unwatchPurchased = publicClient.watchContractEvent({
        address: NFTMARKET_ADDRESS,
        abi: NFTMARKET_ABI,
        eventName: 'Purchased',
        onLogs: (logs) => {
            logs.forEach((log: any) => {
                logs.forEach((log: any) => {
                  console.log('log结构:', log);
            //   const args = log.args || log;
            //   const { nftContract, tokenId, seller, price } = args;
            //   console.log(`[购买] NFT合约: ${nftContract}, TokenID: ${tokenId}`)
            //   console.log(`买家: ${buyer}, 卖家: ${seller}, 价格: ${price} wei`)
            //   console.log(`交易哈希: ${log.transactionHash}\n`)
            })
          },
    })

    const unwatchCanceled = publicClient.watchContractEvent({
        address: NFTMARKET_ADDRESS,
        abi: NFTMARKET_ABI,
        eventName: 'Canceled',
        onLogs: (logs) => {
          logs.forEach((log) => {
            const { nftContract, tokenId } = log as any;
            console.log(`[取消] NFT合约: ${nftContract}, TokenID: ${tokenId}`)
            console.log(`交易哈希: ${log.transactionHash}\n`)
          })
        },
      })
  
    // 关闭监听（示例：10秒后自动停止）
    // setTimeout(() => {
    //   unwatchListed()
    //   unwatchPurchased()
    //   unwatchCanceled()
    //   console.log('已停止监听事件')
    // }, 10_000)
}
watchMarketEvents().catch(console.error)














// const main = async () => {
//     // 创建公共客户端
//     const publicClient = createPublicClient({
//         chain: foundry,
//         transport: http(process.env.RPC_URL!),
//     }).extend(publicActions);

//     console.log('开始监听 ERC20 转账事件...');

//     // 监听 Transfer 事件
//     // cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "transfer(address,uint256)" 0x01BF49D75f2b73A2FDEFa7664AEF22C86c5Be3df 1000000000000000000 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
//     const unwatch = publicClient.watchEvent({
//         address: NFTMARKET_ADDRESS,
//         event: {
//             type: 'event',
//             name: 'list',
//             inputs: [
//                 { type: 'address', name: 'from', indexed: true },
//                 { type: 'address', name: 'to', indexed: true },
//                 { type: 'uint256', name: 'value' }
//             ]
//         },
//         onLogs: (logs) => {
//             logs.forEach((log) => {
//                 if (log.args.value !== undefined) {
//                     console.log('\n检测到新的转账事件:');
//                     console.log(`从: ${log.args.from}`);
//                     console.log(`到: ${log.args.to}`);
//                     console.log(`金额: ${formatEther(log.args.value)}`);
//                     console.log(`交易哈希: ${log.transactionHash}`);
//                     console.log(`区块号: ${log.blockNumber}`);
//                 }
//             });
//         }
//     });

//     // 保持程序运行
//     process.on('SIGINT', () => {
//         console.log('\n停止监听...');
//         unwatch();
//         process.exit();
//     });
// };

// main().catch((error) => {
//     console.error('发生错误:', error);
//     process.exit(1);
// }); 