// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleMultiSig（简单多签钱包合约）
 * @dev 实现多重签名钱包的基本功能
 * 对于最高权限的操作，要求多个地址中的一定数量同意才能执行。
 * 
 * 核心概念：
 * - M-of-N 多签：需要 N 个所有者中的至少 M 个批准才能执行交易
 * - 交易提交-批准-执行流程：提高安全性，防止单点故障
 * 
 * 使用场景：
 * - DAO 治理：重要决策需要多人同意
 * - 资金管理：大额转账需要多个签名
 * - 合约升级：关键操作需要多方确认
 */
contract SimpleMultiSig {
    // 存储所有所有者地址的数组
    address[] public owners;
    
    // 执行交易所需的最少批准数量（M-of-N 中的 M）
    uint256 public required;
    
    // 双重映射：交易ID => 所有者地址 => 是否已批准
    // 用于跟踪每个交易的批准状态
    mapping(uint256 => mapping(address => bool)) public approvals;

    /**
     * @dev 交易结构体，存储待执行的交易信息
     * @param to 交易接收方地址
     * @param value 转账金额（wei）
     * @param data 交易数据（函数调用编码）
     * @param executed 交易是否已执行
     */
    struct Transaction {
        address to;        // 目标合约地址
        uint256 value;     // 发送的以太币数量
        bytes data;        // 调用数据（函数选择器 + 参数）
        bool executed;     // 防止重复执行
    }
    
    // 存储所有待处理和已执行的交易
    Transaction[] public transactions;

    /**
     * @dev 提交新的交易提案
     * 任何所有者都可以提交交易，但需要足够的批准才能执行
     * @param to 交易目标地址
     * @param value 发送的以太币数量
     * @param data 交易数据（calldata）
     * @return uint256 交易ID（在 transactions 数组中的索引）
     */
    function submitTransaction(address to, uint256 value, bytes calldata data) external onlyOwner returns (uint256) {
        // 实现：创建新交易，返回交易ID
        // ...
    }

    /**
     * @dev 批准指定的交易
     * 每个所有者只能批准一次
     * @param txId 要批准的交易ID
     */
    function approveTransaction(uint256 txId) external onlyOwner {
        // 实现：记录批准，防止重复批准
        // ...
    }

    /**
     * @dev 执行已获得足够批准的交易
     * 检查是否有足够多的所有者批准
     * @param txId 要执行的交易ID
     */
    function executeTransaction(uint256 txId) external onlyOwner {
        // 检查是否有足够多的所有者批准（>= required）
        // 检查交易是否已执行
        // 执行交易：调用目标地址
        // ...
    }
}