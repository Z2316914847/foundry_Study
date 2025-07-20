// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./BaseToken.sol";
import "./ownerNFT.sol";

contract NFTMarket{
    BaseERC20 public token;
    ERC721 public nft;

    constructor(string memory _name, string memory _symbol, string memory _baseURI){
        token = new BaseERC20();
        nft = new ERC721(_name, _symbol, _baseURI);
    }
    
    struct nftInfo{
        uint256 tokenId;
        uint256 price;  
        address sellAddress;  // 卖家地址
        address nftContract;  // NFT合约地址
        bool isActive;       // 是否处于活跃状态
    }

    mapping(uint256 => nftInfo) public nftListInfo;

    function list(uint256 tokenId, uint256 price) public {
        // market需不需要获得授权、这里时获取授权，合约最下面由上架时Market不获取授权
        require(nft.ownerOf(tokenId) != address(0), "tokenId not exist" );
        require(nft.ownerOf(tokenId) == msg.sender, "You are not the owner of the NFT");
        require(price > 0, "NFTMarket: price must be greater than zero");

        // 将nft临时授权给market合约
        nft.approve(address(this), tokenId);
        nftListInfo[tokenId] = nftInfo(tokenId, price, msg.sender, address(nft), true);
        // nftListInfo[tokenId] = nftInfo({tokenId, price, msg.sender, address(nft), true});


        // 上架事件
    }

    function buyNFT(address buyAddress, uint256 price, uint256 tokenId) public {
        // 接受地址部位空，价格是否合适
        require(nftListInfo[tokenId].sellAddress != address(0), "tokenId not exist" );
        require(nftListInfo[tokenId].price >= price, "The purchase price must be greater than the set price" );
        require(buyAddress!=address(0), "The purchase address cannot be empty");
        //买家在token合约的address减钱，卖家加钱
        token.transfer(nftListInfo[tokenId].sellAddress, price);
        // NFT同理
        nft.safeTransferFrom(nftListInfo[tokenId].sellAddress, buyAddress, tokenId);
        // 购买完成事件
    }

    // 欠实现bank获取token：实现tokensReceived接口，处理通过transferWithCallback接收到的代币
    function tokensReceived(address from, uint256 amount, bytes calldata data) public returns (bool) {
        // // 检查调用者是否为支付代币合约
        // require(msg.sender == address(paymentToken), "NFTMarket: caller is not the payment token contract");
        
        // // 解析附加数据，获取listingId
        // require(data.length == 32, "NFTMarket: invalid data length");
        // uint256 listingId = abi.decode(data, (uint256));
        
        // // 检查上架信息是否存在且处于活跃状态
        // Listing storage listing = listings[listingId];
        // require(listing.isActive, "NFTMarket: listing is not active");
        
        // // 检查转入的代币数量是否等于NFT价格
        // require(amount == listing.price, "NFTMarket: incorrect payment amount");
        
        // // 将上架信息标记为非活跃
        // listing.isActive = false;
        
        // // 将代币转给卖家
        // bool success = paymentToken.transfer(listing.seller, amount);
        // require(success, "NFTMarket: token transfer to seller failed");
        
        // // 处理NFT转移（卖家 -> 买家）
        // IERC721(listing.nftContract).transferFrom(listing.seller, from, listing.tokenId);
        
        // // 触发NFT售出事件
        // emit NFTSold(listingId, from, listing.seller, listing.nftContract, listing.tokenId, amount);
        
        return true;
    }
    
    // 欠实现bank获取NFT：使用transferWithCallbackAndData购买NFT的辅助函数
    function buyNFTWithCallback(uint256 _listingId) public  {
        // // 检查上架信息是否存在且处于活跃状态
        // Listing storage listing = listings[_listingId];
        // require(listing.isActive, "NFTMarket: listing is not active");
        
        // // 检查买家是否有足够的代币
        // require(paymentToken.balanceOf(msg.sender) >= listing.price, "NFTMarket: insufficient token balance");
        
        // // 编码listingId作为附加数据
        // bytes memory data = abi.encode(_listingId);
        
        // // 调用transferWithCallbackAndData函数，将代币转给市场合约并附带listingId数据
        // bool success = paymentToken.transferWithCallbackAndData(address(this), listing.price, data);
        // require(success, "NFTMarket: token transfer with callback failed");
    }

}