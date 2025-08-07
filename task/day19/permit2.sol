// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ownerERC20Permit.sol";

contract Permit2 {
    // mapping(address => bool) public permits;

    struct PermitTransferFrom {
        ownerERC20Permit token;
        uint256 amount;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    function permit2TransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails memory details,
        address owner1,
        uint8 v, bytes32 r, bytes32 s
    ) public {
        // owner1是否授权代币给 permit2 合约
        // require( permits[owner1], "Permit2:owner1 does not approved the token permit " );
        require( permit.deadline>=block.timestamp, "Permit2: signature expired" );

        // 验证签名有效性
        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("Permit2Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("Permit2")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
        bytes32 messageHash= keccak256(abi.encode(
            keccak256("permit2TransferFrom(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            owner1, 
            details.to, 
            permit.amount,
            permit.token.nonces(owner1), 
            permit.deadline
        ));

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, messageHash));

        address signer = ecrecover(hash, v, r, s);
        require(signer == owner1,"Permit2:Invalid signature");

        // 调用ERC20的transferFrom方法，将amount数量的代币从owner1转移到owner2
        permit.token.transferFrom(owner1, details.to, details.requestedAmount);
    }

    // function approveToken( address owner, bool approved ) public {
    //     permits[owner] = approved;
    // }


    

}

