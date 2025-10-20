// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "./Context.sol";

/**
 * @title Ownable（所有权合约）
 * @dev 提供基本的访问控制机制的合约模块，其中有一个账户（所有者）可以被授予
 * 对特定函数的独占访问权限。
 *
 * 初始所有者由部署者提供的地址设置。之后可以通过 {transferOwnership} 更改。
 *
 * 此模块通过继承使用。它将提供修饰符 `onlyOwner`，可应用于您的函数以限制只有所有者才能使用。
 * 
 * 使用场景：简单的单一管理员权限控制，适用于大多数 DApp
 */
// 基于单个角色控制访问权限
// 单个管理员模式
abstract contract Ownable is Context {
    // 存储合约所有者的地址
    address private _owner;

    /**
     * @dev 错误：调用者账户未被授权执行操作
     * @param account 尝试执行操作的账户地址
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev 错误：所有者不是有效的所有者账户（例如 address(0)）
     * @param owner 无效的所有者地址
     */
    error OwnableInvalidOwner(address owner);

    /**
     * @dev 事件：所有权转移时触发
     * @param previousOwner 之前的所有者地址
     * @param newOwner 新的所有者地址
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev 构造函数：初始化合约，设置部署者提供的地址为初始所有者
     * @param initialOwner 初始所有者的地址，不能为零地址
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev 修饰符：限制只有所有者才能调用
     * 如果由除所有者之外的任何账户调用，则抛出错误
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev 返回当前所有者的地址
     * @return address 当前所有者地址
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev 检查发送者是否为所有者
     * 如果发送者不是所有者，则抛出错误
     * 内部函数，供 onlyOwner 修饰符使用
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev 放弃合约所有权，使合约没有所有者
     * 这将使无法再调用 `onlyOwner` 函数。只能由当前所有者调用。
     *
     * 注意：放弃所有权将使合约没有所有者，从而禁用仅所有者可用的任何功能。
     * 使用场景：合约完全去中心化，不再需要管理员
     * 警告：此操作不可逆！
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev 将合约所有权转移到新账户
     * 只能由当前所有者调用
     * @param newOwner 新所有者的地址，不能为零地址
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev 内部函数：将合约所有权转移到新账户
     * 没有访问限制，供内部使用
     * @param newOwner 新所有者的地址
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
