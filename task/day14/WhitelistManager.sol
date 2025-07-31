// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

// 白名单
contract WhitelistManager {
    address public owner;
    mapping(address => bool) public whitelist;
    
    event WhitelistAdded(address indexed user);
    event WhitelistRemoved(address indexed user);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    function addToWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
        emit WhitelistAdded(user);
    }
    
    function removeFromWhitelist(address user) public onlyOwner {
        whitelist[user] = false;
        emit WhitelistRemoved(user);
    }
    
    function isWhitelisted(address user) public view returns (bool) {
        return whitelist[user];
    }
} 