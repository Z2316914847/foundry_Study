// chains/config.ts
import { sepolia, polygon, arbitrum } from 'viem/chains';

export const CHAINS = {
  ethereum: {
    id: 1,
    name: 'Ethereum',
    chain: sepolia,
    transport: http(),
    explorer: 'https://etherscan.io'
  },
  polygon: {
    id: 137,
    name: 'Polygon',
    chain: polygon,
    transport: http('https://polygon-rpc.com'),
    explorer: 'https://polygonscan.com'
  },
  arbitrum: {
    id: 42161,
    name: 'Arbitrum',
    chain: arbitrum,
    transport: http('https://arb1.arbitrum.io/rpc'),
    explorer: 'https://arbiscan.io'
  }
} as const;