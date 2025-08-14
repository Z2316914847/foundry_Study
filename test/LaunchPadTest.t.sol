// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import { memeProxy } from "../task/day24/memeProxy.sol";
import { memeToken } from "../task/day24/memeToken.sol";
import { IUniswapV2Router02 } from "../task/day24/IUniswapV2Router02.sol";


contract MemeTokenTest is Test {
    memeToken public token;
    memeProxy public proxy;
    MockUniswapV2Router public mockRouter;
    MockWETH public mockWETH;

    address projectOwner = makeAddr("alice");  // 项目方地址
    address memeCreator = makeAddr("bob");    // meme 第一次初始化地址，后面是铸造地址等同于 memecreator 转账 给铸造者
    address user = makeAddr("user");   // 铸造者 == 用户

    function setUp() public {
        vm.startPrank(projectOwner);

        mockWETH = new MockWETH();
        mockRouter = new MockUniswapV2Router(address(mockWETH));

        proxy = new memeProxy(address(mockRouter));
        vm.stopPrank();
    }

    // 测试部署
    function testMeme_Deploy() public {
        vm.startPrank(memeCreator);
        string memory symbol = "meme";
        uint256 maxSupply = 1000000;
        uint256 perMint = 10;
        uint256 totalPrice = 1 ether;
        address memeAddress = proxy.deployMeme(symbol, maxSupply, perMint, totalPrice);

        assertTrue(proxy.isMemeToken(memeAddress));
        assertEq(memeToken(memeAddress).creator(), memeCreator);
        assertEq(memeToken(memeAddress).maxSupply(), 1000000);
        assertEq(memeToken(memeAddress).perMint(), 10);
        assertEq(memeToken(memeAddress).price(), 1 ether);
        vm.stopPrank();
    }

    // 测试铸造
    function testMeme_Mint() public {
        uint256 initialProjectBalance = projectOwner.balance;
        uint256 initialCreatorBalance = memeCreator.balance;
        vm.deal(user, 1 ether);

        vm.startPrank(memeCreator);
        string memory symbol = "meme";
        uint256 maxSupply = 1000000;
        uint256 perMint = 10;
        uint256 totalPrice = 1 ether;  // 每个 token 单价 0.1 ether
        address memeAddress = proxy.deployMeme(symbol, maxSupply, perMint, totalPrice);
        vm.stopPrank();

        vm.startPrank(user);
        proxy.mint{value: 1 ether}(memeAddress);
        vm.stopPrank();

        assertEq(memeToken(memeAddress).balanceOf(user), 9);  // 用户铸造 meme 币成功
        
        assertEq(user.balance, 0 ether);
        assertEq(address(proxy).balance - initialProjectBalance, 0.1 ether);
        assertEq(memeCreator.balance - initialCreatorBalance, 0.9 ether);

    }

    // 测试添加流动性
    function testMeme_AddLiquidityETH() public {
        // 铸造代币
        uint256 initialProjectBalance = projectOwner.balance;
        uint256 initialCreatorBalance = memeCreator.balance;
        vm.deal(user, 1 ether);

        vm.startPrank(memeCreator);
        string memory symbol = "meme";
        uint256 maxSupply = 1000000;
        uint256 perMint = 10;
        uint256 totalPrice = 1 ether;  // 每个 token 单价 0.1 ether
        address memeAddress = proxy.deployMeme(symbol, maxSupply, perMint, totalPrice);
        vm.stopPrank();

        vm.startPrank(user);
        proxy.mint{value: 1 ether}(memeAddress);
        vm.stopPrank();

        // 添加流动性
        vm.startPrank(projectOwner);
        proxy._AddLiquidity( memeAddress, address(proxy).balance);

        vm.stopPrank();
    }

    // 从流动性中提取代币
    function testMeme_BuyMemme() public {
        // 铸造代币
        uint256 initialProjectBalance = projectOwner.balance;
        uint256 initialCreatorBalance = memeCreator.balance;
        vm.deal(user, 1 ether);

        vm.startPrank(memeCreator);
        string memory symbol = "meme";
        uint256 maxSupply = 1000000;
        uint256 perMint = 10;
        uint256 totalPrice = 1 ether;  // 每个 token 单价 0.1 ether
        address memeAddress = proxy.deployMeme(symbol, maxSupply, perMint, totalPrice);
        vm.stopPrank();

        vm.startPrank(user);
        proxy.mint{value: 1 ether}(memeAddress);
        vm.stopPrank();

        // 添加流动性
        vm.startPrank(projectOwner);
        proxy._AddLiquidity( memeAddress, address(proxy).balance);
        vm.stopPrank();

        // 兑换 
        memeToken meme = memeToken(memeAddress);
        uint256 buyAmount = 0.1 ether;
        uint256 expectedTokensFromUniswap = buyAmount * 20000;
        uint256 tokensAtInitialPrice = buyAmount /(meme.price()/meme.perMint());

        // 确保mock价格更优:  这段的意思是：uniswarp 会拒绝 当前价格小于设定价格的交易(因为这是我自己定义的)
        //   市场通常是拒绝 当前价格高于起始价格，因为 要防止用户追涨（市场通常大涨大跌），造成不必要的损失。
        //   市场通常是接受 当前价格低于起始价格。这样用户可以买入更多的代币
        assertTrue(expectedTokensFromUniswap > tokensAtInitialPrice, "Mock price should be favorable");

        vm.startPrank(projectOwner);
        vm.deal(address(projectOwner), 1 ether);   // 兑换代币，的前提是你有和足够的代币
        proxy.buyMeme{value: buyAmount}(memeAddress, expectedTokensFromUniswap);
        vm.stopPrank();


    }

}

// 模拟 Uniswap V2 路由器进行测试
contract MockUniswapV2Router is IUniswapV2Router02 {
    address private _weth;
    mapping(address => mapping(address => address)) public pairs;
    
    constructor(address _wethAddr) {
        _weth = _wethAddr;
    }
    
    function WETH() external pure override returns (address) {
        return 0x1234567890AbcdEF1234567890aBcdef12345678; // Mock WETH address
    }
    
    // function factory() external pure override returns (address) {
    //     return address(0); // Mock factory address
    // }
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable override returns (uint amountToken, uint amountETH, uint liquidity) {
        // Mock implementation - just return the input values
        return (amountTokenDesired, msg.value,  amountTokenDesired);
    }
    
    // function addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external override returns (uint amountA, uint amountB, uint liquidity) {
    //     return (amountADesired, amountBDesired, amountADesired + amountBDesired);
    // }
    
    function getAmountsOut(uint amountIn, address[] calldata path)
        external pure override returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        // Mock: assume 1 ETH = 20000 tokens for favorable pricing
        // Token price is 0.0001 ether = 100000000000000 wei
        // So 1 ETH should give us 1e18/100000000000000 = 10000 tokens at initial price
        // We make Uniswap give 20000 tokens (2x better)
        if (path.length == 2) {
            amounts[1] = amountIn * 20000;
        }
    }
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable override {
        // Mock implementation - we'll handle token transfer in test
        // In real implementation, this would transfer tokens to 'to' address
    }
}

// 莫您 WETH contract
contract MockWETH {
    mapping(address => uint256) public balanceOf;
    
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}