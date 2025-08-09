// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import { NFTMarketV1 } from "../task/day20/AirdopMerkleNFTMarket_V1.sol";
import { NFTMarketV2 } from "../task/day20/AirdopMerkleNFTMarket_V2.sol";
import { upGradeNFTV1 } from "../task/day20/upGradeNFT_V1.sol";
import { upGradeNFTV2 } from "../task/day20/upGradeNFT_V2.sol";
import "../task/day20/proxyMarket.sol";
import "../task/day20/proxyNFT.sol";

import "../task/day20/ownerERC20Permit.sol";
import "../task/day20/ownerNFT.sol";
import "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import   {MessageHashUtils as MHUtils} from "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";


contract AirdopMerkleNFTMarketTest is Test {
    NFTMarketV1 public market;
    NFTMarketV1 public implementation;
    // ERC1967Proxy public proxy;
    proxyMarket public proxymarket;

    upGradeNFTV1 public nftv1;
    upGradeNFTV1 public nftImplementation;
    proxyNFT public proxynft;

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
        merkleProof = _merkleProof(whiteLists, 0);  // index =0: 获取0叶节点到根节点路径上的直接兄弟节点.   index =1: 获取0叶节点到根节点路径上的直接兄弟节点

        // 这个写法错误，初始化只能由代理合约初始化   这段代码的意思是：直接部署并初始化，如果逻辑合约构造函数没有_disableInitializers();的话，我们能初始化成功，但是这个初始化是由逻辑合约自己初始化，所以他会和代理合约存储布局冲突
        // market = new NFTMarketV1();
        // market.initialize(address(token), rootHash);
        
        // 部署实现合约
        implementation = new NFTMarketV1();  // 单独部署逻辑合约


        // 方法一：部署market代理合约  相当于两个功能：逻辑合约放到代理合约中 + 逻辑合约初始化
        // proxy = new ERC1967Proxy(
        //     address(implementation),  // 合约地址
        //     abi.encodeWithSelector( NFTMarketV1.initialize.selector, address(token), rootHash )   // 初始化数据
        // );

        
        // 方法二：部署market代理合约
        proxymarket = new proxyMarket(
            address(implementation),  // 合约地址
            abi.encodeWithSelector( NFTMarketV1.initialize.selector, address(token), rootHash )
        );
        // 将 proxy 实例装扮成 market 实例，这样就可以通过 market 调用 逻辑合约方法。
        // 起始也可以不用这样写（这样写是为了简单）。 假如不需要这行代码，通过proxy调用逻辑合约方法：address(proxy).call(abi.encodeWithSignature("function()", args))
        // NFTMarketV1(address(proxy)).functionName(args) == market.functionName(args)
        market = NFTMarketV1(address(proxymarket));  // 包装代理合约地址为MyUpgradeableNFT接口


        // nftv1实例
        nftImplementation = new upGradeNFTV1();
        proxynft = new proxyNFT(
            address(nftImplementation),
            abi.encodeWithSelector(upGradeNFTV1.initialize.selector, "AA", "AA")
        );
        nftv1 = upGradeNFTV1(address(proxynft));

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

    // 获取路径上的兄弟节点 -- 这个方法适用于白名单自由一个用户的情况，白名单有多个用户不适应(不会写)
    function _merkleProof(bytes32[] memory whiteList, uint256 index) public pure returns (bytes32[] memory) {
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
        NFTMarketV1.Call[] memory calls = new NFTMarketV1.Call[](2);
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

        market.multicall(calls);
        vm.stopPrank();

        // 检查资产转移
        assertEq(token.balanceOf(whiteUser), price-discountPrice);
        assertEq(token.balanceOf(owner), ownerBalance+discountPrice);
        assertEq(nft.ownerOf(nftId), whiteUser);
        // (address ownerAddr, uint256 list_price ) = market.listings(address(nft), nftId);
        //  assertEq(ownerAddr, address(0));
        // assertEq(list_price, 0);



    }

    // ------------------------NFT升级合约---------------------------------
    function test_upgradeNFT() public {

        vm.startPrank(owner);
        upGradeNFTV2 nftv2 = new upGradeNFTV2();
        nftv1.upgradeToAndCall(address(nftv2),"");

        console.log("New implementation address:", address(nftv2));
        
        // 获取代理合约当前指向的实现合约地址
        address currentImplementation = getImplementationAddress(address(proxynft));
        console.log("Current implementation address:", currentImplementation);

        uint256 result = NFTMarketV2(address(proxynft)).test();
        console.log("v2 method: ",result);
        assertEq(address(market.token_permit()), address(token));

        vm.stopPrank();

    }

    // ------------------------market升级合约---------------------------------

     // 测试不同的签名方式 :原始签名/以太坊签名/紧凑型签名
    function testDifferentSignatureMethods() public {
        vm.startPrank(whiteUser);
        
        uint256 nftId = 1;
        uint256 price = 1e18;
        
        // 原始消息
        bytes32 message = keccak256(abi.encodePacked(address(nft), nftId, price));
        console.log("Original message hash:", uint256(message));
        
        // 方式1: 直接签名原始消息
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(1, message);
        address signer1 = ECDSA.recover(message, v1, r1, s1);
        // address recovered = ecrecover(hash, v, r, s);

        console.log("Method 1 - Direct signature:");
        console.log("  Signer:", signer1);
        console.log("  Expected:", whiteUser);
        console.log("  Match:", signer1 == whiteUser);
        
        // 方式2: 使用以太坊签名前缀
        bytes32 ethMessage = MHUtils.toEthSignedMessageHash(message);
        console.log("Ethereum message hash:", uint256(ethMessage));
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(1, ethMessage);
        address signer2 = ECDSA.recover(ethMessage, v2, r2, s2);
        // address recovered = ecrecover(hash, v, r, s);
        console.log("Method 2 - Ethereum signature:");
        console.log("  Signer:", signer2);
        console.log("  Expected:", whiteUser);
        console.log("  Match:", signer2 == whiteUser);
        
        // 方式3: 使用紧凑型签名格式
        bytes memory signature = abi.encodePacked(r2, s2, v2);
        address signer3 = ECDSA.recover(ethMessage, signature);
        // address recovered = ecrecover(hash, v, r, s);
        console.log("Method 3 - Compact signature:");
        console.log("  Signer:", signer3);
        console.log("  Expected:", whiteUser);
        console.log("  Match:", signer3 == whiteUser);
        
        vm.stopPrank();
    }

    // 调用升级合约中的方法
    function test_offlineSignatureList() public {
        // 升级合约 - 使用upgradeToAndCall方法，传入空数据
        NFTMarketV2 newImplementation = new NFTMarketV2();
        vm.startPrank(owner);
        market.upgradeToAndCall(address(newImplementation), "");
        vm.stopPrank();

        // 上架
        vm.startPrank(whiteUser);
        uint256 nftId = 1;
        uint256 price = 1e18;
        nft._mint(nftId, whiteUser);
        nft.setApprovalForAll(address(market), true);  // 一次性授权所有 NFT 给 market

        // 因为合约里没有用户私钥,只能以太坊签名了
        bytes32 message = keccak256(abi.encodePacked(address(nft) ,nftId, price));
        bytes32 sigHash = MHUtils.toEthSignedMessageHash(message);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, sigHash);     
        NFTMarketV2(address(proxymarket)).offlineSignatureList(address(nft), nftId, price, v, r, s);

        vm.stopPrank();

        // 检查上架信息,比较一下是否正确
        assertEq(nft.owners_(nftId), address(market));
        (address ownerAddr, uint256 list_price)  = market.listings(address(nft), nftId);
        assertEq(ownerAddr, whiteUser);
        assertEq(list_price, price);
    }

    // 测试合约升级功能
    function testUpgradeContract() public {
        
        // 部署新版本的实现合约
        NFTMarketV2 newImplementation = new NFTMarketV2();
        
        // 升级合约 - 使用upgradeToAndCall方法，传入空数据
        vm.startPrank(owner);
        market.upgradeToAndCall(address(newImplementation), "");
        vm.stopPrank();
        console.log("New implementation address:", address(newImplementation));
        
        // 获取代理合约当前指向的实现合约地址
        address currentImplementation = getImplementationAddress(address(market));
        console.log("Current implementation address:", currentImplementation);

        uint256 result = NFTMarketV2(address(proxymarket)).test();
        console.log("v2 method: ",result);
        assertEq(address(market.token_permit()), address(token));
    }

    // 获取代理合约当前指向的实现合约地址
    function getImplementationAddress(address proxy) internal view returns (address) {
        // ERC1967 实现合约存储槽
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 data = vm.load(proxy, slot);
        return address(uint160(uint256(data)));
    }
    

}