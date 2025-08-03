// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Bank{

    mapping(address => uint256) public balances;
    mapping( address => address) public total_top10;
    address constant GUARD = address(1);  // address是20字节 , address(1)强制转换 == address(uint160(uint256(1)))
    uint256 public mapSize = 0; // 计数器

    constructor() payable {
        total_top10[GUARD] =GUARD; 
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
        if(total_top10[msg.sender]==address(0) && mapSize<10){
            mapSize = mapSize+1;
        }

        // 更新前10
        setBalanceTop(msg.sender, balances[msg.sender]);
    }

    // 数组记录存款金额的前 10 名用户
    function setBalanceTop(address addr, uint256 amount) public{
        // 获取mapping中第一个 value,和设置第二个 key - value 
        address current = total_top10[GUARD];
        address pre = GUARD;  // 第一个value
        address next = total_top10[current];
        if(total_top10[current] == GUARD && mapSize == 1 ) {
            total_top10[pre] = addr;
            return;
        }
        // 获取第二个 key      1  2  => 2  1  6 => 6  2  1  5 => 6 5 2 1
        for(uint i=1; i<mapSize; i++){
            if(balances[current]<amount){
                total_top10[pre] = addr;
                total_top10[addr] = next;
                return;
            }            
            pre = next;  // 这是第二个 value
            next = total_top10[next];  // 第三个 value
            current = pre;  
        }
        total_top10[pre] = addr;
        total_top10[addr]= next;
         
    }

    //获取top3用户地址
    function getBalanceTop(address addre) public view returns (address addr){
        return total_top10[addre];
    }

}
