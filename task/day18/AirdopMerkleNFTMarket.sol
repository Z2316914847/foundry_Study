// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ownerERC20Permit.sol";
import "./ownerNFT.sol";
import { console } from "forge-std/Test.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract NFTMarket{

    bytes32 public merkleRoot;
    ownerERC20Permit public token_permit;

    constructor( address tokenAddress, bytes32 root) {
        token_permit = ownerERC20Permit(tokenAddress);
        merkleRoot = root;
    }
    
    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed( address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price );
    event Purchased( address indexed nftContract, uint256 indexed tokenId, address buyer, address seller, uint256 price );
    event Canceled(address indexed nftContract, uint256 indexed tokenId);
    event Claimed(address indexed account, uint256 amount);


    // 上架判断：该NFT是否已经上架，价格必须大于0
    // 参数：nftContract是NFT合约地址(根据NFT特有地址，调用NFT合约中的方法)， tokenId：NFT唯一标识， price：设置NFT上架价格
    function list(address nftContract, uint256 tokenId, uint256 price) public {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender && price > 0, "Not NFT owner or price must be > 0");
        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });
        emit Listed(nftContract, tokenId, msg.sender, price);
    }

    function buyNFT(address nftContract, uint256 tokenId) public payable {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller != address(0) && msg.value >= listing.price && listing.seller != msg.sender, "tokenId not exist or The purchase price must be greater than the set price or Buyer address not is owner address" );

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

        // 从买家转移代币到卖家
        // bool success = BaseERC20(token).transferFrom( msg.sender,listing.seller, amount );
        require(ownerERC20Permit(token).transferFrom( msg.sender,listing.seller, amount ), "Token transfer failed");

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

    // 获取NFT上架信息
    function getListings(address nftContract, uint256 tokenId) public view returns (address seller, uint256 price) {
        Listing storage listing = listings[nftContract][tokenId];
        seller = listing.seller;
        price = listing.price;
        return (seller, price);
    }

    // 封装multicall
    // 参数：data：需要调用的合约地址， callData：需要调用的合约方法
    struct Call {
        address target;
        bytes callData;
    }

    // 授权
    // bytes32[] calldata data：使用这个方式相等于使用openzppelin的Multicall.sol，它里面还要经过一段处理，麻烦。所在这里借鉴Multicall3.sol
    function multicall(Call[] calldata data) public returns(bytes[] memory results){
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++){
            (bool success, bytes memory result) = data[i].target.delegatecall(data[i].callData);
            require(success, "Call failed");
            results[i] = result;
        }
        return results;
    }

    // 签名授权 - msg.sender把代币授权给 market合约
    function permitPrePay( uint256 amount,  uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        token_permit.permit(msg.sender, address(this), amount, deadline, v, r, s);
    }

    // 白名单用户购买NFT：验证是否在白名单 ＋ 购买NFT
    // 参数：nftContract:NFT合约地址，NFTId：NFT唯一标识， merkleProof：所有白名单hash
    function claimNFT(address nftContract, uint256 nftId , address token, bytes32[] calldata merkleProof) public {
        console.log("==================================================================");
        Listing storage listing = listings[nftContract][nftId];
        require(listing.seller != address(0) && token_permit.balanceOf(msg.sender) >= listing.price && listing.seller != msg.sender, "nftId not exist or The purchase price must be greater than the set price or Buyer address not is owner address" );
         // 验证用户是否在白名单中
        require(isWhitelisted(msg.sender, merkleProof), "AirdopMerkleNFTMarket: not in whitelist");
        
        // 判断用户在bank钱包是否有足够的Token
        uint256 discountedPrice = listing.price / 2;
        require(token_permit.balanceOf(msg.sender) >= discountedPrice, "AirdopMerkleNFTMarket: insufficient token balance");

        // 发钱
        require(ownerERC20Permit(token).transferFrom(msg.sender, listing.seller, discountedPrice)," AirdopMerkleNFTMarket: token transfer failed ");

         // 转移NFT所有权
        IERC721(nftContract).transferFrom(address(this), msg.sender, nftId);

        // 清除上架信息
        delete listings[nftContract][nftId];

        emit Purchased(nftContract, nftId, msg.sender, listing.seller, listing.price);

    }

    // 验证地址是否在白名单中 - 不理解 ： 可以去看nftMaket - 去中心化数字藏品项目描述，里面有介绍 ，不知道在哪可以联系我QQ:2844847674
    // 参数：user：用户地址，proof：提供从叶子节点到根节点的路径上缺失的兄弟哈希值。
    function isWhitelisted(address user, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // 检查计算出的哈希值是否与默克尔根匹配
        return computedHash == merkleRoot;
    }


}