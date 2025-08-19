// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


contract memeToken is ERC20 {

    address public factory;  // 设置项目坊地址 -- 构建 proxy 合约地址 

    address public creator;  // Meme首次部署者地址，将接收99%的铸造费用
    
    uint256 public maxSupply;  // 代币最大供应量

    uint256 public perMint;  // 每次铸造可以获得的代币数量

    uint256 public price;  // 每次铸造需要支付的费用(wei)
    
    uint256 public totalMinted;  // 已铸造的代币总量

    constructor() ERC20("memeToken", "meme") {
        factory = msg.sender;
    }

    // meme比属性初始化
    // 参数：_creator：创建者地址，_maxSupply：最大供应量，_perMint：每次铸造获得的代币数量，_price：每次铸造价格(wei，其实也设置每个代币金额，但为了简单，这里设置总额)
    function initialize( address _creator, uint256 _maxSupply, uint256 _perMint, uint256 _price ) public {
        require(creator == address(0), "Already initialized");
        factory = msg.sender;
        creator = _creator;
        maxSupply = _maxSupply;
        perMint = _perMint;
        price = _price;
        // ERC20默认精度18，所以这里就不设置精度了
    }

    // meme币铸造
    function _mint(address to) public payable{
        // 检查铸造数量是否超过最大供应量
        require(totalMinted + perMint <= maxSupply, "Exceeds max supply");
        // 铸造费用检查
        require(msg.value >= price, "Not enough ether");
        // 检查铸造是否为工厂
        require(msg.sender == factory, "Only factory can mint"); 

        // 收益分配: 1%给项目方, 90%给创建者
        uint256 factoryFee = (msg.value * 10) / 100;
        uint256 creatorFee = msg.value - factoryFee; 
        (bool creatorSuceess, ) = creator.call{value: creatorFee}("");
        (bool factorySuceess, ) = factory.call{value: factoryFee}("");
        require(creatorSuceess && factorySuceess, "Failed to send funds");
        // 退还多余的 ETH
        if (msg.value > price) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - factoryFee - creatorFee}("");
            require(refundSuccess, "Refund failed");
        }

        // 代币转为铸造人，即购买meme币的买家
        _mint(to, perMint*90/100);  // 实际购买资金只有 90%, 为什么我用95%购买的代币只能由90% 的代币量
        // 5%的token添加到流动性中
        _mint(factory, perMint*10/100);  // 项目方获得 5%
        totalMinted += perMint;
    }
    
}