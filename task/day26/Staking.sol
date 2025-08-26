// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// 导入相关合约和接口
import "./KKToken.sol";                // KKToken代币合约
import "./WETH9.sol";                  // WETH9包装ETH合约
import "./interface/ILendingPool.sol"; // 借贷池接口
import "./interface/IStaking.sol";     // 质押接口


/**
 * @title StakingPool - 质押池合约
 * @dev 这是一个支持ETH质押和奖励分发的智能合约
 * 用户可以质押ETH获得KKToken奖励，同时质押的ETH会被存入借贷市场赚取额外收益
 */
contract StakingPool is IStaking{
    
    KKToken public kkToken;           // KKToken代币合约，用于发放奖励
    ILendingPool public lendingPool;  // 借贷池合约，用于存入质押的ETH
    WETH9 public weth;                // WETH9合约，用于ETH和WETH的转换
    address public owner;             // 合约所有者地址
    
    uint256 public constant REWARD_PER_BLOCK = 10 * 1e18;   // 每个区块的奖励数量（10个KKToken）
    uint256 public totalStaked;                             // 总质押数量
    uint256 public lastRewardBlock;                         // 上次更新奖励的区块号
    uint256 public accRewardPerShare;                       // 累计每份质押的奖励（精度为1e12）
    
    /**
     * @dev 用户信息结构体
     * @param amount 用户质押的ETH数量
     * @param rewardDebt 用户已结算的奖励债务：每次用户添加质押，撤回质押会更新这个值
     * @param stakingTime 用户开始质押的时间戳, 感觉没啥作用
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 stakingTime; 
    }
    
    // 用户地址到用户信息的映射
    mapping(address => UserInfo) public userInfo;
    
    // 事件定义
    event Staked(address indexed user, uint256 amount);    // 质押事件
    event Unstaked(address indexed user, uint256 amount);  // 解除质押事件
    event Claimed(address indexed user, uint256 reward);   // 领取奖励事件
    
    /**
     * @dev 仅所有者修饰符
     * 限制某些关键功能只能由合约所有者调用
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    /**
     * @dev 构造函数
     * @param _kkToken KKToken合约地址
     * @param _weth WETH9合约地址：因为借贷池用的合约是真实的，那么weth也要用真实的
     * @param _lendingPool 借贷池合约地址：去找现成的，如compound，aave...
     */
    constructor(address _kkToken, address _weth, address _lendingPool) {
        kkToken = KKToken(_kkToken);
        weth = WETH9(_weth);
        lendingPool = ILendingPool(_lendingPool);
        owner = msg.sender;
        lastRewardBlock = block.number;
    }
    
    /**
     * @dev 更新奖励计算
     * 根据当前区块和上次更新区块的差值计算新增奖励
     * 更新累计每份质押的奖励
     */
    function updateGlobal() public {
        // 1. 质押数量为0，则不更新奖励
        if (block.number <= lastRewardBlock || totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }
        
        uint256 diff = block.number - lastRewardBlock;
        uint256 reward = diff * REWARD_PER_BLOCK;                //  这段时间的总奖励数量
        accRewardPerShare += (reward * 1e12) / totalStaked;      //  更新累计每份质押的奖励
        lastRewardBlock = block.number;                          //  更新 上次更新奖励 的 区块号
    }
    
    /**
     * @dev 质押ETH函数
     * 用户可以质押ETH获得KKToken奖励
     * 质押的ETH会被转换为WETH并存入借贷市场
     */
    function stake() external payable override {
        require(msg.value > 0, "Cannot stake 0");
        UserInfo storage user = userInfo[msg.sender];

        // 2. 更新累计奖励，全局状态
        updateGlobal();
        
        // 发放待领取的奖励
        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
            if (pending > 0) {
                kkToken.mint(msg.sender, pending);
            }
        } else {
            user.stakingTime = block.timestamp;
        }
        
        user.amount += msg.value;
        totalStaked += msg.value;
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
        
        // 存入借贷市场
        // if (address(lendingPool) != address(0)) {
        //     weth.deposit{value: msg.value}();
        //     weth.approve(address(lendingPool), msg.value);
        //     lendingPool.deposit(address(weth), msg.value, address(this), 0);
        // }
        
        emit Staked(msg.sender, msg.value);
    }
    
    /**
     * @dev 解除质押函数
     * @param _amount 要解除质押的ETH数量
     * 用户可以选择部分或全部解除质押
     */
    function unstake(uint256 _amount) external override {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount && _amount > 0, "Invalid amount");
        
        updateGlobal();
        
        uint256 pending = (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
        user.amount -= _amount;
        totalStaked -= _amount;
        if (user.amount == 0) {
            user.stakingTime = 0;
        }
        
        // 先更新状态，再发放奖励
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
        
        // 发放奖励
        if (pending > 0) {
            kkToken.mint(msg.sender, pending);
        }
        
        // 从借贷市场提取
        // if (address(lendingPool) != address(0)) {
        //     lendingPool.withdraw(address(weth), amount, address(this));
        //     weth.withdraw(amount);
        // }
        
        payable(msg.sender).transfer(_amount);
        emit Unstaked(msg.sender, _amount);
    }
    
    /**
     * @dev 领取奖励函数
     * 用户可以随时领取已累积的KKToken奖励
     */
    function claim() external override {
        updateGlobal();
        
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending = (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
        
        require(pending > 0, "No rewards");
        
        // 先更新状态，再发放奖励
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;   // 更新用户已结算的奖励债务
        kkToken.mint(msg.sender, pending);
        
        emit Claimed(msg.sender, pending);
    }
    
    // 查询用户质押余额
    function balanceOf(address account) external view override returns (uint256) {
        return userInfo[account].amount;
    }

    // 获取待领取的 KK Token 收益
    function earned(address account) external view override returns (uint256) {
        UserInfo memory user = userInfo[account];
        if (user.amount == 0) return 0;
        
        uint256 currentAcc = accRewardPerShare;
        if (block.number > lastRewardBlock && totalStaked > 0) {
            uint256 diff = block.number - lastRewardBlock;
            uint256 reward = diff * REWARD_PER_BLOCK;
            currentAcc += (reward * 1e12) / totalStaked;
        }
        
        return (user.amount * currentAcc) / 1e12 - user.rewardDebt;
    }
    
    /**
     * @dev 更新借贷池地址（仅所有者）
     * @param _lendingPool 新的借贷池合约地址
     */
    // function updateLendingPool(address _lendingPool) external onlyOwner {
    //     lendingPool = ILendingPool(_lendingPool);
    // }
    
    /**
     * @dev 紧急提取函数（仅所有者）
     * 在紧急情况下，所有者可以提取合约中的所有ETH
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner).transfer(balance);
        }
    }
    
    /**
     * @dev 接收ETH的回退函数
     * 允许合约接收ETH
     */
    receive() external payable {}
}