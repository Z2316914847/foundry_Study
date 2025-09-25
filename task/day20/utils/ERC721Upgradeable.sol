// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ERC721Utils} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Utils.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ERC721Upgradeable - 可升级的ERC721代币标准实现
 * @dev 这是OpenZeppelin的ERC721可升级版本，实现了https://eips.ethereum.org/EIPS/eip-721[ERC-721] NFT代币标准
 * 
 * 主要特性：
 * - 包含元数据扩展功能
 * - 支持代币升级（通过代理模式）
 * - 使用结构化存储避免存储冲突
 * - 实现了所有ERC721标准函数：mint、burn、transfer、approve等
 * 
 * 注意：此合约不包含Enumerable扩展，如需枚举功能请使用{ERC721Enumerable}
 * 
 * 存储结构：
 * - 使用ERC7201命名空间避免存储冲突
 * - 所有状态变量都存储在ERC721Storage结构体中
 * - 通过_getERC721Storage()函数访问存储
 */
abstract contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    /// @custom:storage-location erc7201:openzeppelin.storage.ERC721
    /// @dev ERC721存储结构 - 遵循ERC7201标准避免存储冲突
    struct ERC721Storage {
        /// @dev 代币名称 - 用于标识NFT集合的名称
        string _name;

        /// @dev 代币符号 - 用于标识NFT集合的简称
        string _symbol;

        /// @dev 代币所有权映射 - tokenId => owner地址
        /// 记录每个代币ID对应的所有者地址
        mapping(uint256 tokenId => address) _owners;

        /// @dev 余额映射 - owner地址 => 拥有代币数量
        /// 记录每个地址拥有的代币总数
        mapping(address owner => uint256) _balances;

        /// @dev 代币授权映射 - tokenId => 被授权地址
        /// 记录每个代币ID被授权给哪个地址操作
        mapping(uint256 tokenId => address) _tokenApprovals;

        /// @dev 操作员授权映射 - owner => operator => 是否授权
        /// 记录所有者是否授权某个地址管理其所有代币
        mapping(address owner => mapping(address operator => bool)) _operatorApprovals;
    }

    /// @dev ERC7201存储位置常量 - 通过哈希计算确定的唯一存储槽
    /// 这个位置是通过keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC721")) - 1)) & ~bytes32(uint256(0xff))计算得出
    /// 确保在代理升级过程中存储位置不会冲突
    bytes32 private constant ERC721StorageLocation = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;

    /// @dev 获取ERC721存储结构的私有函数
    /// @return $ 返回指向ERC721Storage结构体的存储引用
    /// 使用内联汇编直接访问指定存储槽，避免存储冲突
    function _getERC721Storage() private pure returns (ERC721Storage storage $) {
        assembly {
            $.slot := ERC721StorageLocation
        }
    }

    /**
     * @dev 初始化ERC721合约 - 设置代币名称和符号
     * @param name_ 代币集合的名称
     * @param symbol_ 代币集合的符号
     * 
     * 注意：此函数只能在初始化期间调用，由onlyInitializing修饰符保护
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    /**
     * @dev 无链式初始化的ERC721初始化函数
     * @param name_ 代币集合的名称
     * @param symbol_ 代币集合的符号
     * 
     * 直接设置存储中的名称和符号，不调用其他初始化函数
     * 用于避免在复杂继承结构中重复初始化
     */
    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC721Storage storage $ = _getERC721Storage();
        $._name = name_;
        $._symbol = symbol_;
    }

    /// @inheritdoc IERC165
    /// @dev 检查合约是否支持指定的接口
    /// @param interfaceId 要检查的接口ID
    /// @return 如果支持该接口则返回true，否则返回false
    /// 
    /// 支持的接口：
    /// - IERC721: 基础ERC721接口
    /// - IERC721Metadata: ERC721元数据扩展接口
    /// - 其他通过父合约支持的接口
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC721
    /// @dev 查询指定地址拥有的代币数量
    /// @param owner 要查询的地址
    /// @return 该地址拥有的代币数量
    /// 如果owner为零地址，会抛出ERC721InvalidOwner错误
    function balanceOf(address owner) public view virtual returns (uint256) {
        ERC721Storage storage $ = _getERC721Storage();
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return $._balances[owner];
    }

    /// @inheritdoc IERC721
    /// @dev 查询指定代币ID的所有者
    /// @param tokenId 要查询的代币ID
    /// @return 该代币的所有者地址
    /// 如果代币不存在，会抛出ERC721NonexistentToken错误
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /// @inheritdoc IERC721Metadata
    /// @dev 返回代币集合的名称
    /// @return 代币集合的名称
    function name() public view virtual returns (string memory) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._name;
    }

    /// @inheritdoc IERC721Metadata
    /// @dev 返回代币集合的符号
    /// @return 代币集合的符号
    function symbol() public view virtual returns (string memory) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._symbol;
    }

    /// @inheritdoc IERC721Metadata
    /// @dev 返回指定代币的URI
    /// @param tokenId 代币ID
    /// @return 代币的URI字符串
    /// 如果代币不存在，会抛出ERC721NonexistentToken错误
    /// URI格式：如果baseURI存在，则为baseURI + tokenId，否则返回空字符串
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @dev 用于计算{tokenURI}的基础URI
     * 
     * 如果设置了baseURI，每个代币的URI将是`baseURI`和`tokenId`的连接
     * 默认为空字符串，可以在子合约中重写
     * 
     * @return 基础URI字符串
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /// @inheritdoc IERC721
    /// @dev 授权指定地址操作指定代币
    /// @param to 被授权的地址
    /// @param tokenId 要授权的代币ID
    /// 只有代币所有者或已授权的操作员可以调用此函数
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /// @inheritdoc IERC721
    /// @dev 查询指定代币的授权地址
    /// @param tokenId 代币ID
    /// @return 被授权操作该代币的地址，如果没有授权则返回零地址
    /// 如果代币不存在，会抛出ERC721NonexistentToken错误
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /// @inheritdoc IERC721
    /// @dev 设置操作员权限，允许或禁止指定地址操作调用者的所有代币
    /// @param operator 要设置权限的地址
    /// @param approved true表示授权，false表示撤销授权
    /// 发出ApprovalForAll事件
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @inheritdoc IERC721
    /// @dev 查询指定操作员是否被授权操作所有者的所有代币
    /// @param owner 代币所有者地址
    /// @param operator 操作员地址
    /// @return 如果operator被授权操作owner的所有代币则返回true，否则返回false
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._operatorApprovals[owner][operator];
    }

    /// @inheritdoc IERC721
    /// @dev 转移指定代币的所有权
    /// @param from 发送方地址
    /// @param to 接收方地址
    /// @param tokenId 要转移的代币ID
    /// 
    /// 要求：
    /// - 调用者必须是代币所有者或已授权的操作员
    /// - 代币必须存在且属于from地址
    /// - to地址不能为零地址
    /// 
    /// 发出Transfer事件
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // 设置"auth"参数启用`_isAuthorized`检查，验证代币存在(from != 0)
        // 因此这里不需要验证返回值不为0
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /// @inheritdoc IERC721
    /// @dev 安全转移代币（不包含额外数据）
    /// @param from 发送方地址
    /// @param to 接收方地址
    /// @param tokenId 要转移的代币ID
    /// 
    /// 这是一个便捷函数，调用safeTransferFrom(from, to, tokenId, "")
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @inheritdoc IERC721
    /// @dev 安全转移代币（包含额外数据）
    /// @param from 发送方地址
    /// @param to 接收方地址
    /// @param tokenId 要转移的代币ID
    /// @param data 额外的数据，会传递给接收方合约
    /// 
    /// 如果to是合约地址，会检查其是否实现了ERC721Receiver接口
    /// 发出Transfer事件
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
    }

    /**
     * @dev 返回`tokenId`的所有者。如果代币不存在，不会回退
     *
     * 重要：任何重写此函数以添加未被核心ERC-721逻辑跟踪的代币所有权的操作，
     * 都必须配合使用{_increaseBalance}来保持余额与所有权的一致性。
     * 要维护的不变量是：对于任何地址`a`，`balanceOf(a)`返回的值必须等于
     * `_ownerOf(tokenId)`为`a`的代币数量。
     * 
     * @param tokenId 代币ID
     * @return 代币所有者地址，如果代币不存在则返回零地址
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._owners[tokenId];
    }

    /**
     * @dev 返回`tokenId`的授权地址。如果`tokenId`未铸造则返回0
     * @param tokenId 代币ID
     * @return 被授权操作该代币的地址，如果没有授权则返回零地址
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._tokenApprovals[tokenId];
    }

    /**
     * @dev 返回`spender`是否被允许管理`owner`的代币，特别是`tokenId`
     * （忽略`tokenId`是否真的属于`owner`）
     *
     * 警告：此函数假设`owner`是`tokenId`的实际所有者，不验证此假设
     * 
     * @param owner 代币所有者地址
     * @param spender 操作者地址
     * @param tokenId 代币ID
     * @return 如果spender被授权则返回true，否则返回false
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev 检查`spender`是否可以操作`tokenId`，假设提供的`owner`是实际所有者
     * 
     * 如果以下情况会回退：
     * - `spender`没有从`owner`获得`tokenId`的授权
     * - `spender`没有管理`owner`所有资产的授权
     *
     * 警告：此函数假设`owner`是`tokenId`的实际所有者，不验证此假设
     * 
     * @param owner 代币所有者地址
     * @param spender 操作者地址
     * @param tokenId 代币ID
     * 如果代币不存在，会抛出ERC721NonexistentToken错误
     * 如果授权不足，会抛出ERC721InsufficientApproval错误
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev 对余额的不安全写访问，用于通过重写{ownerOf}来"铸造"代币的扩展
     *
     * 注意：值限制为type(uint128).max。这防止了_balance溢出。当这些增量被限制为uint128值时，
     * uint256从增量中溢出的情况是不现实的。
     *
     * 警告：使用此函数增加账户余额通常需要配合重写{_ownerOf}函数来解析相应代币的所有权，
     * 以便余额和所有权保持一致。
     * 
     * @param account 要增加余额的账户地址
     * @param value 要增加的余额值
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        unchecked {
            $._balances[account] += value;
        }
    }

    /**
     * @dev 将`tokenId`从其当前所有者转移到`to`，或者如果当前所有者（或`to`）是零地址则铸造（或销毁）
     * 返回更新前`tokenId`的所有者。
     *
     * `auth`参数是可选的。如果传递的值不为0，则此函数将检查`auth`是代币的所有者，
     * 还是被所有者授权操作代币的地址。
     *
     * 发出{Transfer}事件。
     *
     * 注意：如果以跟踪余额的方式重写此函数，请参见{_increaseBalance}。
     * 
     * @param to 接收方地址（零地址表示销毁）
     * @param tokenId 代币ID
     * @param auth 授权地址（零地址表示跳过授权检查）
     * @return 更新前的代币所有者地址
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        address from = _ownerOf(tokenId);

        // 执行（可选的）操作员检查
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // 执行更新
        if (from != address(0)) {
            // 清除授权。无需重新授权或发出Approval事件
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                $._balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                $._balances[to] += 1;
            }
        }

        $._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev 铸造指定ID的代币并转移给指定地址
     * 
     * 警告：不推荐使用此方法，建议使用{_safeMint}以确保安全
     *
     * 要求：
     * - `tokenId` 必须不存在
     * - `to` 不能是零地址
     *
     * 发出 {Transfer} 事件
     * 
     * @param to 代币接收者地址
     * @param tokenId 要铸造的代币ID
     * 如果to为零地址，会抛出ERC721InvalidReceiver错误
     * 如果代币已存在，会抛出ERC721InvalidSender错误
     */
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev 铸造`tokenId`，转移给`to`并检查`to`的接受性
     *
     * 要求：
     *
     * - `tokenId` 必须不存在
     * - 如果`to`是智能合约，它必须实现{IERC721Receiver-onERC721Received}，在安全转移时被调用
     *
     * 发出{Transfer}事件
     * 
     * @param to 代币接收者地址
     * @param tokenId 要铸造的代币ID
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev 与{_safeMint}相同，但包含额外的`data`参数，该参数会在{IERC721Receiver-onERC721Received}中
     * 转发给合约接收方
     * 
     * @param to 代币接收者地址
     * @param tokenId 要铸造的代币ID
     * @param data 额外的数据，会传递给接收方合约
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        ERC721Utils.checkOnERC721Received(_msgSender(), address(0), to, tokenId, data);
    }

    /**
     * @dev 销毁指定的代币
     * 
     * 当代币被销毁时，其授权会被清除
     * 这是一个内部函数，不检查发送者是否有权操作该代币
     *
     * 要求：
     * - `tokenId` 必须存在
     *
     * 发出 {Transfer} 事件
     * 
     * @param tokenId 要销毁的代币ID
     * 如果代币不存在，会抛出ERC721NonexistentToken错误
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @dev 将`tokenId`从`from`转移到`to`
     * 与{transferFrom}不同，此函数不对msg.sender施加任何限制
     *
     * 要求：
     *
     * - `to` 不能是零地址
     * - `tokenId` 代币必须属于`from`
     *
     * 发出{Transfer}事件
     * 
     * @param from 发送方地址
     * @param to 接收方地址
     * @param tokenId 要转移的代币ID
     * 如果to为零地址，会抛出ERC721InvalidReceiver错误
     * 如果代币不存在，会抛出ERC721NonexistentToken错误
     * 如果代币不属于from，会抛出ERC721IncorrectOwner错误
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev 安全地将`tokenId`代币从`from`转移到`to`，检查合约接收方是否了解ERC-721标准，
     * 以防止代币被永久锁定
     *
     * `data`是额外数据，没有指定格式，会在调用`to`时发送
     *
     * 这个内部函数类似于{safeTransferFrom}，它会在接收方调用{IERC721Receiver-onERC721Received}，
     * 可用于实现替代的代币转移机制，例如基于签名的转移
     *
     * 要求：
     *
     * - `tokenId` 代币必须存在且属于`from`
     * - `to` 不能是零地址
     * - `from` 不能是零地址
     * - 如果`to`是智能合约，它必须实现{IERC721Receiver-onERC721Received}，在安全转移时被调用
     *
     * 发出{Transfer}事件
     * 
     * @param from 发送方地址
     * @param to 接收方地址
     * @param tokenId 要转移的代币ID
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev 与{_safeTransfer}相同，但包含额外的`data`参数，该参数会在{IERC721Receiver-onERC721Received}中
     * 转发给合约接收方
     * 
     * @param from 发送方地址
     * @param to 接收方地址
     * @param tokenId 要转移的代币ID
     * @param data 额外的数据，会传递给接收方合约
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
    }

    /**
     * @dev 授权`to`操作`tokenId`
     *
     * `auth`参数是可选的。如果传递的值不为0，则此函数将检查`auth`是代币的所有者，
     * 还是被授权操作此所有者持有的所有代币的地址
     *
     * 发出{Approval}事件
     *
     * 对此逻辑的重写应该通过带有额外`bool emitEvent`参数的变体来完成
     * 
     * @param to 被授权的地址
     * @param tokenId 代币ID
     * @param auth 授权者地址
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev `_approve`的变体，带有可选标志来启用或禁用{Approval}事件
     * 在转移上下文中不会发出事件
     * 
     * @param to 被授权的地址
     * @param tokenId 代币ID
     * @param auth 授权者地址
     * @param emitEvent 是否发出Approval事件
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        // 除非必要，避免读取所有者
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // 我们不使用_isAuthorized，因为单代币授权不应该能够调用approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        $._tokenApprovals[tokenId] = to;
    }

    /**
     * @dev 授权`operator`操作`owner`的所有代币
     *
     * 要求：
     * - operator不能是零地址
     *
     * 发出{ApprovalForAll}事件
     * 
     * @param owner 代币所有者地址
     * @param operator 操作员地址
     * @param approved 是否授权（true表示授权，false表示撤销授权）
     * 如果operator为零地址，会抛出ERC721InvalidOperator错误
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        $._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev 如果`tokenId`没有当前所有者（未铸造或已销毁），则回退
     * 返回所有者地址
     *
     * 对所有权逻辑的重写应该通过{_ownerOf}来完成
     * 
     * @param tokenId 代币ID
     * @return 代币所有者地址
     * 如果代币不存在，会抛出ERC721NonexistentToken错误
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }
}
