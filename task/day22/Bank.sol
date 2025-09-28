// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 导入Chainlink自动化接口和OpenZeppelin权限控制
// import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface AutomationCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
  function performUpkeep(bytes calldata performData) external;
}

/**
 * @title 自动化银行合约
 * @notice 实现存款功能，并在存款超过阈值时自动转移一半资金到指定地址
 * @dev 集成Chainlink Automation、Gelato和OpenZeppelin Defender三种自动化方案
 */
contract AutoBank is AutomationCompatibleInterface, Ownable {
    // 状态变量
    uint256 public totalDeposits;       // 总存款金额
    uint256 public threshold;           // 触发自动转账的阈值（wei单位）
    address public targetAddress; // 资金转移目标地址（不可变）
    
    // 用户余额映射
    mapping(address => uint256) public balances;
    
    // 事件定义
    event Deposited(address indexed depositor, uint256 amount);
    event ThresholdReached(uint256 totalDeposits);
    event FundsTransferred(uint256 amount);
    
    /**
     * @dev 构造函数初始化阈值和目标地址
     * @param _threshold 触发自动转账的阈值（wei单位）
     * @param _targetAddress 接收转移资金的地址
     */
    constructor(uint256 _threshold, address _targetAddress) public Ownable(msg.sender){
        threshold = _threshold;
        targetAddress = _targetAddress;
    }
    
    /**
     * @notice 存款函数（接收ETH）
     * @dev 必须发送大于0的金额，更新用户余额和总存款
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @notice 取款函数
     * @param amount 要提取的金额（wei单位）
     * @dev 检查用户余额是否充足，更新状态后转账
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    /**
     * @notice 设置新的触发阈值（仅合约所有者可调用）
     * @param _threshold 新的阈值（wei单位）
     */
    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }
    
    /* ========== Chainlink Automation 集成 ========== */
    
    /**
     * @dev Chainlink Automation检查函数
     * @return upkeepNeeded 是否需要执行performUpkeep
     * @notice 当总存款达到阈值时返回true
     */
    function checkUpkeep(bytes calldata /*checkData*/) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory /*performData*/) 
    {
        upkeepNeeded = totalDeposits >= threshold;
    }
    
    /**
     * @dev Chainlink Automation执行函数
     * @notice 当checkUpkeep返回true时自动调用，转移一半资金到目标地址
     */
    function performUpkeep(bytes calldata /*performData*/) external override {
        require(totalDeposits >= threshold, "Threshold not reached");
        
        uint256 amountToTransfer = totalDeposits / 2;
        totalDeposits -= amountToTransfer;
        
        payable(targetAddress).transfer(amountToTransfer);
        emit FundsTransferred(amountToTransfer);
        emit ThresholdReached(totalDeposits);
    }
}