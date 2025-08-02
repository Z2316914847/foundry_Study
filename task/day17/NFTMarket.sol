// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./BaseToken.sol";
import "./ownerNFT.sol";
import { console } from "forge-std/Test.sol";

contract NFTMarket{

    constructor() {
    }
    
    // 上架信息 seller买家地址，priceNFT价格
    struct Listing {
        address seller;
        uint256 price;
    }

    // NFT合约地址 => TokenID => 上架信息。这个结构可以存任何类型合约 NFT
    mapping(address => mapping(uint256 => Listing)) public listings;

    // 上架和购买，取消上架事件
    event Listed( address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price );
    event Purchased( address indexed nftContract, uint256 indexed tokenId, address buyer, address seller, uint256 price );
    event Canceled(address indexed nftContract, uint256 indexed tokenId);


    // 上架判断：该NFT是否已经上架，价格必须大于0
    // 参数：nftContract是NFT合约地址(根据NFT特有地址，调用NFT合约中的方法)， tokenId：NFT唯一标识， price：设置NFT上架价格
    function list(address nftContract, uint256 tokenId, uint256 price) public {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender && price > 0, "Not NFT owner or price must be > 0");
        // require(price > 0, "Price must be > 0");
        // nft.approve(address(this), tokenId);  //Market上架时自己调用授权方法/用户自己调用，这里推荐用户自己调用授权方法，然后在上架NFT
        // 转移NFT到合约（需先调用NFT合约的approve）
        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });
        emit Listed(nftContract, tokenId, msg.sender, price);
    }

    // 购买NFT(ETH支付)
    // 参数：
    function buyNFT(address nftContract, uint256 tokenId) public payable {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller != address(0) && msg.value >= listing.price && listing.seller != msg.sender, "tokenId not exist or The purchase price must be greater than the set price or Buyer address not is owner address" );
        // require(msg.value >= listing.price, "The purchase price must be greater than the set price" );
        // require(listing.seller != msg.sender, "Buyer address not is owner address" );
        
        // 计算手续费
        // uint256 fee = (listing.price * PLATFORM_FEE_PERCENT) / 100;
        // uint256 sellerProceeds = listing.price - fee;

        uint256 sellerProceeds = listing.price;

        // 发钱
        // payable(feeRecipient).transfer(fee);
        payable(listing.seller).transfer(sellerProceeds);

         // 转移NFT所有权
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        // 清除上架信息
        delete listings[nftContract][tokenId];

        emit Purchased(nftContract, tokenId, msg.sender, listing.seller, listing.price);
        // 购买完成事件
    }

    // 购买NFT（ERC20支付）
    function buyNFTWith_Token( address nftContract, uint256 tokenId, address token, uint256 amount) public payable {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller != address(0) && amount >= listing.price, "tokenId not exist or Insufficient payment" );
        // require(amount >= listing.price, "Insufficient payment");

        // 从买家转移代币到卖家
        // bool success = BaseERC20(token).transferFrom( msg.sender,listing.seller, amount );
        require(BaseERC20(token).transferFrom( msg.sender,listing.seller, amount ), "Token transfer failed");

        // 转移 NFT 所有权
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        // 清除上架信息
        delete listings[nftContract][tokenId];

        emit Purchased(nftContract, tokenId, msg.sender, listing.seller, amount);
    }

    // 取消上架
    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller == msg.sender, "Not seller");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        delete listings[nftContract][tokenId];

        emit Canceled(nftContract, tokenId);
    }

}