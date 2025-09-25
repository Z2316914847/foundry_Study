// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.22;

import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @title ERC1967Utils - ERC-1967代理存储槽工具库
 * @dev 此库为https://eips.ethereum.org/EIPS/eip-1967[ERC-1967]存储槽提供获取器和事件发出更新函数
 * 
 * ERC-1967标准定义了代理合约的存储槽布局，包括：
 * - 实现地址存储槽
 * - 管理员地址存储槽  
 * - 信标地址存储槽
 * 
 * 此库提供了对这些存储槽的安全访问和更新功能
 */
library ERC1967Utils {
    /**
     * @dev 存储当前实现地址的存储槽
     * 这是"eip1967.proxy.implementation"的keccak-256哈希值减去1
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev 代理的`implementation`无效错误
     * @param implementation 无效的实现地址
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev 代理的`admin`无效错误
     * @param admin 无效的管理员地址
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev 代理的`beacon`无效错误
     * @param beacon 无效的信标地址
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev 升级函数看到`msg.value > 0`可能丢失的错误
     * 当升级函数收到ETH但无法处理时抛出
     */
    error ERC1967NonPayable();

    /**
     * @dev 返回当前实现地址
     * @return 当前实现合约地址
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev 在ERC-1967实现槽中存储新地址
     * @param newImplementation 新的实现合约地址
     * 如果新实现地址没有代码，会抛出ERC1967InvalidImplementation错误
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev 执行实现升级，如果数据非空则进行额外的设置调用
     * 只有在执行设置调用时此函数才可支付，否则拒绝`msg.value`以避免资金卡在合约中
     *
     * 发出{IERC1967-Upgraded}事件
     * 
     * @param newImplementation 新的实现合约地址
     * @param data 设置调用数据，如果为空则不执行设置调用
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit IERC1967.Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev 存储合约管理员的存储槽
     * 这是"eip1967.proxy.admin"的keccak-256哈希值减去1
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev 返回当前管理员地址
     *
     * 提示：要获取此值，客户端可以使用https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC调用
     * 直接从下面显示的存储槽（由ERC-1967指定）读取。
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     * 
     * @return 当前管理员地址
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev 在ERC-1967管理员槽中存储新地址
     * @param newAdmin 新的管理员地址
     * 如果新管理员地址为零地址，会抛出ERC1967InvalidAdmin错误
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev 更改代理的管理员
     *
     * 发出{IERC1967-AdminChanged}事件
     * 
     * @param newAdmin 新的管理员地址
     */
    function changeAdmin(address newAdmin) internal {
        emit IERC1967.AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev UpgradeableBeacon合约的存储槽，它定义此代理的实现
     * 这是"eip1967.proxy.beacon"的keccak-256哈希值减去1
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev 返回当前信标地址
     * @return 当前信标合约地址
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev 在ERC-1967信标槽中存储新信标
     * @param newBeacon 新的信标合约地址
     * 如果新信标地址没有代码或其实现没有代码，会抛出相应错误
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev 更改信标并在数据非空时触发设置调用
     * 只有在执行设置调用时此函数才可支付，否则拒绝`msg.value`以避免资金卡在合约中
     *
     * 发出{IERC1967-BeaconUpgraded}事件
     *
     * 注意：自v5以来，调用此函数对{BeaconProxy}实例没有影响，因为
     * 它使用不可变信标，为了提高效率而不查看ERC-1967信标槽的值
     * 
     * @param newBeacon 新的信标合约地址
     * @param data 设置调用数据，如果为空则不执行设置调用
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit IERC1967.BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev 如果`msg.value`不为零则回退。如果升级不执行初始化调用，
     * 可用于避免`msg.value`卡在合约中
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}
