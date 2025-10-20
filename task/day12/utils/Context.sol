// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev 提供有关当前执行上下文的信息，包括交易的发送者及其数据。
 * 虽然这些信息通常可以通过 msg.sender 和 msg.data 获得，但不应以这种直接的方式访问它们，
 * 因为在处理元交易（meta-transactions）时，发送和支付执行费用的账户可能不是实际的发送者
 * （就应用程序而言）。
 *
 * 此合约仅用于中间的、类似库的合约。
 * 主要作用：为支持元交易和代理模式提供抽象层
 */
abstract contract Context {
    /**
     * @dev 返回消息发送者的地址
     * 在普通交易中返回 msg.sender
     * 可以在子合约中重写以支持元交易
     * @return address 消息发送者的地址
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev 返回完整的消息数据（calldata）
     * 在普通交易中返回 msg.data
     * 可以在子合约中重写以支持元交易
     * @return bytes calldata 完整的消息数据
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev 返回上下文后缀的长度
     * 在支持元交易时，可能需要从 calldata 末尾提取额外信息
     * 默认返回 0，表示没有额外的上下文信息
     * @return uint256 上下文后缀的字节长度
     */
    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}
