// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import { NFTMarket } from "../task/day18/AirdopMerkleNFTMarket.sol";
import "../task/day18/ownerERC20Permit.sol";
import "../task/day18/ownerNFT.sol";

contract AirdopMerkleNFTMarketTest is Test {
    NFTMarket public market;
    ownerERC20Permit public token;
    ERC721 public nft;

    address owner = makeAddr("alice");
    // address whiteUser = address(1);
    address whiteUser = vm.addr(1);
    address nowhiteUser = makeAddr("nowhiteUser");

    bytes32 public rootHash;
    bytes32[] public merkleProof;

    function setUp() public {
        vm.startPrank(owner);
        token = new ownerERC20Permit();    
        nft = new ERC721("AA", "AA", "http://AA");

        // 白名单
        bytes32[] memory whiteLists = new bytes32[](1);  // 白名单必须有一个用户，因为空树（0个叶子节点）无法生成有效的 Merkle Root 和 Proof
        whiteLists[0] = keccak256(abi.encodePacked(whiteUser));
        rootHash = _rootHash(whiteLists);
        merkleProof = _merkleProof(whiteLists, 0);

        // 部署NFT市场
        market = new NFTMarket(address(token), rootHash);

        vm.stopPrank();

    }

    // 生产根hash
    function _rootHash(bytes32[] memory whiteList) public returns (bytes32) {
       if (whiteList.length == 0) return bytes32(0);
        if (whiteList.length == 1) return whiteList[0];
        
        bytes32[] memory nextLevel = new bytes32[]((whiteList.length + 1) / 2);
        
        for (uint256 i = 0; i < nextLevel.length; i++) {
            uint256 i2 = i * 2;
            if (i2 + 1 < whiteList.length) {
                nextLevel[i] = keccak256(abi.encodePacked(
                    whiteList[i2] < whiteList[i2 + 1] ? whiteList[i2] : whiteList[i2 + 1],
                    whiteList[i2] < whiteList[i2 + 1] ? whiteList[i2 + 1] : whiteList[i2]
                ));
            } else {
                nextLevel[i] = whiteList[i2];
            }
        }
        
        return _rootHash(nextLevel);
    }

    // 生产所有根节点的hash
    function _merkleProof(bytes32[] memory whiteList, uint256 index) public returns (bytes32[] memory) {
        if (whiteList.length <= 1) return new bytes32[](0);
        
        bytes32[] memory proof = new bytes32[](1);
        if (index % 2 == 0) {
            if (index + 1 < whiteList.length) {
                proof[0] = whiteList[index + 1];
            } else {
                proof[0] = whiteList[index];
            }
        } else {
            proof[0] = whiteList[index - 1];
        }
        
        return proof;
    }

    // 测试是否属于白名单 + 并用优惠价格购买NFT
    function test_User_claimNFT() public {
        // 上架
        vm.startPrank(owner);
        uint256 nftId = 1;
        uint256 price = 1000e18;
        nft._mint(nftId, owner);
        nft.approve(address(market), nftId);
        uint256 discountPrice = price / 2;
        market.list(address(nft), nftId, price);
        token.transfer( whiteUser, price );  
        uint256 ownerBalance = token.balanceOf(owner);
        vm.stopPrank();

        // 购买 
        vm.startPrank(whiteUser);
        token.approve(address(market), discountPrice);
        market.claimNFT(address(nft), nftId, address(token), merkleProof);
        vm.stopPrank();

        // 检查资产转移
        assertEq(token.balanceOf(whiteUser), price-discountPrice);
        assertEq(token.balanceOf(owner), ownerBalance+discountPrice);
        assertEq(nft.ownerOf(nftId), whiteUser);
    }

    // 测试使用multicall组合调用permitPrePay和claimNFT
    function testMulticallPermitAndClaim() public{
        // 上架
        vm.startPrank(owner);
        uint256 nftId = 1;
        uint256 price = 1000e18;
        nft._mint(nftId, owner);
        nft.approve(address(market), nftId);
        uint256 discountPrice = price / 2;
        market.list(address(nft), nftId, price);
        token.transfer( whiteUser, price );  
        uint256 ownerBalance = token.balanceOf(owner);
        vm.stopPrank();

        // 签名:构建EIP712结构化数据请求
        vm.startPrank(whiteUser);
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 domainmessage = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
            whiteUser, 
            address(market),
            discountPrice,
            token.nonces(whiteUser),
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked( "\x19\x01", domainSeparator, domainmessage ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);

        // 模拟签名
        // market.permitPrePay(discountPrice, deadline, v, r, s);

        // 构建两个请求
        NFTMarket.Call[] memory calls = new NFTMarket.Call[](2);
        calls[0].target = address(market);
        calls[0].callData = abi.encodeWithSelector(
            // bytes4(keccak256("permitPrePay(uint256,uint256,uint8,uint32,uint32)")), 
            market.permitPrePay.selector,  // 等效上面bytes4
            discountPrice,
            deadline,
            v,
            r,
            s
        );

        // token.approve(address(market), discountPrice);
        calls[1].target = address(market);
        calls[1].callData = abi.encodeWithSelector(
            bytes4(keccak256("claimNFT(address,uint256,address,bytes32[])")), 
            // market.claimNFT.selector,  // 等效上面bytes4
            address(nft),
            nftId,
            token,
            merkleProof
        );

        bytes[] memory results = market.multicall(calls);
        vm.stopPrank();

        // 检查资产转移
        assertEq(token.balanceOf(whiteUser), price-discountPrice);
        assertEq(token.balanceOf(owner), ownerBalance+discountPrice);
        assertEq(nft.ownerOf(nftId), whiteUser);
        (address ownerAddr, uint256 list_price ) = market.listings(address(nft), nftId);
         assertEq(ownerAddr, address(0));
        assertEq(list_price, 0);



    }
    

}