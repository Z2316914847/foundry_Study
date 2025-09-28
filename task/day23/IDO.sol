// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


// 1.以 0.0001 eth 的单价预售 100 万的 OPS Token
// 2. 在某时间内目标凑集 100 ETH
// 3. 预售门槛为 0.001 ETH
// 4. 预售用户可 claim Token,预售失败 refund 本金
import  "./ownerERC20Permit.sol";
contract IDO {
    address public owner;
    ownerERC20Permit public token;
    uint256 public constant price = 0.0001 ether;         // 每个代币价格 = 0.0001 ether
    uint256 public constant target = 1000000e18;          // 100 万 Token(代币)
    uint256 public constant target_Money = 100 ether;     // 目标筹集 100 ETH
    uint256 public constant min_Principal = 0.001 ether;  // 用户最少认购本金 = 0.001 ether
    uint256 public deadLine;                              // 预售截止时间
    uint256 public total_Raised;                          // 总共筹集的ETH
    // bool public finalized;        // 是否成功
    bool public success;                                  // 预售是否成功

    mapping(address => uint256) public balances;          // 预售用户的认购金额

    constructor(address _token, uint256 _deadLine) {
        token = ownerERC20Permit(_token);
        deadLine = block.timestamp + _deadLine;
        owner = msg.sender;  // 记住要把 token 授权给 IDO合约，数量 target
    }

    // 用户预售购买：保证在活动期间、最小认购必须达到，且不超过预售限额
    function buy() external payable {
        require(block.timestamp < deadLine, "IDO is over");
        require(msg.value >= min_Principal, "The minimum principal is 0.001 ETH");
        if( msg.value + total_Raised < target_Money){
            // 为完成认购
            total_Raised = total_Raised + msg.value;
            balances[msg.sender] = balances[msg.sender] + msg.value;
        }else if(msg.value + total_Raised == target_Money){
            total_Raised = total_Raised + msg.value;
            balances[msg.sender] = balances[msg.sender] + msg.value;
            success = true;
        }else{
            // 超出预售限额，拒绝认购
            revert(" Fundraising completed, reject buy");
        }

    }

    // 获取总筹集的 ETH
    function getRaised() external view returns(uint256) {
        return total_Raised;
    }

    // 预售成功，转账 Token
    function claimToken() public {
        require(success, "The IDO is not successful");
        require(block.timestamp > deadLine, "The IDO is not over");
        uint256 tokenAmount = target * balances[msg.sender] / target_Money;
        require(tokenAmount == 0 , " Not purchased during the pre-sale period ");
        token.transferFrom(owner, msg.sender, tokenAmount);
    }

    // 预售失败，退回本金(管理员退回)
    function refund() external  {
        require(block.timestamp > deadLine, "The IDO is not over");
        require(!success, "The IDO is successful");
        
        payable(msg.sender).transfer(balances[msg.sender]);
    }

    receive() external payable {

    }

    
}