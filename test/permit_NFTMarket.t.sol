// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import { Test, console } from "forge-std/Test.sol";
import "../task/day14/NFTMarket.sol";
import "../task/day14/ownerERC20Permit.sol";
import "../task/day14/ownerNFT.sol";
import "../task/day14/WhitelistManager.sol";
import "../task/day14/TokenBank.sol";
import "../task/day14/permit2.sol";

contract NFTMarketTest is Test{
    
    ownerERC20Permit public token;
    ERC721 public nft;
    WhitelistManager public whitelist;
    NFTMarket public market;
    TokenBank public tokenBank;
    Permit2 public permit2;


    // address owner = makeAddr("alice");
    // address buyer = makeAddr("bob");
    address other = makeAddr("tom");
    address buyer = vm.addr(1);
    address owner = vm.addr(2);


    // 测试参数范围
    uint256 constant MIN_PRICE = 0.01 ether; // 0.01 Token (18 decimals)
    uint256 constant MAX_PRICE = 10000 ether; // 10000 Token (18 decimals)
    
    
    function setUp() public {
        vm.startPrank(owner);

        // 需要测试的合约
        token = new ownerERC20Permit();
        nft = new ERC721("AA", "AA",  "AAURL");
        whitelist = new WhitelistManager();
        market = new NFTMarket( address(token), address(whitelist) );
        permit2 = new Permit2();
        tokenBank = new TokenBank( address(token), address(permit2));

        // 设置白名单
        whitelist.addToWhitelist(buyer);
        
        vm.stopPrank();
    }

    // 测试TokenBank的permitDeposit功能
    function testTokenBank_permitDeposit() public {
        uint256 amount = 1000 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;

        // 设置购买者有 token 代币
        vm.startPrank(owner);
        token.transfer(buyer, amount);
        vm.stopPrank();

        // 构建数据：域 + 消息
        vm.startPrank(buyer);
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 messageHash = keccak256(abi.encode( 
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), // 代币合约结构：即token的_PERMIT_TYPEHASH
            buyer, 
            address(tokenBank),
            amount,
            token.nonces(buyer),
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, messageHash));

        // 签名得到 v r s
        (uint8 v, bytes32 r, bytes32 s) = vm.sign( 1, hash);
        // 存款
        tokenBank.permitDeposit(amount, deadline, v, r, s);
        vm.stopPrank();

        // 验证存款
        assertEq(tokenBank.getdepositBalance(buyer), amount);
        assertEq(token.balanceOf(address(tokenBank)), amount);
    }

    // 测试购买NFT(Token支付),并且非白名单用户无法购买
    function testBuyNFT_Token_PermitBuy() public {
        // 上架 + 给购买者设置代币
        vm.startPrank(owner);
        uint256 tokenId = 1;
        uint256 price = 1000e18;
        uint256 ownerInitialBalance = token.balanceOf(owner);
        ownerInitialBalance =  ownerInitialBalance - price;
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft), tokenId, price);
        token.transfer(buyer, price);  // 购买者有 token 代币
        vm.stopPrank();
        
        // 构建数据：域 + 消息
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 messageHash = keccak256(abi.encode( 
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), // 代币合约结构：即token的_PERMIT_TYPEHASH
            buyer, 
            address(market),
            price,
            token.nonces(buyer),
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1,hash);

        // 购买 
        vm.startPrank(buyer);
        token.approve( address(market), price);
        market.permitBuy(address(nft), tokenId, price, deadline , v, r, s);
        vm.stopPrank();

        // 验证资金情况, owner.balance初始资金为0(因为还没配置钱)
        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(token.balanceOf(owner), ownerInitialBalance + price);
        // 验证上架信息已清除
        (address ownerAddr, uint256 list_price ) = market.listings(address(nft), tokenId);
        assertEq(ownerAddr, address(0));
        assertEq(list_price, 0);
    }

    // 测试TokenBank中Permit2方法
    function testTokenBank_permit2() public {
        // 获取参数
        vm.startPrank(owner);
        uint256 amount = 1000 * 10**18;
        uint256 nonce =  token.nonces(owner);
        uint256 deadline = block.timestamp + 1 hours;
        token.transfer(buyer, amount);
        // uint256 total = token.balanceOf(owner);
        token.approve(address(permit2), token.balanceOf(owner));
        // permit2.approveToken(owner,true);
        vm.stopPrank();

        // buyer 拿到私钥要求转账 
        vm.startPrank(owner);
        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("Permit2Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("Permit2")),
            keccak256(bytes("1")),
            block.chainid,
            address(permit2)
        ));
        bytes32 messageHash = keccak256(abi.encode( 
            keccak256("permit2TransferFrom(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), // 代币合约结构：即token的_PERMIT_TYPEHASH
            owner,   // 必须与签名者私钥对应
            address(tokenBank),
            amount,
            nonce,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, hash);

        tokenBank.depositWithPermit2( amount, nonce, deadline, v, r, s);
        vm.stopPrank();

        // 验证存款
        assertEq(tokenBank.getdepositBalance(owner), amount);
        assertEq(token.balanceOf(address(tokenBank)), amount);
        // console.log("owner approved permit2 allowance:", total);
        // assertEq(token.allowance(address(owner), address(permit2)), total);
    }


}