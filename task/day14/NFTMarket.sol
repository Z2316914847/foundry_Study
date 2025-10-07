// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ownerERC20Permit.sol";
import "./ownerNFT.sol";           // 这个合约中有IERC721接口
import "./WhitelistManager.sol";
import { console } from "forge-std/Test.sol";

contract NFTMarket{
    // 平台手续费 (2%)
    // uint256 public constant PLATFORM_FEE_PERCENT = 2;
    // address public feeRecipient;

    // constructor(address _feeRecipient) {
    //     feeRecipient = _feeRecipient;
    // }
    ownerERC20Permit public myToken;
    WhitelistManager public whitelistManager;

    // NFT合约 白名单

    // NFT合约 黑名单

    constructor(address _myToken, address _whitelistManager) {
        myToken = ownerERC20Permit(_myToken);
        whitelistManager = WhitelistManager(_whitelistManager);
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
        
        // 这里可以增加一个功能：只有白名单的NFT合约中的NFT才能上架 

        // 其实获得NFT授权的所有人，也可以上架NFT，但是这里为了简化，只允许NFT所有者可以上架NFT
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

        // 发钱：
        // 注意：有一个问题：假如代币转移成功，但是NFT转移发生失败，那么买家会损失代币。可以将NFT转移放到转移代币前面（
        //   这里有个问题：假如买家拿到NFT后，不给用户转ETH咋办（实现原理：买家是恶意合约，在接受NFT到后， 恶意合约tokensReceived方法，
        //   而已合约在tokensReceived中回调Market合约中的取消代币授权，就实现了攻击目的）。 解决方案：Market实现一个重入锁，让攻击者无法取消授权 ）
        // 因为 ETH 转移是原生操作，不属于合约状态的一部分 ，revert无法回滚。ERC20是合约状态的一部分，revert可以回滚。
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
    // 这里有一个参数：token：代币合约地址，说明支持任意token购买NFT，但是我的本意只有特定Token能买NFT
    function buyNFTWith_Token( address nftContract, uint256 tokenId, address token, uint256 amount) public payable {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller != address(0), "tokenId not exist" );
        require(amount >= listing.price, "Insufficient payment");

        // 从买家转移代币到卖家
        bool success = ownerERC20Permit(token).transferFrom( msg.sender,listing.seller, amount );
        require(success, "Token transfer failed");

        // 转移 NFT 所有权
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        // 清除上架信息
        delete listings[nftContract][tokenId];

        emit Purchased(nftContract, tokenId, msg.sender, listing.seller, amount);
    }

    // 实现只有离线授权的白名单地址才可以购买 NFT 的方法
    function permitBuy( address nftContract, uint256 tokenId, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) public {
        // 检查用户是否在白名单中
        require(whitelistManager.isWhitelisted(msg.sender), "User not in whitelist");
        
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller != address(0), "tokenId not exist");
        require(amount >= listing.price, "Insufficient payment");
        
        // 使用permit授权
        myToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        
        // 从买家转移代币到卖家
        bool success = myToken.transferFrom(msg.sender, listing.seller, amount);
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
        delete listings[nftContract][tokenId];   // 这行代码会将 listings[nftContract][tokenId] 的值重置为默认值。并且mapping中的value存储槽也会被释放

        emit Canceled(nftContract, tokenId);
    }

    // 这里可以增加一个功能：管理员 验证某个 NFT 合约是否支持ERC721接口

    // 这里可以增加一个功能：管理员 将某个 NFT 合约加入白名单

    // 这里可以增加一个功能：管理员 将某个 NFT 合约假如黑名单

    // 这里可以增加一个功能：管理员 将某个 NFT 合约 移除 白名单

    // 这里可以增加一个功能：管理员 将某个 NFT 合约 移除 黑名单

    

    // 实现tokensReceived接口，处理通过transferWithCallback接收到的代币
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
    
    // 推荐使用 回测方法 购买 NFT
    // function buyNFTWithCallback(uint256 _listingId) public  {
    //     // 检查上架信息是否存在且处于活跃状态
    //     Listing storage listing = listings[_listingId];
    //     require(listing.isActive, "NFTMarket: listing is not active");
        
    //     // 检查买家是否有足够的代币
    //     require(paymentToken.balanceOf(msg.sender) >= listing.price, "NFTMarket: insufficient token balance");
        
    //     // 编码listingId作为附加数据
    //     bytes memory data = abi.encode(_listingId);
        
    //     // 调用代币中的transferWithCallbackAndData函数，将代币转给市场合约并附带listingId数据
    //     bool success = paymentToken.transferWithCallbackAndData(address(this), listing.price, data);
    //     require(success, "NFTMarket: token transfer with callback failed");
    // }

}