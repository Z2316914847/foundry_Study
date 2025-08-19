// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { console } from "forge-std/Test.sol";
import "./memeToken.sol";
import "../../lib/openzeppelin-contracts/contracts/proxy/Clones.sol";
import "./UniswapV2Router02.sol";


// 这是项目方构建的 meme 发射平台
contract memeProxy {
    using Clones for address;
    address public meme;  // 指向真正的Meme合约地址
    mapping(address => bool) public isMemeToken;  // 记录meme铸造者地址
    UniswapV2Router02 public uniswapRouter;  // 指向uniswapRouter合约地址

    // 事件：当新Meme代币部署时触发
    // 参数：creator 部署者地址，token 新部署的Meme代币地址，symbol maxSupply 代币总量
    event MemeDeployed( address indexed creator, address token, string symbol, uint256 maxSupply );
    // 事件：当代币被铸造时触发
    // 参数：tokenAddress 代币地址，buyer 铸造者地址，amount 铸造数量，paid 支付金额
    event MemeMinted(address indexed tokenAddress, address indexed buyer, uint256 amount, uint256 paid);


    constructor( )  {
        meme = address(new memeToken());
    }

    // 部署 meme 合约  
    function deployMeme( string memory symbol, uint256 maxSupply, uint256 perMint, uint256 totalPrice) public returns (address tokenAddr){
        // 使用最小代理克隆实现合约,不会执行构造函数。
        tokenAddr = meme.clone();
        // 初始化克隆合约
        memeToken(tokenAddr).initialize(msg.sender, maxSupply, perMint, totalPrice);
        
        // 记录新代币
        isMemeToken[tokenAddr] = true;    

        // 触发事件
        emit MemeDeployed(msg.sender, tokenAddr, symbol, maxSupply);
        return tokenAddr;
    }

    // 铸造meme
    // 参数：tokenAddr 代币地址
    function mint(address tokenAddr) public payable  {

        require(isMemeToken[tokenAddr], "Token not deployed by this factory");
        memeToken(address(tokenAddr))._mint{value: msg.value}(msg.sender);
        
        emit MemeMinted(tokenAddr, msg.sender, memeToken(tokenAddr).perMint(), memeToken(tokenAddr).price());

    }
    
    receive() external payable {}

    // 添加流动性
    // 参数：amount eth数量
    function _AddLiquidity(address payable _uniswapRouter, address tokenAddr, uint256 ETHamount) public payable{
        // 根据amount，计算proxy合约的所需的token数量
        memeToken token = memeToken(tokenAddr);
        uint256 oneTokenMoney = token.price()/token.perMint();
        uint256 tokenAmount = ETHamount/oneTokenMoney;
        require( address(this).balance >= ETHamount , " not enough eth ");
        require( token.balanceOf(address(this)) >= tokenAmount, " not enough token ");

        // 授权token给 uniswarpRouter
        uniswapRouter = UniswapV2Router02(_uniswapRouter);
        token.approve(_uniswapRouter, tokenAmount);

        // 添加流动性，这里只lpliquidity暂时返回  token 数量
        (, , uint256 Lpliquidity) = uniswapRouter.addLiquidityETH{value: ETHamount}(
            tokenAddr,
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 300
        );

        console.log("Lpliquidity:", Lpliquidity);

    }

}