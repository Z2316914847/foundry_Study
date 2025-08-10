import { createPublicClient, createWalletClient, http, encodeFunctionData, getContract, parseEther } from 'viem';
import { sepolia, foundry } from 'viem/chains';

import { privateKeyToAccount } from 'viem/accounts';
// import type { TransactionReceipt } from 'viem';

// permit2Address = "0x075a6d7fAeEce75bebF4Cd18b47c26EF9C9F06A9";
const TOKEN_ADDRESS = "0xEB1e2574b0cbEeb3fDf51b403F189d47639B2578";
const TOKENBANK_ADDRESS = "0x534b6bBE77d7f82cF1cdd4c7d2CE96F7C19D66AB";
const DELAGATE_ADDRESS = "0x7273997CcBC29a2c070bE4C2Cb078Cd86695EDDC";
const TOKEN_ABI = [
    {
        "type": "constructor",
        "inputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "DOMAIN_SEPARATOR",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "allowance",
        "inputs": [
            {
                "name": "_owner",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_spender",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "remaining",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "approve",
        "inputs": [
            {
                "name": "_spender",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_value",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "approve2",
        "inputs": [
            {
                "name": "_from",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_spender",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_value",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "balanceOf",
        "inputs": [
            {
                "name": "_owner",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "balance",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "decimals",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint8",
                "internalType": "uint8"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "name",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "string",
                "internalType": "string"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "nonces",
        "inputs": [
            {
                "name": "owner",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "permit",
        "inputs": [
            {
                "name": "owner",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "spender",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "deadline",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "v",
                "type": "uint8",
                "internalType": "uint8"
            },
            {
                "name": "r",
                "type": "bytes32",
                "internalType": "bytes32"
            },
            {
                "name": "s",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "symbol",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "string",
                "internalType": "string"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "totalSupply",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "transfer",
        "inputs": [
            {
                "name": "_to",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_value",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "success",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "transferFrom",
        "inputs": [
            {
                "name": "_from",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_to",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_value",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "success",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "transferWithCallback",
        "inputs": [
            {
                "name": "to",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "amount",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "event",
        "name": "Approval",
        "inputs": [
            {
                "name": "owner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "spender",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "Transfer",
        "inputs": [
            {
                "name": "from",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "to",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    }
];
const TOKENBANK_ABI =  [
    {
        "type": "constructor",
        "inputs": [
            {
                "name": "tokenAddress",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "permit2Address",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "receive",
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "LESS_MONEY",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "deposit",
        "inputs": [
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
        "name": "depositWithPermit2",
        "inputs": [
            {
                "name": "amount",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "nonce",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "deadline",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "v",
                "type": "uint8",
                "internalType": "uint8"
            },
            {
                "name": "r",
                "type": "bytes32",
                "internalType": "bytes32"
            },
            {
                "name": "s",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "getdepositBalance",
        "inputs": [
            {
                "name": "addr",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "name",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "string",
                "internalType": "string"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "permit2",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "contract Permit2"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "permitDeposit",
        "inputs": [
            {
                "name": "amount",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "deadline",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "v",
                "type": "uint8",
                "internalType": "uint8"
            },
            {
                "name": "r",
                "type": "bytes32",
                "internalType": "bytes32"
            },
            {
                "name": "s",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "symbol",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "string",
                "internalType": "string"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "token",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "contract ownerERC20Permit"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "tokensReceived",
        "inputs": [
            {
                "name": "from",
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
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "withdraw",
        "inputs": [
            {
                "name": "to",
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
        "stateMutability": "nonpayable"
    },
    {
        "type": "event",
        "name": "WithdrawMoney",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "indexed": false,
                "internalType": "address"
            },
            {
                "name": "",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "depositMoney",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "indexed": false,
                "internalType": "address"
            },
            {
                "name": "",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "tranferSuccess",
        "inputs": [
            {
                "name": "",
                "type": "string",
                "indexed": false,
                "internalType": "string"
            }
        ],
        "anonymous": false
    }
];
const DELAGATE_ABI = [
    {
        "type": "fallback",
        "stateMutability": "payable"
    },
    {
        "type": "receive",
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "execute",
        "inputs": [
            {
                "name": "calls",
                "type": "tuple[]",
                "internalType": "struct SimpleDelegateContract.Calls[]",
                "components": [
                    {
                        "name": "to",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "data",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "value",
                        "type": "uint256",
                        "internalType": "uint256"
                    }
                ]
            }
        ],
        "outputs": [],
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "initialize",
        "inputs": [],
        "outputs": [],
        "stateMutability": "payable"
    },
    {
        "type": "event",
        "name": "Log",
        "inputs": [
            {
                "name": "message",
                "type": "string",
                "indexed": false,
                "internalType": "string"
            }
        ],
        "anonymous": false
    }
];

const PRICATE_KET = "0xxx";
const eoa = privateKeyToAccount(PRICATE_KET as `0x${string}`);
// const DEPOSIT_AMOUNT = 1000000000000000000n; // 1 token  这个需要模块支持：ES2020，没有安装所以用下面的方法
const DEPOSIT_AMOUNT = BigInt("1000000000000000000"); // 注意这里是字符串

// 查询指定地址的链上代码
async function getCodeAtAddress(address: string, publicClient:any) {
    const code = await publicClient.getBytecode({ address: address as `0x${string}` });
    console.log(`地址 ${address} 的链上代码:`, code);
    return code;
}
  
async function getTokenBalance(userAddress: string, publicClient:any, walletClient:any) {
    const eoaTokenBalance = await publicClient.readContract({
        address: TOKEN_ADDRESS,
        abi: TOKEN_ABI,
        functionName: 'balanceOf',
        args: [userAddress],
    });
    console.log('用户ERC20余额:', eoaTokenBalance);
    return eoaTokenBalance;
}

async function checkAccountStatus(userAddress: string, publicClient: any) {
    try {
        const nonce = await publicClient.getTransactionCount({ address: userAddress });
        const balance = await publicClient.getBalance({ address: userAddress });
        console.log(`账户状态检查:`);
        console.log(`- 地址: ${userAddress}`);
        console.log(`- 当前nonce: ${nonce}`);
        console.log(`- ETH余额: ${balance} wei`);
        return { nonce, balance };
    } catch (error) {
        console.error('检查账户状态失败:', error);
        return null;
    }
}

async function main() {
    try {        
        // 1.获取客户端
        const publicClient = createPublicClient({ 
            chain: sepolia,
            transport: http('https://eth-sepolia.public.blastapi.io')
        });
        const walletClient = createWalletClient({
            chain: sepolia,
            transport: http('https://eth-sepolia.public.blastapi.io')
        });

        // 0. 查询eoa的链上代码
        await getCodeAtAddress(eoa.address, publicClient);
        await getTokenBalance(eoa.address, publicClient, walletClient);
        
        // 检查账户状态
        await checkAccountStatus(eoa.address, publicClient);

        // 2.构造交易数据  encodeFunctionData 设置编码  也就是将方法和参数编码成字节码
        const approveCalldata = encodeFunctionData({
            abi: TOKEN_ABI,
            functionName: 'approve',
            args: [TOKENBANK_ADDRESS, DEPOSIT_AMOUNT],
          });
        const depositCalldata = encodeFunctionData({
            abi: TOKENBANK_ABI,
            functionName: 'deposit',
            args: [DEPOSIT_AMOUNT],
        });
        const calls = [
            {
                to:TOKEN_ADDRESS,   // 合约地址
                data:approveCalldata,  // 合约方法调用
                value: BigInt(0),
            },
            {
                to:TOKENBANK_ADDRESS ,
                data:depositCalldata,
                value: BigInt(0),
            }
        ];

        // 3.构建7702消息需要的数据： authorization_list   ＋  将用户设置为智能合约  也就是说这个合约获得用户授权
        console.log('正在签名授权...');
        const authorization = await walletClient.signAuthorization({
            account: eoa,
            contractAddress: DELAGATE_ADDRESS,
            executor: 'self', 
        }); 
        console.log('EIP-7702授权生成成功:', authorization);

        // 4. 发送 EIP-7702 交易
        console.log('正在发送EIP-7702批量交易...');
        const executeHash = await walletClient.writeContract({
            account: eoa, 
            abi: DELAGATE_ABI,
            address:eoa.address,   // 设置为账户的智能合约地址
            functionName: 'execute',
            args: [calls],
            authorizationList: [authorization],
        });
        console.log('EIP-7702 批量交易已发送，tx hash:', executeHash);
        
        // 等待批量交易完成
        await publicClient.waitForTransactionReceipt({ hash: executeHash });
        console.log('EIP-7702 批量交易已确认');

        // 检查存款情况
        const depositBalance = await publicClient.readContract({
            address: TOKENBANK_ADDRESS,
            abi: TOKENBANK_ABI,
            functionName: 'getdepositBalance',
            args: [eoa.address],
        });
        console.log('存款余额:', depositBalance);

    } catch (error: any) {
        console.error('执行过程中发生错误:', error);
        
        // 如果是nonce错误，提供解决方案
        if (error.message && error.message.includes('nonce')) {
            console.log('\n解决方案:');
            console.log('1. 等待几分钟让之前的交易被确认');
            console.log('2. 或者使用新的账户重新测试');
        }
        
        // 如果是交易限制错误，提供解决方案
        if (error.message && error.message.includes('in-flight transaction limit')) {
            console.log('\n解决方案:');
            console.log('1. 等待之前的交易被确认（通常需要几分钟）');
            console.log('2. 检查账户是否有太多待处理交易');
            console.log('3. 考虑使用新的账户进行测试');
        }
    }
}

main();