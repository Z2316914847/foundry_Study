// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {Test, console} from "forge-std/Test.sol";

contract esRNT {
    struct LockInfo{
        address user;
        uint64 startTime; 
        uint256 amount;
    }  // LockInfo 占 2个 slot
    // 要读取这个数据，首先明白这是一个不定长数组，slot 0 用来存放数组长度，数组开始位置：keccak256(solt 0)
    LockInfo[] private _locks; // 64*11=688 bytes

    constructor() { 
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(address(uint160(i+1)), uint64(block.timestamp*2-i), 1e18*(i+1)));
        }
    }
}