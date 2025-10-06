好的，这是一份详细的 EVM 操作码中文解释文档。它按功能类别组织，涵盖了在以太坊黄皮书或常见客户端中定义的核心操作码。

---

### **EVM 操作码中文文档**

**文档说明**：
- **Gas** 列为大致估算，实际成本可能因硬分叉升级（如柏林、伦敦）而变动。
- **堆栈** 列使用简写：`value` 表示任意值，`offset` 表示内存偏移，`key` 和 `value` 表示存储键值。
- 操作码后的数字（如 `PUSH1`）表示操作码携带的字节数。

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

---

### **3. 密码学操作 (Cryptographic)**

执行哈希和地址派生。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SHA3** | 0x20 | 30 + 6 * 数据大小 | offset, size | keccak256(mem[offset:offset+size]) | 计算内存中数据的 Keccak-256 哈希 |
| **ADDRESS** | 0x30 | 2 | - | address | 获取当前执行合约的地址 |
| **BALANCE** | 0x31 | 100 (冷) / 2600 (冷) | address | balance | 获取指定地址的以太币余额（单位：wei） |
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

---

### **6. 推送操作 (Push Operations)**

将常量数据压入堆栈。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PUSH1 ... PUSH32** | 0x60 ... 0x7F | 3 | - | value | 将 1 到 32 字节的值压入堆栈 |

---

### **7. 复制和交换操作 (Duplication & Exchange Operations)**

管理堆栈上的值。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DUP1 ... DUP16** | 0x80 ... 0x8F | 3 | valueN, ..., value1 | valueN, ..., value1, valueN | 复制堆栈上第 1 到第 16 个值 |
| **SWAP1 ... SWAP16** | 0x90 ... 0x9F | 3 | valueN, ..., value1 | value1, ..., valueN | 交换堆栈顶部和第 2 到第 17 个值 |

---

### **8. 日志记录 (Logging)**

记录事件。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LOG0 ... LOG4** | 0xA0 ... 0xA4 | 375 + 375 * 主题数 + 8 * 数据大小 | offset, size, topic1, ... | - | 创建日志记录，包含 0 到 4 个主题和数据 |

---

### **9. 系统操作 (System Operations)**

用于创建和调用其他合约，以及自毁。

| 助记符 | 操作码 | Gas | 输入 | 输出 | 中文解释 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **CREATE** | 0xF0 | 32000 | value, offset, size | address | 使用内存中的代码创建新合约 |
| **CREATE2** | 0xF5 | 32000 | value, offset, size, salt | address | 使用盐创建新合约（地址可预测） |
| **CALL** | 0xF1 | 见注释 | gas, addr, value, inOff, inSize, outOff, outSize | success | 向另一个合约发送消息调用 |
| **CALLCODE** | 0xF2 | 见注释 | gas, addr, value, inOff, inSize, outOff, outSize | success | 使用当前合约的上下文进行调用（已弃用） |
| **DELEGATECALL** | 0xF4 | 见注释 | gas, addr, inOff, inSize, outOff, outSize | success | 使用调用者的上下文调用目标合约 |
| **STATICCALL** | 0xFA | 见注释 | gas, addr, inOff, inSize, outOff, outSize | success | 执行静态调用（不允许修改状态） |
| **RETURN** | 0xF3 | 0 | offset, size | - | 暂停执行并返回内存中的数据 |
| **REVERT** | 0xFD | 0 | offset, size | - | 中止执行，**回滚状态**并返回错误数据 |
| **INVALID** | 0xFE | 0 | - | - | 设计为无效的操作码，会导致执行回滚 |
| **SELFDESTRUCT**/SUICIDE | 0xFF | 5000 + 退款 | beneficiary | - | 销毁当前合约，并将其余额发送到指定地址 |

---

**重要提示**：
- **Gas 成本**：此文档中的 Gas 成本为大致估算，尤其是对于 `SSTORE`, `CALL`, `BALANCE` 等，实际成本受 EIP-2929（冷热访问）和 EIP-3529（退款减少）等影响，会动态变化。请务必参考最新的以太坊文档。
- **堆栈效应**：输入和输出列描述了操作码对堆栈的影响，从左到右是堆栈顶部的顺序。

这份文档可以作为理解和分析 EVM 字节码的快速参考指南。