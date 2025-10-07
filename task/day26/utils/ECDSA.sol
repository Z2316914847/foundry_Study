// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 * 椭圆曲线数字签名算法 (ECDSA) 操作库
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 * 这些函数可用于验证消息是否由给定地址私钥的持有者签名
 *
 * 重要安全提示：
 * 1. 始终对消息进行哈希处理后再签名，不要直接签名原始数据
 * 2. 使用EIP-191或EIP-712标准格式进行签名
 * 3. 验证恢复的地址与预期签名者地址匹配
 * 4. 注意签名重放攻击，使用nonce或时间戳
 */
library ECDSA {
  // 签名恢复错误类型枚举
  enum RecoverError {
    NoError,                // 无错误
    InvalidSignature,       // 无效签名
    InvalidSignatureLength, // 无效签名长度
    InvalidSignatureS,      // 无效签名s值
    InvalidSignatureV       // 无效签名v值 (v4.8中已弃用)
  }

  /**
   * @dev 根据错误类型抛出相应的错误信息
   * @param error 错误类型
   */
  function _throwError(RecoverError error) private pure {
    if (error == RecoverError.NoError) {
      return; // 无错误：什么都不做
    } else if (error == RecoverError.InvalidSignature) {
      revert("ECDSA: invalid signature");
    } else if (error == RecoverError.InvalidSignatureLength) {
      revert("ECDSA: invalid signature length");
    } else if (error == RecoverError.InvalidSignatureS) {
      revert("ECDSA: invalid signature 's' value");
    }
  }

  /**
   * @dev 尝试从哈希消息和签名中恢复签名者地址
   * 返回签名哈希消息的地址或错误信息。该地址可用于验证目的。
   *
   * `ecrecover` EVM操作码允许可塑性（非唯一）签名：
   * 此函数通过要求`s`值在下半序，`v`值为27或28来拒绝它们。
   *
   * 重要：为了验证安全，`hash`必须是哈希操作的结果：
   * 可以构造对非哈希数据恢复到任意地址的签名。
   * 确保安全的方法是接收原始消息的哈希（否则可能太长），
   * 然后在其上调用{toEthSignedMessageHash}。
   *
   * 签名生成文档：
   * - Web3.js: https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign
   * - ethers.js: https://docs.ethers.io/v5/api/signer/#Signer-signMessage
   *
   * @param hash 已哈希的消息（32字节）
   * @param signature 签名数据（65字节：r+s+v）
   * @return recovered 恢复的签名者地址
   * @return error 恢复过程中的错误类型
   * 
   * _自v4.3版本可用_
   */
  function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
    if (signature.length == 65) {
      bytes32 r;  // 签名的r分量
      bytes32 s;  // 签名的s分量
      uint8 v;    // 签名的v分量
      
      // ecrecover需要签名参数，目前获取这些参数的唯一方法是使用汇编
      // 从65字节签名中提取r、s、v分量
      // 签名格式：前32字节=r，接下来32字节=s，最后1字节=v
      /// @solidity memory-safe-assembly
      assembly {
        // 从签名偏移0x20处读取32字节作为r值
        // 跳过前32字节（length字段）
        r := mload(add(signature, 0x20))
        // 从签名偏移0x40处读取32字节作为s值
        s := mload(add(signature, 0x40))
        // 从签名偏移0x60处读取第一个字节作为v值
        // v值决定使用哪个椭圆曲线点（27或28）
        v := byte(0, mload(add(signature, 0x60)))
      }
      return tryRecover(hash, v, r, s);
    } else {
      return (address(0), RecoverError.InvalidSignatureLength);
    }
  }

  /**
   * @dev 从哈希消息和签名中恢复签名者地址
   * 返回签名哈希消息的地址。该地址可用于验证目的。
   *
   * `ecrecover` EVM操作码允许可塑性（非唯一）签名：
   * 此函数通过要求`s`值在下半序，`v`值为27或28来拒绝它们。
   *
   * 重要：为了验证安全，`hash`必须是哈希操作的结果：
   * 可以构造对非哈希数据恢复到任意地址的签名。
   * 确保安全的方法是接收原始消息的哈希（否则可能太长），
   * 然后在其上调用{toEthSignedMessageHash}。
   *
   * @param hash 已哈希的消息（32字节）
   * @param signature 签名数据（65字节：r+s+v）
   * @return 恢复的签名者地址
   * 
   * 注意：如果恢复失败，此函数会抛出错误
   */
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, signature);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev {ECDSA-tryRecover}的重载，分别接收`r`和`vs`短签名字段
   * 支持EIP-2098短签名格式，可以节省gas费用
   *
   * 参见：https://eips.ethereum.org/EIPS/eip-2098[EIP-2098短签名]
   *
   * @param hash 已哈希的消息（32字节）
   * @param r 签名的r分量（32字节）
   * @param vs 签名的vs分量（32字节，包含s和v信息）
   * @return recovered 恢复的签名者地址
   * @return error 恢复过程中的错误类型
   * 
   * _自v4.3版本可用_
   */
  function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
    // 从vs中提取s值：清除最高位得到s
    // vs的最高位存储v信息，其余位存储s值
    bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    // 从vs中提取v值：取最高位并加27
    // EIP-2098短签名格式：vs = (v << 255) | s
    uint8 v = uint8((uint256(vs) >> 255) + 27);
    return tryRecover(hash, v, r, s);
  }

  /**
   * @dev {ECDSA-recover}的重载，分别接收`r`和`vs`短签名字段
   * 支持EIP-2098短签名格式
   *
   * @param hash 已哈希的消息（32字节）
   * @param r 签名的r分量（32字节）
   * @param vs 签名的vs分量（32字节，包含s和v信息）
   * @return 恢复的签名者地址
   * 
   * 注意：如果恢复失败，此函数会抛出错误
   * _自v4.2版本可用_
   */
  function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, r, vs);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev {ECDSA-tryRecover}的重载，分别接收`v`、`r`和`s`签名字段
   * 这是最底层的签名恢复函数，其他函数最终都会调用此函数
   *
   * @param hash 已哈希的消息（32字节）
   * @param v 签名的v分量（1字节，值为27或28）
   * @param r 签名的r分量（32字节）
   * @param s 签名的s分量（32字节）
   * @return recovered 恢复的签名者地址
   * @return error 恢复过程中的错误类型
   * 
   * _自v4.3版本可用_
   */
  function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
    // EIP-2仍然允许ecrecover()的签名可塑性。移除这种可能性并使签名唯一。
    // 以太坊黄皮书附录F (https://ethereum.github.io/yellowpaper/paper.pdf) 定义了有效范围：
    // s值范围(301): 0 < s < secp256k1n ÷ 2 + 1，v值范围(302): v ∈ {27, 28}
    // 大多数当前库生成的签名在s值下半序范围内是唯一的
    //
    // 签名可塑性问题：同一个私钥和消息可以生成多个有效签名
    // 攻击者可以利用这种可塑性进行重放攻击
    //
    // 如果你的库生成可塑性签名（如上半序的s值），计算新的s值：
    // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1
    // 并将v从27翻转到28或反之。如果你的库也生成0/1的v值而不是27/28，
    // 给v加27以接受这些可塑性签名。
    //
    // 安全常数：secp256k1曲线的阶数的一半
    // 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return (address(0), RecoverError.InvalidSignatureS);
    }

    // 如果签名有效（且不可塑），返回签名者地址
    address signer = ecrecover(hash, v, r, s);
    if (signer == address(0)) {
      return (address(0), RecoverError.InvalidSignature);
    }

    return (signer, RecoverError.NoError);
  }

  /**
   * @dev {ECDSA-recover}的重载，分别接收`v`、`r`和`s`签名字段
   * 这是最底层的签名恢复函数
   *
   * @param hash 已哈希的消息（32字节）
   * @param v 签名的v分量（1字节，值为27或28）
   * @param r 签名的r分量（32字节）
   * @param s 签名的s分量（32字节）
   * @return 恢复的签名者地址
   * 
   * 注意：如果恢复失败，此函数会抛出错误
   */
  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev 从哈希创建以太坊签名消息
   * 返回与使用eth_sign JSON-RPC方法签名的哈希对应的哈希，
   * 这是EIP-191标准的一部分。
   *
   * 此函数用于将32字节的哈希转换为标准的以太坊签名消息格式
   * 格式：\x19Ethereum Signed Message:\n32<32字节哈希>
   *
   * @param hash 要签名的32字节哈希
   * @return 以太坊签名消息哈希
   * 
   * 参见：{recover}函数用于恢复此哈希的签名者
   * 参见：https://eth.wiki/json-rpc/API#eth_sign
   */
  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    // 32是哈希的字节长度，由上面的类型签名强制
    // 根据EIP-191标准创建以太坊签名消息哈希
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  /**
   * @dev 从字节数组创建以太坊签名消息
   * 返回与使用eth_sign JSON-RPC方法签名的消息对应的哈希，
   * 这是EIP-191标准的一部分。
   *
   * 此函数用于将任意长度的字节数组转换为标准的以太坊签名消息格式
   * 格式：\x19Ethereum Signed Message:\n<长度><原始消息>
   *
   * @param s 要签名的字节数组
   * @return 以太坊签名消息哈希
   * 
   * 参见：{recover}函数用于恢复此哈希的签名者
   * 参见：https://eth.wiki/json-rpc/API#eth_sign
   */
  function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
    // 为可变长度字节数组创建以太坊签名消息哈希
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
  }

  /**
   * @dev 从域分隔符和结构哈希创建以太坊签名类型化数据
   * 返回与使用eth_signTypedData JSON-RPC方法签名的数据对应的哈希，
   * 这是EIP-712标准的一部分。
   *
   * EIP-712允许对结构化数据进行类型安全的签名，
   * 提供更好的用户体验和更强的安全性。
   *
   * @param domainSeparator 域分隔符，包含合约信息（名称、版本、链ID等）
   * @param structHash 结构化数据的哈希
   * @return EIP-712类型化数据哈希
   * 
   * 参见：{recover}函数用于恢复此哈希的签名者
   * 参见：https://eips.ethereum.org/EIPS/eip-712
   */
  function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
    // 根据EIP-712标准创建结构化数据哈希
    // \x19\x01是EIP-712的前缀
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
  }
}
