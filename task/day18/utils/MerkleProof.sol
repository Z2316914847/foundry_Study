// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/cryptography/MerkleProof.sol)
// 此文件由脚本 scripts/generate/templates/MerkleProof.js 程序化生成

pragma solidity ^0.8.20;

import {Hashes} from "./Hashes.sol";

/**
 * @dev 这些函数用于处理 Merkle 树证明的验证
 *
 * 树和证明可以使用我们的 JavaScript 库生成：
 * https://github.com/OpenZeppelin/merkle-tree
 * 您可以在 readme 中找到快速入门指南
 *
 * 警告：您应该避免使用在哈希前长度为 64 字节的叶子值，
 * 或者使用 keccak256 以外的哈希函数来哈希叶子节点。
 * 这是因为 Merkle 树中排序的内部节点对的连接可能被重新解释为叶子值。
 * OpenZeppelin 的 JavaScript 库生成的 Merkle 树默认安全，可以抵御这种攻击。
 *
 * 重要：使用以不安全方式访问内存的自定义哈希函数时，请考虑内存副作用。
 *
 * 注意：此库支持使用自定义交换哈希函数（即 `H(a, b) == H(b, a)`）构建的
 * merkle 树的证明验证。证明使用非交换哈希函数构建的树中的叶子包含需要
 * 此库不支持的额外逻辑。
 */
library MerkleProof {
    /**
     * @dev 提供的多重证明无效
     */
    error MerkleProofInvalidMultiproof();

    /**
     * @dev 如果 `leaf` 可以被证明是 `root` 定义的 Merkle 树的一部分，则返回 true。
     * 为此，必须提供一个 `proof`，包含从叶子到树根的分支上的兄弟哈希。
     * 假设每对叶子和每对原像都已排序。
     *
     * 此版本使用默认哈希函数处理内存中的证明。
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev 返回通过使用 `proof` 从 `leaf` 向上遍历 Merkle 树获得的重建哈希。
     * 当且仅当重建的哈希与树的根匹配时，`proof` 才有效。
     * 处理证明时，假设叶子和原像对已排序。
     *
     * 此版本使用默认哈希函数处理内存中的证明。
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = Hashes.commutativeKeccak256(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev 如果 `leaf` 可以被证明是 `root` 定义的 Merkle 树的一部分，则返回 true。
     * 为此，必须提供一个 `proof`，包含从叶子到树根的分支上的兄弟哈希。
     * 假设每对叶子和每对原像都已排序。
     *
     * 此版本使用自定义哈希函数处理内存中的证明。
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bool) {
        return processProof(proof, leaf, hasher) == root;
    }

    /**
     * @dev 返回通过使用 `proof` 从 `leaf` 向上遍历 Merkle 树获得的重建哈希。
     * 当且仅当重建的哈希与树的根匹配时，`proof` 才有效。
     * 处理证明时，假设叶子和原像对已排序。
     *
     * 此版本使用自定义哈希函数处理内存中的证明。
     */
    function processProof(
        bytes32[] memory proof,
        bytes32 leaf,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = hasher(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev 如果 `leaf` 可以被证明是 `root` 定义的 Merkle 树的一部分，则返回 true。
     * 为此，必须提供一个 `proof`，包含从叶子到树根的分支上的兄弟哈希。
     * 假设每对叶子和每对原像都已排序。
     *
     * 此版本使用默认哈希函数处理 calldata 中的证明。
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev 返回通过使用 `proof` 从 `leaf` 向上遍历 Merkle 树获得的重建哈希。
     * 当且仅当重建的哈希与树的根匹配时，`proof` 才有效。
     * 处理证明时，假设叶子和原像对已排序。
     *
     * 此版本使用默认哈希函数处理 calldata 中的证明。
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = Hashes.commutativeKeccak256(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev 如果 `leaf` 可以被证明是 `root` 定义的 Merkle 树的一部分，则返回 true。
     * 为此，必须提供一个 `proof`，包含从叶子到树根的分支上的兄弟哈希。
     * 假设每对叶子和每对原像都已排序。
     *
     * 此版本使用自定义哈希函数处理 calldata 中的证明。
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bool) {
        return processProofCalldata(proof, leaf, hasher) == root;
    }

    /**
     * @dev 返回通过使用 `proof` 从 `leaf` 向上遍历 Merkle 树获得的重建哈希。
     * 当且仅当重建的哈希与树的根匹配时，`proof` 才有效。
     * 处理证明时，假设叶子和原像对已排序。
     *
     * 此版本使用自定义哈希函数处理 calldata 中的证明。
     */
    function processProofCalldata(
        bytes32[] calldata proof,
        bytes32 leaf,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = hasher(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev 如果 `leaves` 可以根据 `proof` 和 `proofFlags` 同时被证明是 `root` 定义的 Merkle 树的一部分，
     * 则返回 true，如 {processMultiProof} 中所述。
     *
     * 此版本使用默认哈希函数处理内存中的多重证明。
     *
     * 注意：并非所有 Merkle 树都支持多重证明。有关详细信息，请参阅 {processMultiProof}。
     *
     * 注意：考虑 `root == proof[0] && leaves.length == 0` 的情况，因为它将返回 `true`。
     * 必须独立验证 `leaves`。请参阅 {processMultiProof}。
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev 返回从 `leaves` 和 `proof` 中的兄弟节点重建的树的根。重建通过逐步重建所有内部节点进行，
     * 通过将叶子/内部节点与另一个叶子/内部节点或证明兄弟节点组合，具体取决于每个 `proofFlags` 项是 true 还是 false。
     *
     * 此版本使用默认哈希函数处理内存中的多重证明。
     *
     * 注意：并非所有 Merkle 树都支持多重证明。要使用多重证明，确保以下条件就足够了：
     * 1) 树是完整的（但不一定是完美的），
     * 2) 要证明的叶子按与树中相反的顺序排列（即，从最深层开始从右到左查看，然后继续到下一层）。
     *
     * 注意：空集（即 `proof.length == 1 && leaves.length == 0` 的情况）被视为无操作，
     * 因此是有效的多重证明（即它返回 `proof[0]`）。如果您没有在其他地方验证叶子，请考虑禁止这种情况。
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // 此函数通过从叶子向上遍历树来重建根哈希。根通过消耗和产生队列上的值来重建。
        // 队列从 `leaves` 数组开始，然后转到 `hashes` 数组。在过程结束时，
        // `hashes` 数组中的最后一个哈希应该包含 Merkle 树的根。
        uint256 leavesLen = leaves.length;
        uint256 proofFlagsLen = proofFlags.length;

        // 检查证明有效性
        if (leavesLen + proof.length != proofFlagsLen + 1) {
            revert MerkleProofInvalidMultiproof();
        }

        // xxxPos 值是每个数组中要消耗的下一个值的"指针"。所有访问都使用 `xxx[xxxPos++]` 完成，
        // 它返回当前值并递增指针，从而模拟队列的"弹出"。
        bytes32[] memory hashes = new bytes32[](proofFlagsLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // 在每一步中，我们使用两个值计算下一个哈希：
        // - 来自"主队列"的值。如果尚未消耗所有叶子，我们获取下一个叶子，否则我们获取下一个哈希。
        // - 根据标志，要么是来自"主队列"的另一个值（合并分支），要么是来自 `proof` 数组的元素。
        for (uint256 i = 0; i < proofFlagsLen; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = Hashes.commutativeKeccak256(a, b);
        }

        if (proofFlagsLen > 0) {
            if (proofPos != proof.length) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[proofFlagsLen - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev 如果 `leaves` 可以根据 `proof` 和 `proofFlags` 同时被证明是 `root` 定义的 Merkle 树的一部分，
     * 则返回 true，如 {processMultiProof} 中所述。
     *
     * 此版本使用自定义哈希函数处理内存中的多重证明。
     *
     * 注意：并非所有 Merkle 树都支持多重证明。有关详细信息，请参阅 {processMultiProof}。
     *
     * 注意：考虑 `root == proof[0] && leaves.length == 0` 的情况，因为它将返回 `true`。
     * 必须独立验证 `leaves`。请参阅 {processMultiProof}。
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bool) {
        return processMultiProof(proof, proofFlags, leaves, hasher) == root;
    }

    /**
     * @dev 返回从 `leaves` 和 `proof` 中的兄弟节点重建的树的根。重建通过逐步重建所有内部节点进行，
     * 通过将叶子/内部节点与另一个叶子/内部节点或证明兄弟节点组合，具体取决于每个 `proofFlags` 项是 true 还是 false。
     *
     * 此版本使用自定义哈希函数处理内存中的多重证明。
     *
     * 注意：并非所有 Merkle 树都支持多重证明。要使用多重证明，确保以下条件就足够了：
     * 1) 树是完整的（但不一定是完美的），
     * 2) 要证明的叶子按与树中相反的顺序排列（即，从最深层开始从右到左查看，然后继续到下一层）。
     *
     * 注意：空集（即 `proof.length == 1 && leaves.length == 0` 的情况）被视为无操作，
     * 因此是有效的多重证明（即它返回 `proof[0]`）。如果您没有在其他地方验证叶子，请考虑禁止这种情况。
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bytes32 merkleRoot) {
        // 此函数通过从叶子向上遍历树来重建根哈希。根通过消耗和产生队列上的值来重建。
        // 队列从 `leaves` 数组开始，然后转到 `hashes` 数组。在过程结束时，
        // `hashes` 数组中的最后一个哈希应该包含 Merkle 树的根。
        uint256 leavesLen = leaves.length;
        uint256 proofFlagsLen = proofFlags.length;

        // 检查证明有效性
        if (leavesLen + proof.length != proofFlagsLen + 1) {
            revert MerkleProofInvalidMultiproof();
        }

        // xxxPos 值是每个数组中要消耗的下一个值的"指针"。所有访问都使用 `xxx[xxxPos++]` 完成，
        // 它返回当前值并递增指针，从而模拟队列的"弹出"。
        bytes32[] memory hashes = new bytes32[](proofFlagsLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // 在每一步中，我们使用两个值计算下一个哈希：
        // - 来自"主队列"的值。如果尚未消耗所有叶子，我们获取下一个叶子，否则我们获取下一个哈希。
        // - 根据标志，要么是来自"主队列"的另一个值（合并分支），要么是来自 `proof` 数组的元素。
        for (uint256 i = 0; i < proofFlagsLen; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = hasher(a, b);
        }

        if (proofFlagsLen > 0) {
            if (proofPos != proof.length) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[proofFlagsLen - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev 如果 `leaves` 可以根据 `proof` 和 `proofFlags` 同时被证明是 `root` 定义的 Merkle 树的一部分，
     * 则返回 true，如 {processMultiProof} 中所述。
     *
     * 此版本使用默认哈希函数处理 calldata 中的多重证明。
     *
     * 注意：并非所有 Merkle 树都支持多重证明。有关详细信息，请参阅 {processMultiProof}。
     *
     * 注意：考虑 `root == proof[0] && leaves.length == 0` 的情况，因为它将返回 `true`。
     * 必须独立验证 `leaves`。请参阅 {processMultiProofCalldata}。
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev 返回从 `leaves` 和 `proof` 中的兄弟节点重建的树的根。重建通过逐步重建所有内部节点进行，
     * 通过将叶子/内部节点与另一个叶子/内部节点或证明兄弟节点组合，具体取决于每个 `proofFlags` 项是 true 还是 false。
     *
     * 此版本使用默认哈希函数处理 calldata 中的多重证明。
     *
     * 注意：并非所有 Merkle 树都支持多重证明。要使用多重证明，确保以下条件就足够了：
     * 1) 树是完整的（但不一定是完美的），
     * 2) 要证明的叶子按与树中相反的顺序排列（即，从最深层开始从右到左查看，然后继续到下一层）。
     *
     * 注意：空集（即 `proof.length == 1 && leaves.length == 0` 的情况）被视为无操作，
     * 因此是有效的多重证明（即它返回 `proof[0]`）。如果您没有在其他地方验证叶子，请考虑禁止这种情况。
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // 此函数通过从叶子向上遍历树来重建根哈希。根通过消耗和产生队列上的值来重建。
        // 队列从 `leaves` 数组开始，然后转到 `hashes` 数组。在过程结束时，
        // `hashes` 数组中的最后一个哈希应该包含 Merkle 树的根。
        uint256 leavesLen = leaves.length;
        uint256 proofFlagsLen = proofFlags.length;

        // 检查证明有效性
        if (leavesLen + proof.length != proofFlagsLen + 1) {
            revert MerkleProofInvalidMultiproof();
        }

        // xxxPos 值是每个数组中要消耗的下一个值的"指针"。所有访问都使用 `xxx[xxxPos++]` 完成，
        // 它返回当前值并递增指针，从而模拟队列的"弹出"。
        bytes32[] memory hashes = new bytes32[](proofFlagsLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // 在每一步中，我们使用两个值计算下一个哈希：
        // - 来自"主队列"的值。如果尚未消耗所有叶子，我们获取下一个叶子，否则我们获取下一个哈希。
        // - 根据标志，要么是来自"主队列"的另一个值（合并分支），要么是来自 `proof` 数组的元素。
        for (uint256 i = 0; i < proofFlagsLen; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = Hashes.commutativeKeccak256(a, b);
        }

        if (proofFlagsLen > 0) {
            if (proofPos != proof.length) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[proofFlagsLen - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev 如果 `leaves` 可以根据 `proof` 和 `proofFlags` 同时被证明是 `root` 定义的 Merkle 树的一部分，
     * 则返回 true，如 {processMultiProof} 中所述。
     *
     * 此版本使用自定义哈希函数处理 calldata 中的多重证明。
     *
     * 注意：并非所有 Merkle 树都支持多重证明。有关详细信息，请参阅 {processMultiProof}。
     *
     * 注意：考虑 `root == proof[0] && leaves.length == 0` 的情况，因为它将返回 `true`。
     * 必须独立验证 `leaves`。请参阅 {processMultiProofCalldata}。
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves, hasher) == root;
    }

    /**
     * @dev 返回从 `leaves` 和 `proof` 中的兄弟节点重建的树的根。重建通过逐步重建所有内部节点进行，
     * 通过将叶子/内部节点与另一个叶子/内部节点或证明兄弟节点组合，具体取决于每个 `proofFlags` 项是 true 还是 false。
     *
     * 此版本使用自定义哈希函数处理 calldata 中的多重证明。
     *
     * 注意：并非所有 Merkle 树都支持多重证明。要使用多重证明，确保以下条件就足够了：
     * 1) 树是完整的（但不一定是完美的），
     * 2) 要证明的叶子按与树中相反的顺序排列（即，从最深层开始从右到左查看，然后继续到下一层）。
     *
     * 注意：空集（即 `proof.length == 1 && leaves.length == 0` 的情况）被视为无操作，
     * 因此是有效的多重证明（即它返回 `proof[0]`）。如果您没有在其他地方验证叶子，请考虑禁止这种情况。
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bytes32 merkleRoot) {
        // 此函数通过从叶子向上遍历树来重建根哈希。根通过消耗和产生队列上的值来重建。
        // 队列从 `leaves` 数组开始，然后转到 `hashes` 数组。在过程结束时，
        // `hashes` 数组中的最后一个哈希应该包含 Merkle 树的根。
        uint256 leavesLen = leaves.length;
        uint256 proofFlagsLen = proofFlags.length;

        // 检查证明有效性
        if (leavesLen + proof.length != proofFlagsLen + 1) {
            revert MerkleProofInvalidMultiproof();
        }

        // xxxPos 值是每个数组中要消耗的下一个值的"指针"。所有访问都使用 `xxx[xxxPos++]` 完成，
        // 它返回当前值并递增指针，从而模拟队列的"弹出"。
        bytes32[] memory hashes = new bytes32[](proofFlagsLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // 在每一步中，我们使用两个值计算下一个哈希：
        // - 来自"主队列"的值。如果尚未消耗所有叶子，我们获取下一个叶子，否则我们获取下一个哈希。
        // - 根据标志，要么是来自"主队列"的另一个值（合并分支），要么是来自 `proof` 数组的元素。
        for (uint256 i = 0; i < proofFlagsLen; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = hasher(a, b);
        }

        if (proofFlagsLen > 0) {
            if (proofPos != proof.length) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[proofFlagsLen - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }
}
