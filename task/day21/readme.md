Fork 代码库：https://github.com/OpenSpace100/openspace_ctf
阅读代码  Vault.sol 及测试用例，在测试用例中 testExploit 函数添加一些代码，设法取出预先部署的 Vault 合约内的所有资金。
以便运行 forge test 可以通过所有测试。
可以在 Vault.t.sol 中添加代码，或加入新合约，但不要修改已有代码。
请提交你 fork 后的代码库链接。

遇到的问题
  1.abi应用接口 - 编码
    1.abi.encode(arg1,arg2,...)
    2.abi.encodePacked(arg1,arg2,....)
    3.abi.encodeWithSignature("functionName(type1,type2,...)",arg1,arg2,...)
    4.abi.encodeWithSelector(bytes4(keecak256("functionName(type1,type2,...)")) ,arg1,arg2,...)
    5.abi.encodeCall(IERC20.transfer, (_to, _value)):encodeCall 可以通过函数指针，来对函数及参数编码，在执行编码时，执行完整的类型检查, 确保类型匹配函数签名
2.abi应用接口 - 解码