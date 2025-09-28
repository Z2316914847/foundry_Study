// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ownerERC20Permit.sol";
import {Test, console} from "forge-std/Test.sol";

// 将需要 锁仓的 token 转移到这个合约中，并设置锁仓期限和释放周期。
contract MyVesting {

    address public immutable _beneficiary;     // 受益人
    uint256 public immutable  _startTime;      // 锁仓开始时间
    uint256 public immutable _LockPeriod;      // 锁定期（12个月）
    uint256 public immutable  _vestingPeriod;  // 释放周期（24个月）
    ownerERC20Permit public immutable _token;  // 锁定的 Token 代币
    uint256 public _totalAmount;               // 总锁定 Token 数量
    // mapping(address => uint256) public _erc20Released; // 我们只记录一个 token ，所以不用mapping
    uint256 public _releasedAmount;            // 已释放 token 数量

    // 参数：受益人地址、开始释放时间（Unix 时间戳）、总释放周期（秒）
    constructor( address beneficiary, address tokenAddress ){
        _token = ownerERC20Permit(tokenAddress);
        _beneficiary = beneficiary;
        _startTime = block.timestamp;
        _LockPeriod = 365 days;
        _vestingPeriod = 730 days;

    }

    // 存款
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        
        _totalAmount = amount;
        require( _token.transferFrom(msg.sender, address(this), amount), "Token transfer failed" );
    }

    // 计算当前 应当释放当前解锁的 ERC20 给受益人
    function  release() public returns (uint256) {
        
        uint256 currentReleasedAmount = getReleasableAmount() - _releasedAmount; 
        require(currentReleasedAmount > 0, "No tokens to release");

        // 更新释放数量
        _releasedAmount = _releasedAmount + currentReleasedAmount;
        _token.transfer(_beneficiary, currentReleasedAmount);

        return currentReleasedAmount;
    }

    // 计算从 开始释放时间 到 当前时间 应当释放的 ERC20 数量
    function getReleasableAmount() public view returns (uint256) {
        if(block.timestamp < _startTime + _LockPeriod){
            // 锁仓期内，不是释放 token
            return 0;
        }else if( block.timestamp < _startTime + _LockPeriod + _vestingPeriod ){
            // 释放 token 期间，线性释放
            // 当前时间/总释放周期(取整)，然后乘以总数量
            uint256 vestingTime = block.timestamp - _startTime - _LockPeriod;
            return (vestingTime*_totalAmount) / _vestingPeriod ;
        }else {
            // 全部释放完毕
            return _totalAmount;
        }
    }




}