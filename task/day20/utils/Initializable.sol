// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @title Initializable - 可升级合约的初始化基类
 * @dev 这是一个基础合约，用于帮助编写可升级合约或任何将部署在代理后面的合约
 * 
 * 由于代理合约不使用构造函数，通常将构造函数逻辑移动到外部初始化函数中，
 * 通常称为`initialize`。然后需要保护这个初始化函数，使其只能被调用一次。
 * 此合约提供的{initializer}修饰符将具有此效果。
 *
 * 初始化函数使用版本号。一旦使用版本号，它就会被消耗，不能重复使用。
 * 这种机制防止每个"步骤"的重新执行，但允许在升级添加需要初始化的模块时创建新的初始化步骤。
 *
 * 使用示例：
 *
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * 提示：为避免代理处于未初始化状态，应尽早调用初始化函数，
 * 通过将编码的函数调用作为`_data`参数提供给{ERC1967Proxy-constructor}。
 *
 * 注意：当与继承一起使用时，必须手动注意不要两次调用父初始化器，
 * 或确保所有初始化器都是幂等的。这不会像Solidity的构造函数那样自动验证。
 *
 * [警告]
 * ====
 * 避免让合约处于未初始化状态。
 *
 * 未初始化的合约可能被攻击者接管。这适用于代理及其实现合约，
 * 这可能会影响代理。为防止实现合约被使用，您应该在构造函数中调用
 * {_disableInitializers}函数，在部署时自动锁定它：
 *
 * ```solidity
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev 可初始化合约的存储结构
     *
     * 它在自定义ERC-7201命名空间上实现，以减少与可升级合约一起使用时存储冲突的风险
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev 指示合约已被初始化的版本号
         * 0表示未初始化，1表示已初始化，2及以上表示重新初始化的版本
         */
        uint64 _initialized;
        /**
         * @dev 指示合约正在初始化过程中
         * 用于防止重入攻击和确保初始化过程的原子性
         */
        bool _initializing;
    }

    /// @dev ERC7201存储位置常量 - 通过哈希计算确定的唯一存储槽
    /// 这个位置是通过keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))计算得出
    /// 确保在代理升级过程中存储位置不会冲突
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev 合约已经初始化错误
     * 当尝试初始化已经初始化的合约时抛出
     */
    error InvalidInitialization();

    /**
     * @dev 合约不在初始化状态错误
     * 当在非初始化状态下调用onlyInitializing修饰的函数时抛出
     */
    error NotInitializing();

    /**
     * @dev 合约初始化或重新初始化时触发的事件
     * @param version 初始化版本号
     */
    event Initialized(uint64 version);

    /**
     * @dev 定义一个受保护的初始化函数修饰符，最多只能调用一次
     * 在其作用域内，可以使用`onlyInitializing`函数来初始化父合约
     *
     * 类似于`reinitializer(1)`，除了在构造函数上下文中，`initializer`可以被调用任意次数。
     * 构造函数中的这种行为在测试期间很有用，不期望在生产中使用。
     *
     * 发出{Initialized}事件
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // 缓存值以避免重复的sload操作
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // 允许的调用：
        // - initialSetup: 合约不在初始化状态且没有先前版本被初始化
        // - construction: 合约在版本1初始化（无重新初始化）且当前合约刚刚部署
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev 定义一个受保护的重新初始化函数修饰符，最多只能调用一次，
     * 且只有在合约之前没有初始化到更高版本时才能调用
     * 在其作用域内，可以使用`onlyInitializing`函数来初始化父合约
     *
     * 重新初始化器可以在原始初始化步骤之后使用。这对于配置通过升级添加且需要初始化的模块至关重要。
     *
     * 当`version`为1时，此修饰符类似于`initializer`，除了标记为`reinitializer`的函数不能嵌套。
     * 如果一个在另一个的上下文中被调用，执行将回退。
     *
     * 注意版本可以以大于1的增量跳跃；这意味着如果多个重新初始化器在合约中共存，
     * 以正确的顺序执行它们取决于开发者或操作员。
     *
     * 警告：将版本设置为2**64 - 1将防止任何未来的重新初始化。
     *
     * 发出{Initialized}事件
     * 
     * @param version 重新初始化的版本号
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev 修饰符，用于保护初始化函数，使其只能被具有{initializer}和{reinitializer}修饰符的函数直接或间接调用
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev 如果合约不在初始化状态则回退。参见{onlyInitializing}
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev 锁定合约，防止任何未来的重新初始化。这不能是初始化器调用的一部分。
     * 在合约的构造函数中调用此函数将防止该合约被初始化或重新初始化到任何版本。
     * 建议使用此函数来锁定设计为通过代理调用的实现合约。
     *
     * 第一次成功执行时发出{Initialized}事件
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev 返回已初始化的最高版本。参见{reinitializer}
     * @return 已初始化的版本号
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev 如果合约当前正在初始化则返回`true`。参见{onlyInitializing}
     * @return 如果合约正在初始化则返回true，否则返回false
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev 指向存储槽的指针。允许集成者用自定义存储位置覆盖它
     *
     * 注意：考虑遵循ERC-7201公式来派生存储位置
     * @return 存储槽的bytes32标识符
     */
    function _initializableStorageSlot() internal pure virtual returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    /**
     * @dev 返回指向存储命名空间的指针
     * @return $ 指向InitializableStorage结构体的存储引用
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        bytes32 slot = _initializableStorageSlot();
        assembly {
            $.slot := slot
        }
    }
}
