好的，我来为您补全缺失的部分，并在文档开头添加一个详细的目录。

---

# **EVM操作码完整中文文档**

**文档说明**：
- **Gas** 列为大致估算，实际成本可能因硬分叉升级（如柏林、伦敦）而变动。
- **堆栈** 列使用简写：`value` 表示任意值，`offset` 表示内存偏移，`key` 和 `value` 表示存储键值。
- 操作码后的数字（如 `PUSH1`）表示操作码携带的字节数。

## **目录**

1. [停止和算术运算](#1-停止和算术运算-stop-and-arithmetic)
2. [比较和位运算](#2-比较和位运算-comparison--bitwise-logic)
3. [密码学操作](#3-密码学操作-cryptographic)
4. [区块信息](#4-区块信息-block-information)
5. [堆栈、内存、存储和流程控制](#5-堆栈内存存储和流程控制-stack-memory-storage-and-flow)
6. [推送操作](#6-推送操作-push-operations)
7. [复制和交换操作](#7-复制和交换操作-duplication--exchange-operations)
8. [日志记录](#8-日志记录-logging)
9. [系统操作](#9-系统操作-system-operations)

---

### **1. 停止和算术运算 (Stop and Arithmetic)**

这些是基础的计算和流程控制操作。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **STOP** | 0x00 | 0 | - | - | 暂停合约执行，**成功**结束 |
| **ADD** | 0x01 | 3 | a, b | (a + b) | 加法（模 2^256） |
| **MUL** | 0x02 | 5 | a, b | (a * b) | 乘法（模 2^256） |
| **SUB** | 0x03 | 3 | a, b | (a - b) | 减法（模 2^256） |
| **DIV** | 0x04 | 5 | a, b | (a // b) | 无符号整数除法（除数为0则返回0） |
| **SDIV** | 0x05 | 5 | a, b | (a // b) | **有符号**整数除法（除数为0则返回0） |
| **MOD** | 0x06 | 5 | a, b | (a % b) | 无符号取模（模数为0则返回0） |
| **SMOD** | 0x07 | 5 | a, b | (a % b) | **有符号**取模（模数为0则返回0） |
| **ADDMOD** | 0x08 | 8 | a, b, N | (a + b) % N | 无符号加法取模（模数为0则返回0） |
| **MULMOD** | 0x09 | 8 | a, b, N | (a * b) % N | 无符号乘法取模（模数为0则返回0） |
| **EXP** | 0x0A | 10 + 50 * 字节大小 | base, exponent | base^exponent | 指数运算 |
| **SIGNEXTEND** | 0x0B | 5 | b, x | 符号扩展值 | 将 `x` 的符号位从第 `b` 字节开始扩展至32字节 |

[返回目录](#目录)

---

### **2. 比较和位运算 (Comparison & Bitwise Logic)**

用于比较值和进行位级操作。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LT** | 0x10 | 3 | a, b | (a < b) ? 1 : 0 | 无符号小于 |
| **GT** | 0x11 | 3 | a, b | (a > b) ? 1 : 0 | 无符号大于 |
| **SLT** | 0x12 | 3 | a, b | (a < b) ? 1 : 0 | **有符号**小于 |
| **SGT** | 0x13 | 3 | a, b | (a > b) ? 1 : 0 | **有符号**大于 |
| **EQ** | 0x14 | 3 | a, b | (a == b) ? 1 : 0 | 等于 |
| **ISZERO** | 0x15 | 3 | a | (a == 0) ? 1 : 0 | 判断是否为0 |
| **AND** | 0x16 | 3 | a, b | (a & b) | 按位与 |
| **OR** | 0x17 | 3 | a, b | (a \| b) | 按位或 |
| **XOR** | 0x18 | 3 | a, b | (a ^ b) | 按位异或 |
| **NOT** | 0x19 | 3 | a | ~a | 按位取反 |
| **BYTE** | 0x1A | 3 | i, x | byte | 从 `x` 的第 `i` 个字节（0为最高位） |
| **SHL** | 0x1B | 3 | shift, value | value << shift | 左移（自 Constantinople 硬分叉） |
| **SHR** | 0x1C | 3 | shift, value | value >> shift | **逻辑**右移（自 Constantinople） |
| **SAR** | 0x1D | 3 | shift, value | value >> shift | **算术**右移（保留符号位，自 Constantinople） |

[返回目录](#目录)

---

### **3. 密码学操作 (Cryptographic)**

执行哈希和地址派生。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SHA3** | 0x20 | 30 + 6 * 数据大小 | offset, size | keccak256(mem[offset:offset+size]) | 计算内存中数据的 Keccak-256 哈希 |
| **ADDRESS** | 0x30 | 2 | - | address | 获取当前执行合约的地址 |
| **BALANCE** | 0x31 | 100 (热) / 2600 (冷) | address | balance | 获取指定地址的以太币余额（单位：wei） |
| **ORIGIN** | 0x32 | 2 | - | address | 获取原始交易发起者（EOA）地址 |
| **CALLER** | 0x33 | 2 | - | address | 获取当前调用者（`msg.sender`）地址 |
| **CALLVALUE** | 0x34 | 2 | - | value | 获取随调用发送的以太币数量（`msg.value`） |
| **CALLDATALOAD** | 0x35 | 3 | offset | data[offset:offset+32] | 从调用数据（`calldata`）中加载32字节 |
| **CALLDATASIZE** | 0x36 | 2 | - | size | 获取调用数据（`calldata`）的大小 |
| **CALLDATACOPY** | 0x37 | 3 + 3 * 字节大小 | destOffset, offset, size | - | 从 `calldata` 复制数据到内存 |
| **CODESIZE** | 0x38 | 2 | - | size | 获取当前合约代码的大小 |
| **CODECOPY** | 0x39 | 3 + 3 * 字节大小 | destOffset, offset, size | - | 从当前合约代码复制数据到内存 |
| **EXTCODESIZE** | 0x3B | 100 (冷) / 2600 (冷) | address | size | 获取指定地址的合约代码大小 |
| **EXTCODECOPY** | 0x3C | 100 (冷) + 3 * 字节大小 | addr, destOff, off, size | - | 从指定地址的合约代码复制数据到内存 |
| **EXTCODEHASH** | 0x3F | 100 (冷) / 2600 (冷) | address | hash | 获取指定地址合约代码的哈希（空账户返回0） |

[返回目录](#目录)

---

### **4. 区块信息 (Block Information)**

获取当前区块的上下文信息。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **BLOCKHASH** | 0x40 | 20 | blockNumber | hash | 获取最近256个区块内某个区块的哈希 |
| **COINBASE** | 0x41 | 2 | - | address | 获取当前区块的矿工/验证者地址 |
| **TIMESTAMP** | 0x42 | 2 | - | timestamp | 获取当前区块的时间戳（Unix 时间） |
| **NUMBER** | 0x43 | 2 | - | blockNumber | 获取当前区块的编号 |
| **PREVRANDAO**/DIFFICULTY | 0x44 | 2 | - | randomness/difficulty | 获取随机值（PoS）或难度（PoW） |
| **GASLIMIT** | 0x45 | 2 | - | gasLimit | 获取当前区块的 Gas 上限 |
| **CHAINID** | 0x46 | 2 | - | chainId | 获取当前链的 ID（自 Istanbul 硬分叉） |
| **SELFBALANCE** | 0x47 | 5 | - | balance | 获取当前合约的余额（Gas 比 `BALANCE` 更优） |
| **BASEFEE** | 0x48 | 2 | - | baseFee | 获取当前区块的基础费用（自 London 硬分叉） |

[返回目录](#目录)

---

### **5. 堆栈、内存、存储和流程控制 (Stack, Memory, Storage and Flow)**

管理执行状态和流程。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **POP** | 0x50 | 2 | value | - | 从堆栈弹出一个值 |
| **MLOAD** | 0x51 | 3 | offset | value | 从内存加载32字节到堆栈 |
| **MSTORE** | 0x52 | 3 | offset, value | - | 将32字节值存储到内存 |
| **MSTORE8** | 0x53 | 3 | offset, value | - | 将1个字节存储到内存 |
| **SLOAD** | 0x54 | 100 (热) / 2100 (冷) | key | value | 从存储加载值 |
| **SSTORE** | 0x55 | 见注释 | key, value | - | 将值存储到存储（Gas 成本复杂，取决于修改） |
| **JUMP** | 0x56 | 8 | counter | - | 跳转到程序计数器 |
| **JUMPI** | 0x57 | 10 | counter, condition | - | 条件跳转（`condition != 0` 时跳转） |
| **PC** | 0x58 | 2 | - | counter | 获取当前程序计数器 |
| **MSIZE** | 0x59 | 2 | - | size | 获取当前内存的大小（字节） |
| **GAS** | 0x5A | 2 | - | gas_remaining | 获取执行可用 Gas（在指令执行后） |
| **JUMPDEST** | 0x5B | 1 | - | - | 标记一个有效的跳转目标 |

[返回目录](#目录)

---

### **6. 推送操作 (Push Operations)**

将常量数据压入堆栈。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PUSH1** | 0x60 | 3 | - | value | 将1字节值压入堆栈 |
| **PUSH2** | 0x61 | 3 | - | value | 将2字节值压入堆栈 |
| **PUSH3** | 0x62 | 3 | - | value | 将3字节值压入堆栈 |
| **...** | ... | 3 | - | value | ... |
| **PUSH31** | 0x7E | 3 | - | value | 将31字节值压入堆栈 |
| **PUSH32** | 0x7F | 3 | - | value | 将32字节值压入堆栈 |

**说明**：PUSH系列操作码从 0x60 到 0x7F，共32个，用于将1到32字节的立即数压入堆栈。

[返回目录](#目录)

---

### **7. 复制和交换操作 (Duplication & Exchange Operations)**

管理堆栈上的值。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DUP1** | 0x80 | 3 | value1 | value1, value1 | 复制堆栈顶部值 |
| **DUP2** | 0x81 | 3 | value2, value1 | value2, value1, value2 | 复制堆栈第2个值到顶部 |
| **DUP3** | 0x82 | 3 | value3, value2, value1 | value3, value2, value1, value3 | 复制堆栈第3个值到顶部 |
| **...** | ... | 3 | ... | ... | ... |
| **DUP16** | 0x8F | 3 | value16, ..., value1 | value16, ..., value1, value16 | 复制堆栈第16个值到顶部 |
| **SWAP1** | 0x90 | 3 | value2, value1 | value1, value2 | 交换堆栈顶部和第2个值 |
| **SWAP2** | 0x91 | 3 | value3, value2, value1 | value1, value2, value3 | 交换堆栈顶部和第3个值 |
| **...** | ... | 3 | ... | ... | ... |
| **SWAP16** | 0x9F | 3 | value17, value16, ..., value1 | value1, value16, ..., value17 | 交换堆栈顶部和第17个值 |

**说明**：DUP系列复制堆栈中指定深度的值到顶部，SWAP系列交换堆栈顶部与指定深度位置的值。

[返回目录](#目录)

---

### **8. 日志记录 (Logging)**

记录事件，对应Solidity中的事件(Event)。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LOG0** | 0xA0 | 375 + 8 * 数据大小 | offset, size | - | 创建无主题的日志记录 |
| **LOG1** | 0xA1 | 375 + 375 * 1 + 8 * 数据大小 | offset, size, topic1 | - | 创建带1个主题的日志记录 |
| **LOG2** | 0xA2 | 375 + 375 * 2 + 8 * 数据大小 | offset, size, topic1, topic2 | - | 创建带2个主题的日志记录 |
| **LOG3** | 0xA3 | 375 + 375 * 3 + 8 * 数据大小 | offset, size, topic1, topic2, topic3 | - | 创建带3个主题的日志记录 |
| **LOG4** | 0xA4 | 375 + 375 * 4 + 8 * 数据大小 | offset, size, topic1, topic2, topic3, topic4 | - | 创建带4个主题的日志记录 |

**说明**：
- `offset`和`size`指定内存中日志数据的位置和大小
- 每个主题都是32字节值
- Gas成本公式：基础375 + 每个主题375 + 每字节数据8

[返回目录](#目录)

---

### **9. 系统操作 (System Operations)**

用于创建和调用其他合约，以及自毁。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **CREATE** | 0xF0 | 32000 | value, offset, size | address | 使用内存中的代码创建新合约 |
| **CREATE2** | 0xF5 | 32000 | value, offset, size, salt | address | 使用盐创建新合约（地址可预测） |
| **CALL** | 0xF1 | 复杂 | gas, addr, value, inOff, inSize, outOff, outSize | success | 向另一个合约发送消息调用 |
| **CALLCODE** | 0xF2 | 复杂 | gas, addr, value, inOff, inSize, outOff, outSize | success | 使用当前合约的上下文进行调用（已弃用） |
| **DELEGATECALL** | 0xF4 | 复杂 | gas, addr, inOff, inSize, outOff, outSize | success | 使用调用者的上下文调用目标合约 |
| **STATICCALL** | 0xFA | 复杂 | gas, addr, inOff, inSize, outOff, outSize | success | 执行静态调用（不允许修改状态） |
| **RETURN** | 0xF3 | 0 | offset, size | - | 暂停执行并返回内存中的数据 |
| **REVERT** | 0xFD | 0 | offset, size | - | 中止执行，**回滚状态**并返回错误数据 |
| **INVALID** | 0xFE | 0 | - | - | 设计为无效的操作码，会导致执行回滚 |
| **SELFDESTRUCT** | 0xFF | 5000 + 退款 | beneficiary | - | 销毁当前合约，并将其余额发送到指定地址 |

**调用操作码参数说明**：
- `gas`：分配给调用的Gas数量
- `addr`：目标合约地址
- `value`：转移的以太币数量（wei）
- `inOff`, `inSize`：输入数据在内存中的位置
- `outOff`, `outSize`：输出数据在内存中的存储位置

[返回目录](#目录)

---

**文档说明**：
- **Gas成本**为大致估算，实际成本受硬分叉影响
- **冷/热访问**：冷访问指交易中首次访问，热访问指同一交易中重复访问
- **复杂Gas**：部分操作码Gas成本依赖具体执行情况

现在这个完整文档包含了所有操作码类别，并添加了详细的目录导航。您可以直接复制这个完整版本到Word文档中。