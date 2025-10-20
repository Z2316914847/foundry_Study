// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @title MutilOwner (多管理员合约)
 * @dev 基于 Mapping 实现多管理员权限控制
 * 继承自 Ownable，在单一所有者的基础上增加了多个操作员（Operator）角色
 * 
 * 权限层级：
 * - Owner（所有者）：拥有最高权限，可以添加/删除操作员
 * - Operator（操作员）：拥有部分操作权限，由所有者管理
 * 
 * 使用场景：需要多个管理员共同管理合约，但保留一个超级管理员
 */
abstract contract MutilOwner is Ownable {
    // 存储操作员地址及其状态的映射，true 表示是操作员
    mapping(address => bool) public isOperator;

    /**
     * @dev 修饰符：限制只有操作员才能调用
     * 用于需要操作员权限的函数
     */
    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");
        _;
    }

    /**
     * @dev 添加新的操作员
     * 只有合约所有者才能调用此函数
     * @param _operator 要添加为操作员的地址
     */
    function addOperator(address _operator) external onlyOwner {
        isOperator[_operator] = true;
    }

    /**
     * @dev 移除操作员权限
     * 只有合约所有者才能调用此函数
     * @param _operator 要移除操作员权限的地址
     */
    function removeOperator(address _operator) external onlyOwner {
        isOperator[_operator] = false;
    }
}

// SPDX-License-Identifier: MIT