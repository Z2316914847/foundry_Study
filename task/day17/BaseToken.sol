// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import { console } from "forge-std/Test.sol";


// token(代币，货币，简称 token == 美元/人民币/欧元/日元)，刚好ERC20协议规定了货币必须要实现的功能
contract BaseERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint248 public totalSupply;   // 设置供应量归部署者所有。设置uint248 节省256位存储消耗

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor()  {
        name = 'Base';
        symbol = 'Base';
        decimals = 18;
        totalSupply = 100000000*10**18;
        balances[msg.sender] = totalSupply;
    }

    // 允许任何一个人查看某地址金额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // 从调用者地址向目标地址转账
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value){
            revert("ERC20: transfer amount exceeds balance");
        } 
        // 转账前，判断目标地址是否是合约地址，如果是，则调用 transferWithCallback() 方法
        if(_to.code.length != 0){
            require(transferWithCallback(_to, _value),"transfer tokens failed");  
        }
        balances[msg.sender]  =balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }

    // 从 from地址向to地址转账(需要授权),转账者的地址其实是授权者地址

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // 判断地址和value输入是否符合要求
        require(_from != address(0) && _to != address(0) && _value > 0, "transferFrom faily");

        // 查询被授权人 spender 余额>value
        uint256  approveBalance= allowance( _from, msg.sender);
        require(approveBalance>=_value ,"ERC20: approve value greater than balance");

        // 授权的记录更新 + balances更新转账
        allowances[_from][msg.sender] = approveBalance - _value;
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    // 允许 spender多次从调用者地址提款 ：允许 Token 的所有者批准某个地址消费他们的一部分Token（approve）
    function approve(address _spender, uint256 _value) public returns (bool) {
        // 授权地址要有效
        require(_spender!=address(0), "ERC20: approve to the zero address");
        // 授权value额度必须大于0
        require(_value>0,"ERC20: approve value less than zero");
        // 授权记录更新
        bool success = approve2(msg.sender, _spender, _value);
        require(success,"ERC20: approve failed");
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function approve2(address _from ,address _spender, uint256 _value) public returns (bool) {
        allowances[_from][_spender] = allowances[_from][_spender] + _value;
        return true; 
    }

    // 查询owner授权给 spender地址额度
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {  
        return allowances[_owner][_spender];
    }

    // 转账函数.在转账时，如果目标地址是合约地址的话，调用目标地址的 tokensReceived() 方法。
    function transferWithCallback(address to, uint256 amount) public  returns (bool){
        (bool success,) = to.call(abi.encodeWithSelector(bytes4(keccak256("tokensReceived(address,uint256)")), msg.sender, amount));
        return success;
    }


}