// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";


// upGradeNFT是逻辑合约，它里面的状态变量有特殊的存储布局
contract upGradeNFTV1 is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable{
    uint256 private _nextTokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); 
    }

    // 
    function initialize(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);  // 因为逻辑合约不能
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();  // 检查执行是否通过委托调用进行。这允许函数在实现合约上可调用，但不能通过代理调用。
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // 必须覆盖此函数以授权升级
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // 可选：添加存储间隙以备未来升级
    // 存储间隙（__gap）的作用，在父合约中预留 uint256[50] private __gap，为未来升级预留存储槽。新增状态变量时，从 __gap 中占用位置，避免打乱原有布局：
    uint256[50] private __gap;
    

}

