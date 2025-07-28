import { createWalletClient, createPublicClient, http, parseEther, formatEther } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { sepolia } from 'viem/chains'
// import { erc20Abi } from 'viem'
import readline from 'readline'
import { randomBytes } from 'crypto'

// 设置命令行交互
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
})

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http()
})

const walletClient = createWalletClient({
  chain: sepolia,
  transport: http()
})

const erc20Abi = [
  {
      "type": "constructor",
      "inputs": [],
      "stateMutability": "nonpayable"
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
]

// 钱包状态
let account: any = null
let walletAddress: string = ''

// 主菜单
function mainMenu() {
  console.log('\n=== 命令行钱包 ===')
  console.log('1. 生成新私钥')
  console.log('2. 导入私钥')
  console.log('3. 查询余额')
  console.log('4. 发送ETH')
  console.log('5. 发送ERC20代币')
  console.log('6. 退出')

  rl.question('请选择操作: ', async (choice) => {
    switch (choice) {
      case '1':
        await generatePrivateKey()
        break
      case '2':
        await importPrivateKey()
        break
      case '3':
        await checkBalance()
        break
      case '4':
        await sendETH()
        break
      case '5':
        await sendERC20()
        break
      case '6':
        rl.close()
        process.exit(0)
      default:
        console.log('无效选择')
        mainMenu()
    }
  })
}

// 1. 生成新私钥
async function generatePrivateKey() {
  // privateKeyToAccount：将私钥转为账户对象
  // const privateKey = generatePrivateKey() // viem提供的随机生成私钥方法、import { generatePrivateKey } from 'viem/accounts'
  const privateKey = `0x${randomBytes(32).toString('hex')}` as `0x${string}`
  account = privateKeyToAccount(privateKey)
  // 获取账户地址
  walletAddress = account.address
  console.log('\n新账户已生成:')
  console.log('地址:', walletAddress)
  console.log('私钥:', privateKey)
  console.log('\n请妥善保存私钥！')
  mainMenu()
}

// 2. 导入私钥
async function importPrivateKey() {
  rl.question('请输入私钥: ', (privateKey) => {
    try {
      // 如果私钥没有0x前缀，自动添加
      const formattedPrivateKey = privateKey.trim().startsWith('0x') 
        ? privateKey.trim() 
        : `0x${privateKey.trim()}`
      
      account = privateKeyToAccount(formattedPrivateKey as `0x${string}`)
      walletAddress = account.address
      console.log('\n账户已导入:')
      console.log('地址:', walletAddress)
    } catch (e) {
      console.log('无效的私钥格式')
    }
    mainMenu()
  })
}

// 3. 查询余额
async function checkBalance() {
  if (!walletAddress) {
    console.log('请先生成或导入账户')
    return mainMenu()
  }

  try {
    const balance = await publicClient.getBalance({
      address: walletAddress as `0x${string}`
    })
    console.log(`\n余额: ${formatEther(balance)} ETH`)
    
    // 这里可以添加ERC20代币余额查询
  } catch (e) {
    console.log('查询余额失败:', e)
  }
  mainMenu()
}

// 4. 发送ETH
async function sendETH() {
  if (!account) {
    console.log('请先生成或导入账户')
    return mainMenu()
  }

  rl.question('请输入接收地址: ', async (toAddress) => {
    rl.question('请输入发送金额(ETH): ', async (amount) => {
      try {
        console.log('\n准备发送交易...')
        
        const txHash = await walletClient.sendTransaction({
          account,
          to: toAddress.trim() as `0x${string}`,
          value: parseEther(amount)
        })
        
        console.log('交易已发送，哈希:', txHash)
        console.log('可以在 https://sepolia.etherscan.io/tx/' + txHash + ' 查看详情')
      } catch (e) {
        console.log('发送交易失败:', e)
      }
      mainMenu()
    })
  })
}

// 5. 发送ERC20代币
async function sendERC20() {
  if (!account) {
    console.log('请先生成或导入账户')
    return mainMenu()
  }

  rl.question('请输入代币合约地址: ', async (tokenAddress) => {
    rl.question('请输入接收地址: ', async (toAddress) => {
      rl.question('请输入发送金额: ', async (amount) => {
        try {
          console.log('\n准备发送ERC20交易...')
          
          // simulateContract()：模拟和验证合约的交互
          const { request } = await publicClient.simulateContract({
            account,
            address: tokenAddress.trim() as `0x${string}`,
            abi: erc20Abi,
            functionName: 'transfer',
            args: [toAddress.trim() as `0x${string}`, parseEther(amount)],
             // EIP-1559 特定参数
            type: 'eip1559',  // viem写法：type: 'eip1559'。ether.js写法：type: 2
            maxPriorityFeePerGas: parseEther('0.00000000001'), // 适当的小费
            maxFeePerGas: parseEther('0.00002') // 最大 gas 费
          })
          
          // 执行合约写入以执行交易
          const txHash = await walletClient.writeContract({
            ...request,
            account
          })
          
          console.log('ERC20交易已发送，哈希:', txHash)
          console.log('可以在 https://sepolia.etherscan.io/tx/' + txHash + ' 查看详情')
        } catch (e) {
          console.log('发送ERC20交易失败:', e)
        }
        mainMenu()
      })
    })
  })
}

// 启动钱包
console.log('命令行钱包启动...')
mainMenu()