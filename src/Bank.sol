// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// 编写一个 Bank 合约，实现功能：
//   可以通过 Metamask 等钱包直接给 Bank 合约地址存款
//   在 Bank 合约记录每个地址的存款金额
//   用数组记录存款金额的前 3 名用户
//   编写 withdraw() 方法，仅管理员可以通过该方法提取资金。

contract Bank{
    address owner;   // 设置部署合约的人为管理员
    mapping(address => uint256) public balances;
    address[] public total_top3;

    constructor() payable {
        // 设置部署合约的人为管理员
        owner = msg.sender;
    }

    receive() external payable {
        saveMeomey();
    }

    // 记录每个地址的存款金额，并排序数组
    function saveMeomey() public payable {
        // 存入金额必须大于0
        require(msg.value > 0,"money must>0");

        // 当msg.value有数据时，会自动将金额存入合约的balance
        // 判断是否为新用户，是新用户则添加到mapping中
        balances[msg.sender] =balances[msg.sender]+ msg.value;

        // 更新前三
        setBalanceTop(msg.sender, balances[msg.sender]);
    }

    // 数组记录存款金额的前 3 名用户
    function setBalanceTop(address addr, uint256 amount) public{
        // 方法二:找出最小索引
        uint min_index =0; 
        if(total_top3.length < 3) {
            total_top3.push(addr);
            return;
        }

        for(uint j=1; j<total_top3.length; j++){
            if (balances[total_top3[min_index]] >balances[total_top3[j]]){
                min_index = j;
            }
        }

        if(amount > balances[total_top3[min_index]]) {
            total_top3[min_index] = addr;
        }
    }

    //获取top3用户地址
    function getBalanceTop() public view returns (address[] memory addr){
        return total_top3;
    }


    // withdraw() 方法，仅管理员可以通过该方法提取资金。
    function withdraw(uint256 money) public{
        // 判断money是不是数字，这里还没做，待会做
        // 判断是否是管理员  普通账户比较
        require(msg.sender == owner);
        require(money <= address(this).balance);
        payable(msg.sender).transfer(money);
    }

    // 查询合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 查询用户余额
    function getAccountBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

}