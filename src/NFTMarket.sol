// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./BaseToken.sol";
import "./ownerNFT.sol";
import { console } from "forge-std/Test.sol";

contract NFTMarket{
    // 平台手续费 (2%)
    // uint256 public constant PLATFORM_FEE_PERCENT = 2;
    // address public feeRecipient;

    // constructor(address _feeRecipient) {
    //     feeRecipient = _feeRecipient;
    // }

     constructor() {
    //     feeRecipient = _feeRecipient;
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
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(price > 0, "Price must be > 0");
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
        require(listing.seller != address(0), "tokenId not exist" );
        require(msg.value >= listing.price, "The purchase price must be greater than the set price" );
        require(listing.seller != msg.sender, "Buyer address not is owner address" );
        
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
        require(listing.seller != address(0), "tokenId not exist" );
        require(amount >= listing.price, "Insufficient payment");

        // 从买家转移代币到卖家
        bool success = BaseERC20(token).transferFrom( msg.sender,listing.seller, amount );
        require(success, "Token transfer failed");

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

    // 欠实现bank获取token：实现tokensReceived接口，处理通过transferWithCallback接收到的代币
    // function tokensReceived(address from, uint256 amount, bytes calldata data) public returns (bool) {
    //     // 检查调用者是否为支付代币合约
    //     require(msg.sender == address(paymentToken), "NFTMarket: caller is not the payment token contract");
        
    //     // 解析附加数据，获取listingId
    //     require(data.length == 32, "NFTMarket: invalid data length");
    //     uint256 listingId = abi.decode(data, (uint256));
        
    //     // 检查上架信息是否存在且处于活跃状态
    //     Listing storage listing = listings[listingId];
    //     require(listing.isActive, "NFTMarket: listing is not active");
        
    //     // 检查转入的代币数量是否等于NFT价格
    //     require(amount == listing.price, "NFTMarket: incorrect payment amount");
        
    //     // 将上架信息标记为非活跃
    //     listing.isActive = false;
        
    //     // 将代币转给卖家
    //     bool success = paymentToken.transfer(listing.seller, amount);
    //     require(success, "NFTMarket: token transfer to seller failed");
        
    //     // 处理NFT转移（卖家 -> 买家）
    //     IERC721(listing.nftContract).transferFrom(listing.seller, from, listing.tokenId);
        
    //     // 触发NFT售出事件
    //     emit NFTSold(listingId, from, listing.seller, listing.nftContract, listing.tokenId, amount);
        
    //     return true;
    // }
    
    // 欠实现bank获取NFT：使用transferWithCallbackAndData购买NFT的辅助函数
    // function buyNFTWithCallback(uint256 _listingId) public  {
    //     // 检查上架信息是否存在且处于活跃状态
    //     Listing storage listing = listings[_listingId];
    //     require(listing.isActive, "NFTMarket: listing is not active");
        
    //     // 检查买家是否有足够的代币
    //     require(paymentToken.balanceOf(msg.sender) >= listing.price, "NFTMarket: insufficient token balance");
        
    //     // 编码listingId作为附加数据
    //     bytes memory data = abi.encode(_listingId);
        
    //     // 调用transferWithCallbackAndData函数，将代币转给市场合约并附带listingId数据
    //     bool success = paymentToken.transferWithCallbackAndData(address(this), listing.price, data);
    //     require(success, "NFTMarket: token transfer with callback failed");
    // }

}