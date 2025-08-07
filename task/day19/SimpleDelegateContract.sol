// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract SimpleDelegateContract {

    struct Calls {
        address to;
        bytes data;
        uint256 value;
    }

    // 执行多个交易
    function execute(Calls[] memory calls) public payable{
        for (uint256 i = 0; i < calls.length; i++) {
            Calls memory call = calls[i];
            (bool success, bytes memory result) = call.to.call{value: call.value}(call.data);
            require(success, string(result));
        }
    }

    event Log(string message);
    // 合约得到用户授权 合约便可以代替用户操作 用户的账户
    function initialize() external payable {
        emit Log('Hello, world!');
    }

    // 支持接收ETH
    receive() external payable {}
    
    // fallback函数
    fallback() external payable {}
}