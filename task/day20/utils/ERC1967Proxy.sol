// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.22;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

/**
 * @title ERC1967Proxy - 可升级代理合约
 * @dev 此合约实现了可升级代理。它是可升级的，因为调用被委托给一个可以更改的实现地址。
 * 此地址存储在由https://eips.ethereum.org/EIPS/eip-1967[ERC-1967]指定的存储位置中，
 * 这样它就不会与代理后面的实现的存储布局冲突。
 */
//  ERC1967：规定逻辑合约地址的存储位置，规定管理员地址的存储位置
contract ERC1967Proxy is Proxy {
    /**
     * @dev 使用`implementation`指定的初始实现初始化可升级代理
     *
     * 如果`_data`非空，它用作对`implementation`的委托调用中的数据。这通常是一个
     * 编码的函数调用，允许像Solidity构造函数一样初始化代理的存储。
     *
     * 要求：
     *
     * - 如果`data`为空，`msg.value`必须为零。
     * 
     * @param implementation 初始实现合约地址
     * @param _data 初始化数据，通常是编码的函数调用
     */
    constructor(address implementation, bytes memory _data) payable {
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }

    /**
     * @dev 返回当前实现地址
     *
     * 提示：要获取此值，客户端可以使用https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC调用
     * 直接从下面显示的存储槽（由ERC-1967指定）读取。
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     * 
     * @return 当前实现合约地址
     */
    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
