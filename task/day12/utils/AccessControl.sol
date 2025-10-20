// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "../../../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {Context} from "../../../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {ERC165} from "../../../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

/**
 * @dev 合约模块，允许子合约实现基于角色的访问控制机制。
 * 这是一个轻量级版本，不允许枚举角色成员，除非通过链外方式访问合约事件日志。
 * 某些应用程序可能受益于链上可枚举性，对于这些情况，请参见 {AccessControlEnumerable}。
 *
 * 角色通过其 `bytes32` 标识符引用。这些应该在外部 API 中公开并且是唯一的。
 * 实现这一点的最佳方法是使用 `public constant` 哈希摘要：
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * 角色可用于表示一组权限。要限制对函数调用的访问，请使用 {hasRole}：
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * 角色可以通过 {grantRole} 和 {revokeRole} 函数动态授予和撤销。
 * 每个角色都有一个关联的管理员角色，只有拥有角色管理员角色的账户才能调用 {grantRole} 和 {revokeRole}。
 *
 * 默认情况下，所有角色的管理员角色是 `DEFAULT_ADMIN_ROLE`，这意味着只有拥有此角色的账户
 * 才能授予或撤销其他角色。可以通过使用 {_setRoleAdmin} 创建更复杂的角色关系。
 *
 * 警告：`DEFAULT_ADMIN_ROLE` 也是其自身的管理员：它有权限授予和撤销此角色。
 * 应采取额外的预防措施来保护已被授予该角色的账户。
 * 我们建议使用 {AccessControlDefaultAdminRules} 来为此角色实施额外的安全措施。
 */
// 基于多角色控制访问权限的抽象合约
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    /**
     * @dev 角色数据结构
     * @param hasRole 账户地址到角色拥有状态的映射
     * @param adminRole 该角色的管理员角色标识符
     */
    struct RoleData {
        mapping(address account => bool) hasRole; // 存储哪些地址拥有该角色
        bytes32 adminRole; // 该角色的管理员角色
    }

    // 角色标识符到角色数据的映射，存储所有角色的信息
    mapping(bytes32 role => RoleData) private _roles;

    // 默认管理员角色标识符，值为 0x00，作为所有角色的默认管理员
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev 修饰符，检查账户是否拥有特定角色
     * 如果调用者没有所需角色，将回滚并抛出 {AccessControlUnauthorizedAccount} 错误
     * @param role 需要检查的角色标识符
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role); // 检查调用者是否拥有角色
        _; // 继续执行函数体
    }

    /**
     * @dev 检查合约是否支持特定的接口（ERC165标准）
     * @param interfaceId 要检查的接口标识符
     * @return bool 如果支持该接口返回 true，否则返回 false
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev 查询账户是否拥有指定角色
     * @param role 角色标识符
     * @param account 要查询的账户地址
     * @return bool 如果账户拥有该角色返回 true，否则返回 false
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev 检查消息发送者是否拥有指定角色
     * 如果 _msgSender() 缺少该角色，则回滚并抛出 {AccessControlUnauthorizedAccount} 错误
     * 重写此函数会改变 {onlyRole} 修饰符的行为
     * @param role 要检查的角色标识符
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev 检查指定账户是否拥有指定角色
     * 如果账户缺少该角色，则回滚并抛出 {AccessControlUnauthorizedAccount} 错误
     * @param role 要检查的角色标识符
     * @param account 要检查的账户地址
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev 返回控制指定角色的管理员角色
     * 管理员角色可以授予和撤销该角色。参见 {grantRole} 和 {revokeRole}。
     * 要更改角色的管理员，请使用 {_setRoleAdmin}。
     * @param role 要查询的角色标识符
     * @return bytes32 管理该角色的管理员角色标识符
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev 授予账户指定角色
     * 如果账户之前没有被授予该角色，则触发 {RoleGranted} 事件
     * 
     * 要求：
     * - 调用者必须拥有该角色的管理员角色
     * 
     * 可能触发 {RoleGranted} 事件
     * @param role 要授予的角色标识符
     * @param account 要授予角色的账户地址
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev 从账户撤销指定角色
     * 如果账户之前拥有该角色，则触发 {RoleRevoked} 事件
     * 
     * 要求：
     * - 调用者必须拥有该角色的管理员角色
     * 
     * 可能触发 {RoleRevoked} 事件
     * @param role 要撤销的角色标识符
     * @param account 要撤销角色的账户地址
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev 从调用账户放弃指定角色
     * 角色通常通过 {grantRole} 和 {revokeRole} 管理：此函数的目的是为账户提供一种机制，
     * 在账户被攻破时（例如受信任的设备丢失时）失去其权限。
     * 
     * 如果调用账户已被撤销该角色，则触发 {RoleRevoked} 事件
     * 
     * 要求：
     * - 调用者必须是 `callerConfirmation`（防止误操作）
     * 
     * 可能触发 {RoleRevoked} 事件
     * @param role 要放弃的角色标识符
     * @param callerConfirmation 调用者地址的确认，必须与 msg.sender 相同
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev 设置指定角色的管理员角色
     * 内部函数，用于修改角色的管理员
     * 
     * 触发 {RoleAdminChanged} 事件
     * @param role 要设置管理员的角色标识符
     * @param adminRole 新的管理员角色标识符
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev 尝试授予账户指定角色，并返回布尔值指示角色是否已授予
     * 内部函数，没有访问限制
     * 
     * 可能触发 {RoleGranted} 事件
     * @param role 要授予的角色标识符
     * @param account 要授予角色的账户地址
     * @return bool 如果角色被成功授予返回 true，如果账户已经拥有该角色返回 false
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev 尝试从账户撤销指定角色，并返回布尔值指示角色是否已撤销
     * 内部函数，没有访问限制
     * 
     * 可能触发 {RoleRevoked} 事件
     * @param role 要撤销的角色标识符
     * @param account 要撤销角色的账户地址
     * @return bool 如果角色被成功撤销返回 true，如果账户本来就没有该角色返回 false
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}
