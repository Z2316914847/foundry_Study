// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title OwnableUpgradeable - 可升级的所有权控制模块
 * @dev 提供基本访问控制机制的合约模块，其中有一个账户（所有者）可以被授予对特定函数的独占访问权限
 *
 * 初始所有者设置为部署者提供的地址。之后可以使用{transferOwnership}更改。
 *
 * 此模块通过继承使用。它将提供修饰符`onlyOwner`，可以应用于您的函数以将其使用限制为所有者。
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    /// @dev Ownable存储结构 - 遵循ERC7201标准避免存储冲突
    struct OwnableStorage {
        /// @dev 合约所有者地址
        address _owner;
    }

    /// @dev ERC7201存储位置常量 - 通过哈希计算确定的唯一存储槽
    /// 这个位置是通过keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))计算得出
    /// 确保在代理升级过程中存储位置不会冲突
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    /// @dev 获取Ownable存储结构的私有函数
    /// @return $ 返回指向OwnableStorage结构体的存储引用
    /// 使用内联汇编直接访问指定存储槽，避免存储冲突
    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev 调用者账户未被授权执行操作
     * @param account 未授权的账户地址
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev 所有者不是有效的所有者账户（例如`address(0)`）
     * @param owner 无效的所有者地址
     */
    error OwnableInvalidOwner(address owner);

    /// @dev 所有权转移事件
    /// @param previousOwner 前一个所有者地址
    /// @param newOwner 新的所有者地址
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev 初始化合约，将部署者提供的地址设置为初始所有者
     * @param initialOwner 初始所有者地址
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    /**
     * @dev 无链式初始化的Ownable初始化函数
     * @param initialOwner 初始所有者地址
     * 如果初始所有者为零地址，会抛出OwnableInvalidOwner错误
     */
    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev 如果由所有者以外的任何账户调用则抛出异常
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev 返回当前所有者的地址
     * @return 当前所有者地址
     */
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev 如果发送者不是所有者则抛出异常
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev 放弃合约所有权。将无法调用`onlyOwner`函数。只能由当前所有者调用。
     *
     * 注意：放弃所有权将使合约没有所有者，从而禁用仅对所有者可用的任何功能。
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev 将合约所有权转移给新账户（`newOwner`）
     * 只能由当前所有者调用
     * @param newOwner 新的所有者地址
     * 如果新所有者为零地址，会抛出OwnableInvalidOwner错误
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev 将合约所有权转移给新账户（`newOwner`）
     * 无访问限制的内部函数
     * @param newOwner 新的所有者地址
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
