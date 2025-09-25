// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
// import "./utils/ERC721Upgradeable.sol";
// import "./utils/OwnableUpgradeable.sol";
// import "./utils/Initializable.sol";
// import "./utils/UUPSUpgradeable.sol";


// upGradeNFTV1是逻辑合约，它里面的状态变量有特殊的存储布局
// UUPSUpgradeable 让 upGradeNFTV1 具有一个方法，这个方法可以升级逻辑合约地址
contract upGradeNFTV1 is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable{
    uint256 private _nextTokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();  // 禁用逻辑合约的初始化，这样后面 代理合约 才能调用 逻辑合约initialize函数，来完成逻辑合约初始化
        // 为什么逻辑合约中不完成初始化：因为，逻辑合约初始化后，会有自己的 存储布局，然后存储槽就会有 数据。
        //   后面逻辑合约调用initialize函数时，代理合约中的存储槽也会有数据，这样两个存储槽变冲突了。
        // 所以 禁止 逻辑合约自己初始化。假如逻辑合约初始化后，那代理合约就不能 初始化 逻辑合约。
    }

    // 初始化
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

