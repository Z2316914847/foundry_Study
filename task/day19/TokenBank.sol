// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./ownerERC20Permit.sol";
import { console } from "forge-std/Script.sol";
import { Permit2 } from "./permit2.sol";

interface IPermit2 {
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    struct PermitTransferFrom {
        address token;
        uint256 amount;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    // permit2必须要的数据内容
    function permit2TransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        uint8 v, bytes32 r, bytes32 s
    ) external;
}

// TokenBank添加一个方法
contract TokenBank {
    string public name; 
    string public symbol;
    ownerERC20Permit public token;
    Permit2 public permit2;   
    uint public LESS_MONEY = 0.01 ether;   

    mapping (address => uint256) deposits; 
    event depositMoney( address, uint256 );
    event WithdrawMoney( address, uint256 );
    event tranferSuccess(string);


    
    constructor(address tokenAddress, address permit2Address){
        token = ownerERC20Permit(tokenAddress);
        permit2 = Permit2(permit2Address);
    }

    receive() external payable { }



    function deposit(uint256 amount) public payable {
        require (amount > 0, " The deposit amount must not be less than 0.01!" );

        // 外部合约转账 + Bank添加记录
        try token.transferFrom(msg.sender, address(this), amount) returns(bool){
            emit  tranferSuccess("tranfer success!");
            deposits[msg.sender] = deposits[msg.sender] + amount;
        }catch {
            console.log(" deposit failed! ");
            revert("tranfer failed!");
        } 
        emit  depositMoney( msg.sender, amount );
    }

    function withdraw(address to,uint256 amount) public {
        require(deposits[msg.sender] > amount, "The balance amount less than deposit money!");
        deposits[msg.sender]  = deposits[msg.sender] - amount;
        try token.transfer(msg.sender, amount) returns (bool){
            emit tranferSuccess("tranfer success");
        }catch {
            revert("tranfer fail");
        }
        emit WithdrawMoney(to, amount);  
    }

    function tokensReceived(address from, uint256 amount) public {
        // 判断用户是否的真转账到tokenBankV2合约中
        require(msg.sender == address(token),"Only baseToken can be modified");
        deposits[from] = deposits[from] + amount;
        emit  depositMoney( msg.sender, amount );
    }

    function getdepositBalance(address addr) public view returns(uint256){
        return deposits[addr];
    }

    // ERC20拓展：permit授权
    function permitDeposit( uint256 amount,  uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        // 1. 先用 permit 授权
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        // 2. 再转账
        require(token.transferFrom(msg.sender, address(this), amount), "permitDeposit failed");
        // 判断用户是否的真转账到tokenBankV2合约中
        deposits[msg.sender] = deposits[msg.sender] + amount;
        emit  depositMoney( msg.sender, amount );
    }

    // 拓展 permit2授权
    // 参数：amount：代币数量，nonce：随机数，deadline：过期时间，v，r，s：签名值
    function depositWithPermit2(uint256 amount, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(amount > 0, "TokenBank: deposit amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= amount, "TokenBank: insufficient token balance");

        // 构造 permit2 合约需要的数据, 其实这个数据一般是由前端提供的
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            token: address(token),
            amount: amount,
            nonce: nonce,
            deadline: deadline
        });

        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),
            requestedAmount: amount
        });
        
        // 调用permit2转账
        IPermit2(address(permit2)).permit2TransferFrom(
            permit,
            transferDetails, 
            msg.sender, 
            v, r, s
        );

        // 更新用户的存款记录
        deposits[msg.sender] += amount;
        emit depositMoney(msg.sender, amount);
    }
}