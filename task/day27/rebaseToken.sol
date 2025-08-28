// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";


contract RebaseToken {
    mapping(address => uint256) private _gonBalances;    // 存储每个地址的代币数量（以 gon 为单位）
    mapping(address => mapping(address => uint256)) private _allowances;   // 存储每个地址的授权额度

    uint256 private constant MAX_UINT256 = ~uint256(0);   // ~uint256(0) ==type(uint256).max。 ' ~ ' 这是按位取反操作符，它会将每一位都翻转（0 变成 1，1 变成 0）
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 100_000_000 * 10**18;   // 初始代币供应量
    // TOTAL_GONS能被supply整除，这样在rebase时，supply的值会一直保持整数
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);   // 总代币 gon 数量：找一个数，这个数小于等于uint256的最大值，且这个数除以INITIAL_FRAGMENTS_SUPPLY的余数为0

    string public name = "Rebase Deflation Token";
    string public symbol = "RDT";
    uint8 public decimals = 18;
    
    uint256 private _totalSupply;              // 代币供应量
    uint256 private _gonsPerFragment;          // 调整系数 = TOTAL_GONS / _totalSupply
    
    uint256 public lastRebaseTime;             // 上次rebase时间
    uint256 public rebaseCount;                // rebase次数
    address public owner;                      // 所有者
    
    uint256 private constant DEFLATION_RATE = 99;             // 通缩率，每年通缩1%
    uint256 private constant RATE_DENOMINATOR = 100;          // 通缩率分母
    uint256 private constant REBASE_INTERVAL = 365 days;      // rebase间隔时间

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Rebase(uint256 indexed epoch, uint256 totalSupply);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;
        lastRebaseTime = block.timestamp;
        _gonBalances[msg.sender] = TOTAL_GONS;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // 查询代币总供应量
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 查询某个地址的代币余额
    function balanceOf(address who) public view returns (uint256) {
        return _gonBalances[who] / _gonsPerFragment;
    }

    // 查询某个地址的代币余额（以 gon 为单位）
    function gonBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(to != address(this), "Transfer to contract");
        
        uint256 gonValue = value * _gonsPerFragment;
        _gonBalances[msg.sender] -= gonValue;
        _gonBalances[to] += gonValue;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(to != address(this), "Transfer to contract");
        
        _allowances[from][msg.sender] -= value;
        uint256 gonValue = value * _gonsPerFragment;
        _gonBalances[from] -= gonValue;
        _gonBalances[to] += gonValue;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // 增加授权额度
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    // 减少授权额度
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    // 执行rebase(自动执行),当前时间要 >= 上次rebase时间 + rebase间隔时间
    function rebase() external onlyOwner {
        require(block.timestamp >= lastRebaseTime + REBASE_INTERVAL, "Rebase too early");
        _rebase();
    }

    // 执行rebase（手动执行），不建议执行
    function manualRebase() external onlyOwner {
        _rebase();
    }

    // 内部rebase逻辑
    function _rebase() internal {
        rebaseCount++;
        uint256 newTotalSupply = (_totalSupply * DEFLATION_RATE) / RATE_DENOMINATOR;
        _totalSupply = newTotalSupply;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;
        lastRebaseTime = block.timestamp;
        emit Rebase(rebaseCount, _totalSupply);
    }

    // 查询调整系数 K
    function gonsPerFragment() external view returns (uint256) {
        return _gonsPerFragment;
    }

    // 查询是否可以rebase
    function canRebase() external view returns (bool) {
        return block.timestamp >= lastRebaseTime + REBASE_INTERVAL;
    }

    // 查询下次rebase时间
    function nextRebaseTime() external view returns (uint256) {
        return lastRebaseTime + REBASE_INTERVAL;
    }
}