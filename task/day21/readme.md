```
需求：
  Fork 代码库：https://github.com/OpenSpace100/openspace_ctf
  阅读代码  Vault.sol 及测试用例，在测试用例中 testExploit 函数添加一些代码，设法取出预先部署的 Vault 合约内的所有资金。
  以便运行 forge test 可以通过所有测试。
  可以在 Vault.t.sol 中添加代码，或加入新合约，但不要修改已有代码。
  请提交你 fork 后的代码库链接。
```
##### 遇到的问题
  - abi应用接口 - 编码
    - abi.encode(arg1,arg2,...)
    - abi.encodePacked(arg1,arg2,....)
    - abi.encodeWithSignature("functionName(type1,type2,...)",arg1,arg2,...)
    - abi.encodeWithSelector(bytes4(keecak256("functionName(type1,type2,...)")) ,arg1,arg2,...)
    - abi.encodeCall(IERC20.transfer, (_to, _value)):encodeCall 可以通过函数指针，来对函数及参数编码，在执行编码时，执行完整的类型检查, 确保类型匹配函数签名
  - abi应用接口 - 解码


##### 如何提升合约安全性
  - 合约审计：
    - 有提交到审计公司：immunefi、Hasts.finance、Hacken Proof、bugrap等等...
    - 或者将合约公布出来，让全网网友审计。
    - 合约公布出来，举办比赛，让参赛人找出漏洞：code4rena、Sherlock、Hats.finance
  - 最小合约功能
    - 如何提升最小合约安全：减少外部依赖
  - 完整的测试
    - 使用foundry自带的测试工具(动态分析):模糊测试，边界测试，随机测试，覆盖测试等等...
    - 静态分析代码，工具有：Mythril、Slither、aderyn等等...
    - 形式化验证：Certora、solidity SMT Checker
    - ai：chatgpt
  - 预案和演练
    - 紧急停机
    - 灾难恢复
##### 常见的安全漏洞
  - 重入攻击
    - 引入重入锁/瞬时存储，避免多次调用同一个函数。
  - 溢出
    - 使用 SafeMath 库，避免整数溢出。
  - 精度损失
    - 在 solidity 0.8.0 版本之后，推出 unchecked 关键字，可以避免精度损失。
  - 权限控制
  - 签名重用
  - Dos服务拒绝
  - 减少函数无限循环
  - 遵循：检查 - 交互 - 变更 
