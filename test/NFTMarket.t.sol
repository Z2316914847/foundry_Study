// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import { Test, console } from "forge-std/Test.sol";
import { NFTMarket } from "../src/NFTMarket.sol";
import "../src/BaseToken.sol";
import "../src/ownerNFT.sol";

contract NFTMarketTest is Test{
    
    //   2. 购买NFT测试
    //     成功购买​：验证NFT所有权和代币转账正确
    // ​    失败情况​：
    //       自己购买自己的NFT
    //       重复购买已售出的NFT
    //       支付代币不足
    //       无效购买地址（零地址）
    //   3. 模糊测试
    //       随机生成价格（0.01-10000）和买家地址
    //       验证在各种随机条件下NFT交易的正确性
    //   4. 不可变测试
    //      验证市场合约在任何情况下都不会持有代币
    //      包括正常交易和直接转账给市场合约的情况
    NFTMarket public market;
    BaseERC20 public token;
    ERC721 public nft;

    address owner = makeAddr("alice");
    address buyer = makeAddr("bob");
    address other = makeAddr("tom");

    // 测试参数范围
    uint256 constant MIN_PRICE = 0.01 ether; // 0.01 Token (18 decimals)
    uint256 constant MAX_PRICE = 10000 ether; // 10000 Token (18 decimals)
    
    
    function setUp() public {
        vm.startPrank(owner);
        market = new NFTMarket();
        token = new BaseERC20();
        nft = new ERC721("AA", "AA",  "AAURL");
        vm.stopPrank();
    }

    // NFT 上架成功（ETH支付）
    event Listed( address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price );
    function testListNFT_Success() public {
        vm.startPrank(owner);

        // 设置NFT价格
        uint256 tokenId = 1;
        uint256 price = 0.1 ether;

        // 铸造NFT
        nft._mint(tokenId, owner);

        // owner地址临时授权给market合约
        nft.approve(address(market), tokenId);

        // 预期接下来的 market.list() 调用会发出一个 Approval 事件。该事件的参数必须是：owner 作为批准人，address(market) 作为被批准人，tokenId 作为被批准的 token ID
        vm.expectEmit(true, true, true, true);
        emit Listed(address(nft), tokenId, address(owner), price);

        market.list(address(nft),tokenId, price);
        vm.stopPrank();

        // 检查上架信息,比较一下是否正确
        (address ownerAddr, uint256 list_price)  = market.listings(address(nft), tokenId);
        assertEq(ownerAddr, owner);
        assertEq(list_price, 0.1 ether);
    }

     // NFT 上架成功（ERC20支付）
    function testListNFT_Success_Token() public {
        vm.startPrank(owner);
        uint256 tokenId = 1;
        uint256 price = 1000e18;
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft), tokenId, price);
        vm.stopPrank();

        // 验证上架状态
        (address ownerAddr, uint256 list_price) = market.listings(address(nft), tokenId);
        assertEq(ownerAddr, owner);
        assertEq(list_price, price);
    }
    // NFT上架失败 —— 非所有者尝试上架
    function testListNFT_Fail_NotOwner() public {
        vm.startPrank(owner);
        uint256 tokenId = 2;
        uint256 price = 0.1 ether;
        
        nft._mint(tokenId, owner);
        vm.stopPrank();
        
        vm.prank(other);
        vm.expectRevert("You are not the owner of the NFT");
        market.list( address(nft), tokenId, price);
    }

    // NFT上架失败 —— 未授权市场合约操作NFT
    function testListNFT_Fail_NotApproved() public {
        uint256 tokenId = 3;
        uint256 price = 0.1 ether;
        
        vm.prank(owner);
        nft._mint(tokenId, owner);
        
        // 不调用approve
        vm.prank(owner);
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        market.list( address(nft), tokenId, price);
    }

    // // NFT上架失败 —— 价格无效
    function testListNFT_Fail_InvalidPrice() public {
        uint256 tokenId = 4;
        uint256 price = 0 ether;
        
        vm.prank(owner);
        nft._mint(tokenId, owner);
        
        vm.prank(owner);
        nft.approve(address(market), tokenId);
        
        vm.prank(owner);
        vm.expectRevert("NFTMarket: price must be greater than zero");
        market.list( address(nft), tokenId, price);
    }

    // 测试购买NFT(ETH支付)
    function testBuyNFT_Success() public {
        // 上架
        vm.startPrank(owner);

        uint256 tokenId = 1;
        uint256 price = 0.2 ether;
        uint256 ownerInitialBalance = owner.balance;
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft),tokenId, price);
        vm.stopPrank();

        // 购买 
        vm.startPrank(buyer);
        vm.deal(buyer, 1 ether);
        // market.buyNFT(address(nft), tokenId);
        market.buyNFT{value: price}(address(nft), tokenId); // 关键：传递 price 作为 msg.value
        vm.stopPrank();

        // 验证资金情况, owner.balance初始资金为0(因为还没配置钱)
        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(owner.balance, ownerInitialBalance + price);

        // 验证上架信息已清除
        (address ownerAddr, uint256 list_price ) = market.listings(address(nft), tokenId);
        assertEq(ownerAddr, address(0));
        assertEq(list_price, 0);
    }

     // 测试购买NFT(Token支付)
    function testBuyNFT_Success_Token() public {
        // 上架
        vm.startPrank(owner);
        uint256 tokenId = 1;
        uint256 price = 1000e18;
        uint256 ownerInitialBalance = token.balanceOf(owner);
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft), tokenId, price);
        vm.stopPrank();

        // 购买 
        vm.startPrank(buyer);
        deal(address(token), buyer, 10000e18);  // 重置RERC20的余额 绕过同token代币说有者（代币总量在增加）
        token.approve( address(market), price);
        market.buyNFTWith_Token(address(nft), tokenId, address(token), price);
        vm.stopPrank();

        // 验证资金情况, owner.balance初始资金为0(因为还没配置钱)
        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(token.balanceOf(owner), ownerInitialBalance + price);

        // 验证上架信息已清除
        (address ownerAddr, uint256 list_price ) = market.listings(address(nft), tokenId);
        assertEq(ownerAddr, address(0));
        assertEq(list_price, 0);
    }

    // 测试购买NFT - 自己购买自己的NFT
    function testBuyNFT_Fail_BuyOwnNFT() public {
        vm.startPrank(owner);
        uint256 tokenId = 1;
        uint256 price = 0.2 ether;
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft),tokenId, price);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.deal(owner, 1 ether);
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        market.buyNFT{value: price}(address(nft), tokenId); // 关键：传递 price 作为 msg.value
        vm.stopPrank();
    }

    // 测试购买NFT - 重复购买已售出的NFT
    function testBuyNFT_Fail_AlreadySold() public {
         vm.startPrank(owner);

        uint256 tokenId = 1;
        uint256 price = 0.2 ether;
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft),tokenId, price);
        vm.stopPrank();

        // 购买 
        vm.startPrank(buyer);
        vm.deal(buyer, 1 ether);
        // market.buyNFT(address(nft), tokenId);
        market.buyNFT{value: price}(address(nft), tokenId); // 关键：传递 price 作为 msg.value
        vm.stopPrank();

        // 购买 
        vm.startPrank(other);
        vm.deal(other, 1 ether);
        vm.expectRevert("Repeat purchases are not supported");
        market.buyNFT{value: price}(address(nft), tokenId); // 关键：传递 price 作为 msg.value
        vm.stopPrank();
    }
    // 测试购买NFT - 买家只能出价 NFT设定的价格
    function testBuyNFT_Fail_InsufficientPayment() public {
        vm.startPrank(owner);
        uint256 tokenId = 1;
        uint256 price = 0.2 ether;
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft),tokenId, price);
        vm.stopPrank();
        
         // 2. 买家尝试支付不足金额（应失败）
        vm.startPrank(buyer);
        vm.deal(buyer, 1 ether);
        uint256 lowPayment = price - 0.1 ether; /// 低于设置的价格
        market.buyNFT{value: lowPayment}(address(nft), tokenId);
        vm.stopPrank();
    }

    // 测试购买NFT - 无效购买地址（零地址）
    function testBuyNFT_Fail_InvalidAddress() public {
        vm.startPrank(owner);
        uint256 tokenId = 1;
        uint256 price = 0.2 ether;
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft),tokenId, price);
        vm.stopPrank();
        
        vm.startPrank(buyer);
        vm.deal(buyer, 1 ether);
        market.buyNFT{value: price}(address(nft), tokenId+1);
        vm.stopPrank();
    }

    // 模糊测试 
    // priceRaw: 随机生成的价格, buyerAddr: 随机生成的买家地址
    function testFuzz_RandomPriceAndBuyer(uint256 priceRaw, address buyerAddr) public {
        // 1.priceRaw价格范围设置：minprice(0.01) - mzxprice(10000) Token (18 decimals)
        uint256 price = bound(
            priceRaw, 
            MIN_PRICE, 
            MAX_PRICE 
        );
        uint256 ownerInitialBalance = token.balanceOf(owner);

        // 2限制价格范围在 0.01 - 10000 之间、排除零地址和合约地址、排除owner地址
        vm.assume(price >= 1 && price <= 10000 * 1e18);
        vm.assume(buyerAddr != address(0) && buyerAddr.code.length == 0);
        vm.assume(buyerAddr != owner);
        
        // 3.上架NFT
        vm.startPrank(owner);
        uint256 tokenId = 1;
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft),tokenId, price);
        vm.stopPrank();

        // 4. 准备买家
        vm.startPrank(buyer);
        uint256 buyerBalance = price * 2;   // 分配足够代币给买家（价格的两倍）
        deal(address(token), buyer, buyerBalance);
        token.approve(address(market), price);
        market.buyNFTWith_Token( address(nft), tokenId, address(token), price );
        vm.stopPrank();

         // 5. 验证结果
        // NFT所有权转移
        assertEq(nft.ownerOf(tokenId), buyer, "NFT should be transferred to buyer");
        uint256 expectedSellerBalance = ownerInitialBalance + price;
        assertEq(token.balanceOf(owner), expectedSellerBalance, "Seller should receive payment" );
        uint256 expectedBuyerBalance = buyerBalance - price;
        assertEq( token.balanceOf(buyer), expectedBuyerBalance, "Buyer balance should decrease by price");
        
        //上架信息清除
        (address seller, uint256 list_Price) = market.listings(address(nft), tokenId);
        assertEq(seller, address(0), "Listing should be cleared");
        assertEq(list_Price, 0, "Listing price should be reset");
        
    }

     // 不可变测试：市场合约不应持有任何Token
    function testInvariant_MarketNeverHoldsTokens() public {
        // 上架
        vm.startPrank(owner);
        uint256 tokenId = 1;
        uint256 price = 1000e18;
        uint256 ownerInitialBalance = token.balanceOf(owner);
        nft._mint(tokenId, owner);
        nft.approve(address(market), tokenId);
        market.list(address(nft), tokenId, price);
        vm.stopPrank();
         
        // 购买前检查
        assertEq(token.balanceOf(address(market)), 0);
        // 执行购买
        vm.startPrank(buyer);
        deal(address(token), buyer, 10000e18);  // 重置RERC20的余额 绕过同token代币说有者（代币总量在增加）
        token.approve( address(market), price);
        market.buyNFTWith_Token(address(nft), tokenId, address(token), price);
        vm.stopPrank();
        
        // 购买后检查
        assertEq(token.balanceOf(address(market)), 0);
        
        // 尝试直接转账给市场合约, 失败(因为basetoken不支持转账给合约,只支持转给不同用户)
        vm.prank(owner);
        vm.expectRevert("ERC20: transferTo non contract");   // 是背后被捕获
        token.transfer(address(market), 100);
        
        // 验证市场合约无法保留代币
        assertEq(token.balanceOf(address(market)), 0);
    }

}