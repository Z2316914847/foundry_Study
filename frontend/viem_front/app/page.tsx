'use client';      // 
/*
use client:
  是 Next.js（13+版本）中的一个关键指令，用于区分客户端组件和服务端组件，这里是客户端组件。代码会在浏览器中执行（而非Node.js服务器）。
  启用浏览器API和交互能力:允许在组件中使用：React状态（useState, useEffect 等）、事件监听（onClick, onChange 等）
    浏览器API（window, document, localStorage）第三方库（如动画库、图表库等依赖DOM的库）
  客户端组件：在浏览器中动态渲染，支持交互。
*/

// 这两个是Rect最常用的两个hooks，useState: 用于在函数组件中管理状态**​（数据变化时触发UI更新）。useEffect: 用于处理副作用**​（如数据获取、DOM操作、订阅等）。
import { useState, useEffect } from 'react';
import { createPublicClient, createWalletClient, http, formatEther, getContract, custom, parseEther } from 'viem';
import { sepolia } from 'viem/chains';
// import TokenBank_ABI from './contracts/TokenBank.json';
// import { ERC20_ABI } from './contracts/ERC20.json';
import { useAccount, useReadContract, useWriteContract } from 'wagmi'

// TokenBank 合约地址和合约ABI,   token的地址暂时不用
const TOKEN_BANK_ADDRESS = "0xb5A2Faf7aF7Bb5465909234a2ACD330F555F7a89";
// const TOKEN_ADDRESS = "0xc218690806F0a7F1656cCA01B0e6C5fB4D0Ec4cC";

const TOKENBANK_ABI = [
  {
      "type": "constructor",
      "inputs": [
          {
              "name": "tokenAddress",
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
              "internalType": "contract BaseERC20"
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
]

const TOKEN_ABI = [
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



export default function Home() {
  // 这段代码是 React 中使用 useState Hook 来声明一个状态变量及其更新函数，专门用于管理 ​字符串类型的余额数据
  // balance: 当前状态值（初始为字符串 '0'）。setBalance: 更新 balance 的函数。​useState<string>('0'): 显式声明状态类型为 string，初始值为 '0'。
  const [balance, setBalance] = useState<string>('0');
  const [tokenBalance, setTokenBalance] = useState<string>('0');  // 实时更新token余额
  const [depositBalance, setDepositBalance] = useState<string>('0');  // 实时更新存款余额
  const [depositAmount, setDepositAmount] = useState<string>('');   // 实时更新存款金额
  const [withdrawAmount, setWithdrawAmount] = useState<string>('');  // 实时更新取款金额

  // 这段代码是 React 中使用 TypeScript 的 useState Hook 来声明一个 ​以太坊地址状态变量，具有严格的类型安全约束。
  // 0x${string} | undefined>**: TypeScript 的联合类型，严格限定输入格式。
  const [address, setAddress] = useState<`0x${string}` | undefined>();  // 获取账户地址
  // 连接状态 isConnected当前状态值（boolean 类型），初始值为 false。  setIsConnected更新状态的函数，只能接受 boolean 值（true/false）。
  const [isConnected, setIsConnected] = useState(false);
  // chainId当前状态值，类型为 number | undefined。  setChainId更新状态的函数，只能接受 number/undefined 值。
  //   <number | undefined>明确允许两种状态：有效的链 ID（数字）未连接/未识别的状态（undefined）
  const [chainId, setChainId] = useState<number | undefined>();
  const [isLoading, setIsLoading] = useState(false);  // 加载状态
  const [txHash, setTxHash] = useState<string>('');  // 交易哈希
  const [error, setError] = useState<string>('');  // 错误信息

  // 链接sepolia测试网
  const publicClient = createPublicClient({
    chain: sepolia,
    // transport: http()
    transport: http('https://eth-sepolia.public.blastapi.io'),
    // transport: http('https://sepolia.infura.io/v3/0ecc55a11dfe4ef6b50caedf71c07b6b'),
  });

  // 检查是否为正确的网络,因为我们204行设置了sepolia网络，chainId初始值为undefined，在没有链接钱包之前，或者网络没有改到sepolia，isCorrectNetwork为false
  const isCorrectNetwork = chainId === sepolia.id;

  // 清除错误信息函数
  const clearError = () => setError('');

  // 定义一个异步函数connectWallet， async关键字声明这是一个异步函数，内部可使用 await 调用其他异步操作。
  // 连接钱包
  const connectWallet = async () => {
    setError('');

    if (typeof window === 'undefined') {
      setError('请在浏览器中运行此应用');
      return;
    }

    if (typeof window.ethereum === 'undefined') {
      setError('请安装 MetaMask 钱包');
      return;
    }

    try {
      setIsLoading(true);

      // 请求账户访问
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      });

      if (!accounts || accounts.length === 0) {
        setError('未获取到账户信息');
        return;
      }

      // 获取网络ID
      const networkId = await window.ethereum.request({
        method: 'eth_chainId'
      });

      const currentChainId = parseInt(networkId, 16);

      setAddress(accounts[0] as `0x${string}`);
      setChainId(currentChainId);
      setIsConnected(true);

      // 检查网络
      if (currentChainId !== sepolia.id) {
        setError(`请切换到 ${sepolia.name} 网络 (Chain ID: ${sepolia.id})`);

        // 尝试切换网络
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: `0x${sepolia.id.toString(16)}` }],
          });
        } catch (switchError: any) {
          // 如果网络不存在，尝试添加网络
          if (switchError.code === 4902) {
            try {
              await window.ethereum.request({
                method: 'wallet_addEthereumChain',
                params: [{
                  chainId: `0x${sepolia.id.toString(16)}`,
                  chainName: sepolia.name,
                  rpcUrls: ['https://eth-sepolia.public.blastapi.io'],
                  nativeCurrency: {
                    name: 'Sepolia ETH',
                    symbol: 'ETH',
                    decimals: 18,
                  },
                  blockExplorerUrls: ['https://sepolia.etherscan.io'],
                }],
              });
            } catch (addError) {
              console.error('添加网络失败:', addError);
              setError('无法添加 Sepolia 网络，请手动添加');
            }
          } else {
            console.error('切换网络失败:', switchError);
            setError('无法切换到 Sepolia 网络');
          }
        }
      }

      // 清除之前的事件监听器（避免重复注册）
      if (window.ethereum && typeof window.ethereum.removeAllListeners === 'function') {
        window.ethereum.removeAllListeners('accountsChanged');
        window.ethereum.removeAllListeners('chainChanged');
      }

      // 监听账户变化
      window.ethereum.on('accountsChanged', (accounts: string[]) => {
        if (accounts.length === 0) {
          setIsConnected(false);
          setAddress(undefined);
          setError('钱包已断开连接');
        } else {
          setAddress(accounts[0] as `0x${string}`);
          clearError();
        }
      });

      // 监听网络变化
      window.ethereum.on('chainChanged', (chainId: string) => {
        const newChainId = parseInt(chainId, 16);
        setChainId(newChainId);

        if (newChainId !== sepolia.id) {
          setError(`请切换到 ${sepolia.name} 网络 (Chain ID: ${sepolia.id})`);
        } else {
          clearError();
        }
      });

    } catch (error: any) {
      console.error('连接钱包失败:', error);

      // 处理常见错误
      if (error.code === 4001) {
        setError('用户拒绝了连接请求');
      } else if (error.code === -32002) {
        setError('MetaMask 正在处理请求，请检查扩展程序');
      } else if (error.message?.includes('User rejected')) {
        setError('用户拒绝了连接请求');
      } else {
        setError(`连接失败: ${error.message || '未知错误'}`);
      }
    } finally {
      setIsLoading(false);
    }
  };

  // 断开连接
  const disconnectWallet = () => {
    setIsConnected(false);
    setAddress(undefined);
    setChainId(undefined);
    setError('');

    // 清除事件监听器
    if (window.ethereum && typeof window.ethereum.removeAllListeners === 'function') {
      window.ethereum.removeAllListeners('accountsChanged');
      window.ethereum.removeAllListeners('chainChanged');
    }
  };

  // 获取 Token 余额和存款余额
  const fetchBalances = async () => {
    if (!address) return;
    try {
      // 获取TOKEN合约地址
      const tokenAddress = await publicClient.readContract({
        address: TOKEN_BANK_ADDRESS,
        abi: TOKENBANK_ABI,
        functionName: 'token',
        // args: [address]
      }) as `0x${string}`;
      const tokenBalance = await publicClient.readContract({
        address: tokenAddress,
        abi: TOKEN_ABI,
        functionName: 'balanceOf',
        args: [address]
      }) as bigint;
      // const decimals = await publicClient.readContract({
      //   address: tokenAddress,
      //   abi: TOKEN_ABI,
      //   functionName: 'decimals',
      //   // args: [address]
      // }) as number;

      // 查询用户在 TokenBank 中的存款余额
      const depositBalance = await publicClient.readContract({
        address: TOKEN_BANK_ADDRESS,
        abi: TOKENBANK_ABI,
        functionName: 'getdepositBalance',
        args: [address]
      }) as bigint;

      // 转换单位为完整代币数量
      const formatBalance = (value: bigint) => {
        return Number(value) / 10 ** 18;
      };

      setTokenBalance(formatBalance(tokenBalance).toString());
      setDepositBalance(formatBalance(depositBalance).toString());
    } catch (error) {
      console.error("获取余额失败:", error);
      setTokenBalance("0");
      setDepositBalance("0");
    }
  };

  // 存款
  const handleDeposit = async () => {
    if (!address || !depositAmount) return;
    setIsLoading(true);
    setTxHash('');

    const walletClient = createWalletClient({
      chain: sepolia,
      transport: custom(window.ethereum),
      // transport: http('https://eth-sepolia.public.blastapi.io')
    });

    try {
      // 获取TOKEN合约地址
      const tokenAddress = await publicClient.readContract({
        address: TOKEN_BANK_ADDRESS,
        abi: TOKENBANK_ABI,
        functionName: 'token',
      }) as `0x${string}`;
 
      const { request } = await publicClient.simulateContract({
        account:address,
        address: tokenAddress,
        abi: TOKEN_ABI,
        functionName: 'transfer',
        args: [TOKEN_BANK_ADDRESS, parseEther(depositAmount)]
      });
      const hash = await walletClient.writeContract( request );

      setTxHash(hash);

      // 等待交易确认后刷新余额
      await publicClient.waitForTransactionReceipt({ hash });
      fetchBalances();
      setDepositAmount('');
    } catch (error) {
      console.error('存款失败:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // 取款
  const handleWithdraw = async () => {
    if (!address || !withdrawAmount) return;
    setIsLoading(true);
    setTxHash('');

    const walletClient = createWalletClient({
      chain: sepolia,
      transport: custom(window.ethereum),
      // transport: http('https://eth-sepolia.public.blastapi.io')
    });

    try {
      // tokenBank取款
      const { request } = await publicClient.simulateContract({
        account:address,
        address: TOKEN_BANK_ADDRESS,
        abi: TOKENBANK_ABI,
        functionName: 'withdraw',
        args: [address, parseEther(withdrawAmount)]
      });

      const hash = await walletClient.writeContract( request );
      setTxHash(hash);

      // 等待交易确认后刷新余额
      await publicClient.waitForTransactionReceipt({ hash });
      fetchBalances();
      setWithdrawAmount('');
    } catch (error) {
      console.error('取款失败:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // 获取eth余额：useEffect(() => {...}, [address])	监听 address 的变化，变化时执行副作用函数
  useEffect(() => {
    // 定义一个异步函数fetchEthBalance，获取当前账户的ETH余额
    const fetchEthBalance = async () => {
      if (!address) return;

      const balance = await publicClient.getBalance({
        address: address,
      });

      setBalance(formatEther(balance));
    };

    if (address) {
      fetchEthBalance();
      fetchBalances();
    }
  }, [address]);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8">
      <h1 className="text-3xl font-bold mb-8">Token Bank Demo</h1>

      <div className="bg-white p-6 rounded-lg shadow-lg w-full max-w-2xl">
        {/* 错误提示 */}
        {error && (
          <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
            {error}
          </div>
        )}

        {!isConnected ? (
          <button
            onClick={connectWallet}
            disabled={isLoading}
            className={`w-full py-2 px-4 rounded transition-colors ${isLoading
                ? 'bg-gray-400 cursor-not-allowed'
                : 'bg-blue-500 hover:bg-blue-600'
              } text-white`}
          >
            {isLoading ? '连接中...' : '连接 MetaMask'}
          </button>
        ) : (
          <div className="space-y-4">
            <div className="text-center">
              <p className="text-gray-600">钱包地址:</p>
              <p className="font-mono break-all">{address}</p>
            </div>
            <div className="text-center">
              <p className="text-gray-600">当前网络:</p>
              <p className={`font-mono ${isCorrectNetwork ? 'text-green-600' : 'text-red-600'}`}>
                {chainId === sepolia.id ? sepolia.name : `未知网络 (Chain ID: ${chainId})`}
                {!isCorrectNetwork && (
                  <span className="block text-sm text-red-500 mt-1">
                    ⚠️ 请切换到 {sepolia.name} 网络
                  </span>
                )}
              </p>
            </div>
            <div className="text-center">
              <p className="text-gray-600">钱包 ETH 余额:</p>
              <p className="font-mono">{balance} ETH</p>
            </div>

            {/* Token 余额显示 */}
            <div className="text-center">
              <p className="text-gray-600">您的Token 余额:</p>
              <p className="font-mono">{tokenBalance} Token</p>
            </div>

            {/* 存款余额显示 */}
            <div className="text-center">
              <p className="text-gray-600">您在TokenBank中Token存款余额:</p>
              <p className="font-mono">{depositBalance} Token</p>
            </div>

            {/* 存款表单 */}
            <div className="border p-4 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">存款</h3>
              <div className="flex space-x-2">
                <input
                  type="text"
                  value={depositAmount}
                  onChange={(e) => setDepositAmount(e.target.value)}
                  placeholder="输入存款金额"
                  className="flex-1 border rounded p-2"
                  disabled={isLoading}
                />
                <button
                  onClick={handleDeposit}
                  disabled={isLoading || !depositAmount || !isCorrectNetwork}
                  className={`px-4 py-2 rounded ${isLoading || !isCorrectNetwork
                      ? 'bg-gray-400 cursor-not-allowed'
                      : 'bg-green-500 hover:bg-green-600'
                    } text-white`}
                >
                  {isLoading ? '处理中...' : !isCorrectNetwork ? '网络错误' : '存款'}
                </button>
              </div>
            </div>

            {/* 取款表单 */}
            <div className="border p-4 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">取款</h3>
              <div className="flex space-x-2">
                <input
                  type="text"
                  value={withdrawAmount}
                  onChange={(e) => setWithdrawAmount(e.target.value)}
                  placeholder="输入取款金额"
                  className="flex-1 border rounded p-2"
                  disabled={isLoading}
                />
                <button
                  onClick={handleWithdraw}
                  disabled={isLoading || !withdrawAmount || !isCorrectNetwork}
                  className={`px-4 py-2 rounded ${isLoading || !isCorrectNetwork
                      ? 'bg-gray-400 cursor-not-allowed'
                      : 'bg-red-500 hover:bg-red-600'
                    } text-white`}
                >
                  {isLoading ? '处理中...' : !isCorrectNetwork ? '网络错误' : '取款'}
                </button>
              </div>
            </div>

            {/* 交易哈希显示 */}
            {txHash && (
              <div className="text-center">
                <p className="text-gray-600">交易哈希:</p>
                <p className="font-mono break-all text-blue-500">{txHash}</p>
              </div>
            )}

            <button
              onClick={disconnectWallet}
              className="w-full bg-red-500 text-white py-2 px-4 rounded hover:bg-red-600 transition-colors"
            >
              断开连接
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
