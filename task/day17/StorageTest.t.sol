// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./StorageTest.sol";

contract StorageTestTest is Test {
    StorageTest public storageTest;
    
    function setUp() public {
        storageTest = new StorageTest();
    }
    
    function testGetStorageData() public {
        // 获取存储槽0的原始数据
        bytes32 slot0 = storageTest.getStorageSlot0();
        
        // 获取字符串的十六进制表示
        string memory nameHex = storageTest.getNameHex();
        
        // 获取字符串长度
        uint256 length = storageTest.getNameLength();
        
        // 打印结果
        console.log("String length:", length);
        console.log("Storage slot 0 (hex):");
        console.logBytes32(slot0);
        console.log("Name as hex string:", nameHex);
        
        // 验证存储槽0包含字符串长度和内容
        // 对于短字符串（<=31字节），存储格式为：
        // 最后1字节：长度 * 2
        // 前31字节：字符串内容（左对齐）
        
        uint8 storedLength = uint8(slot0[31]);
        console.log("Stored length (bytes):", storedLength / 2);
        
        // 提取字符串内容
        bytes memory content = new bytes(storedLength / 2);
        for (uint i = 0; i < storedLength / 2; i++) {
            content[i] = slot0[i];
        }
        console.log("Extracted content:");
        console.logString(string(content));
    }
}
