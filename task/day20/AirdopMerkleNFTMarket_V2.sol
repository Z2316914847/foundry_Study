// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./ownerERC20Permit.sol";
// import "./ownerNFT.sol";
// import { console } from "forge-std/Test.sol";
// import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
// import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
// import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "./AirdopMerkleNFTMarket_V1.sol";

contract NFTMarketV2 is NFTMarketV1{

    // 可升级合约不需要构造函数参数
    constructor() NFTMarketV1() {}

    function test() public returns(uint256){
        return 10;
    }


    function offlineSignatureList( address nftContract, uint256 tokenId, uint256 price, uint8 v, bytes32 r, bytes32 s ) public {
        
        bytes32 messageHash = keccak256(abi.encodePacked(nftContract, tokenId, price));
        bytes32 sigHash = MHUtils.toEthSignedMessageHash(messageHash);  // 只能以太坊签名,不能是由原始签名,因为合约没有用户私钥,没有私钥便不能完成原始签名        
        address signer = ECDSA.recover(sigHash, v, r, s);  // 等效  address recovered = ecrecover(hash, v, r, s);      

        IERC721 nft = IERC721(nftContract);
        address owner = nft.ownerOf(tokenId);
        require( signer == owner && price > 0, "Invalid signature or price must be > 0");
        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });

        emit Listed(nftContract, tokenId, msg.sender, price);
        
    }

    // 离线签名 上架NFT  tokenId， 价格
    // 参数：nftContract是NFT合约地址(根据NFT特有地址，调用NFT合约中的方法)， tokenId：NFT唯一标识， price：设置NFT上架价格， v,r,s：离线签名参数
    

}