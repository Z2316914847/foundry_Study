// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.22;

import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "./Initializable.sol";

/**
 * @title UUPSUpgradeable - UUPS代理升级机制
 * @dev 为UUPS代理设计的可升级机制。当此合约设置为代理后面的实现时，
 * 这里包含的函数可以执行{ERC1967Proxy}的升级。
 *
 * 安全机制确保升级不会意外关闭可升级性，但如果升级保留可升级性但移除安全机制，
 * 例如通过用自定义升级实现替换`UUPSUpgradeable`，这种风险会重新出现。
 *
 * 必须重写{_authorizeUpgrade}函数以包含对升级机制的访问限制。
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev 合约升级接口的版本。如果此getter缺失，则`upgradeTo(address)`和`upgradeToAndCall(address,bytes)`都存在，
     * 如果不应该调用函数，则必须使用`upgradeTo`，而如果第二个参数是空字节字符串，`upgradeToAndCall`将调用`receive`函数。
     * 如果getter返回`"5.0.0"`，则只有`upgradeToAndCall(address,bytes)`存在，如果不应该调用函数，
     * 第二个参数必须是空字节字符串，这使得在升级期间无法调用`receive`函数。
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev 调用来自未授权上下文的错误
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev 存储`slot`作为UUID不受支持的错误
     * @param slot 不支持的存储槽
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev 检查执行是否通过delegatecall调用进行，以及执行上下文是否是指向自身的具有实现（如ERC-1967中定义）的代理合约。
     * 这应该只适用于使用当前合约作为其实现的UUPS和透明代理。通过ERC-1167最小代理（克隆）执行函数通常不会通过此测试，
     * 但不保证会失败。
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev 检查执行不是通过委托调用进行的。这允许函数在实现合约上可调用，但不能通过代理调用。
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    /**
     * @dev UUPSUpgradeable初始化函数
     */
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    /**
     * @dev UUPSUpgradeable无链式初始化函数
     */
    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    
    /**
     * @dev ERC-1822 {proxiableUUID}函数的实现。返回实现使用的存储槽。
     * 用于在执行升级时验证实现的兼容性。
     *
     * 重要：指向可代理合约的代理本身不应被视为可代理的，因为这有风险
     * 通过委托给自己直到gas耗尽来破坏升级到它的代理。因此，如果通过代理调用此函数，
     * 此函数回退是至关重要的。这由`notDelegated`修饰符保证。
     * 
     * @return 实现使用的存储槽
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev 将代理的实现升级为`newImplementation`，然后执行编码在`data`中的函数调用
     *
     * 调用{_authorizeUpgrade}
     *
     * 发出{Upgraded}事件
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     * 
     * @param newImplementation 新的实现合约地址
     * @param data 要执行的函数调用数据
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev 如果执行不是通过delegatecall进行的，或者执行上下文不是指向自身的具有ERC-1967兼容实现的代理，则回退
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // 必须通过delegatecall调用
            ERC1967Utils.getImplementation() != __self // 必须通过活动代理调用
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev 如果执行是通过delegatecall进行的则回退
     * 参见{notDelegated}
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // 不能通过delegatecall调用
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev 当`msg.sender`未被授权升级合约时应回退的函数。由{upgradeToAndCall}调用
     *
     * 通常，此函数将使用xref:access.adoc[访问控制]修饰符，如{Ownable-onlyOwner}
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     * 
     * @param newImplementation 新的实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev 为UUPS代理执行带有安全检查的实现升级和额外的设置调用
     *
     * 作为安全检查，在新实现中调用{proxiableUUID}，期望返回值是ERC-1967中的实现槽
     *
     * 发出{IERC1967-Upgraded}事件
     * 
     * @param newImplementation 新的实现合约地址
     * @param data 设置调用数据
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // 实现不是UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}
