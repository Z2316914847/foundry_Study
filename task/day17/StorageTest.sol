// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 获取存储槽0的原始数据
// string数据内容 小于32字节 储存布局方式：数据+长度。之前AI回答是长度＋数据，AI搞错了。
contract StorageTest {
    string public name = "xxxxxxxxxxxx"; // 12 个字符串，占32个字节。   存储布局 = slot0， slot0 = 0x7878787878787878787878780000000000000000000000000000000000000018
    
    // 获取存储槽0的原始数据
    function getStorageSlot0() public view returns (bytes32) {
        bytes32 slot0;
        assembly {
            slot0 := sload(0)
        }
        return slot0;
    }
    
    // 获取存储槽1的原始数据（如果字符串长度超过31字节）
    function getStorageSlot1() public view returns (bytes32) {
        bytes32 slot1;
        assembly {
            slot1 := sload(1)
        }
        return slot1;
    }
    
    // 获取字符串的十六进制表示
    function getNameHex() public view returns (string memory) {
        return _toHexString(bytes(name));
    }
    
    // 将字节数组转换为十六进制字符串
    function _toHexString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    
    // 获取字符串长度
    function getNameLength() public view returns (uint256) {
        return bytes(name).length;
    }
}
