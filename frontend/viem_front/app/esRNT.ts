import { createPublicClient, http, toHex, keccak256, toBytes,hexToBytes } from 'viem'
import { mainnet, foundry } from 'viem/chains'


// 创建公共客户端
const client = createPublicClient({
  chain: foundry,
  transport: http("http://localhost:8545")
})

// esRNT 合约地址 (替换为实际地址)
const contractAddress = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512' 

// 读取 _locks 数组长度
async function getLocksArrayLength() {
  // const lengthSlot = '0x0' // _locks 是第一个状态变量
  const lengthHex = await client.getStorageAt({
    address: contractAddress,
    // slot: lengthSlot
    slot: toHex(0)
  })
  // lengthHex 返回的是十六进制的字符串，需要转换成十进制的数字，后面16是为了说明lengthHex是16进制的字符串
  return parseInt(lengthHex || '0x0', 16)
}

// 读取单个 LockInfo
async function getLockInfo(index: number) {
  // 计算数组元素的开始位置
  // const arraySlot = BigInt(keccak256(toBytes('0x00')))  // 数组其实存储元素起始位置，存储第一个元素
  const arraySlot = BigInt(
    keccak256(
      hexToBytes(
        '0x0000000000000000000000000000000000000000000000000000000000000000' // 32字节零填充,并且这是存储槽第一个即:slot0
      )
      // toBytes( toHex(0))  写法错误  
    )
  )
  const slot1 = toHex(arraySlot + BigInt(index * 2))
  const slot2 = toHex(arraySlot + BigInt(index * 2 + 1))

  // 读取两个存储槽
  const [slot1Data, slot2Data] = await Promise.all([
    client.getStorageAt({ address: contractAddress, slot: slot1 }),
    client.getStorageAt({ address: contractAddress, slot: slot2 })
  ])

  // 解析数据
  const user = '0x' + slot1Data?.slice(26) // address 是最后20字节
  const startTime = parseInt(slot1Data?.slice(2, 18) || '0', 16) // uint64 在前8字节
  const amount = parseInt(slot2Data || '0x0', 16) // uint256 在第二个槽

  return { user, startTime, amount }
}

// 获取并打印所有 locks
async function printAllLocks() {
  const length = await getLocksArrayLength()
  console.log(`Total locks: ${length}`)

  for (let i = 0; i < length; i++) {
    const lock = await getLockInfo(i)
    console.log(
      `locks[${i}]: user: ${lock.user}, ` +
      `startTime: ${lock.startTime}, ` +
      `amount: ${lock.amount}`
    )
  }
}

// 运行
printAllLocks().catch(console.error)
