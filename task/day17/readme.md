需求：
    先查看先前 NFTMarket 的各函数消耗，测试用例的 gas report 记录到 gas_report_v1.md尝试优化 NFTMarket 合约，
        尽可能减少 gas ，测试用例 用例的 gas report 记录到 gas_report_v2.md

遇到的问题
    1.测试用例必须包含一个测试函数，才能运行
    2.Gas消耗导出成一个文件：forge test test/NFTMarketGasTest.t.sol --gas-report > gas_report_v1.md
    3.immutable和constant修饰符：只能修饰值类型数据

优化gas
    NFT文件：
        1.静态调用更省gas：
          1.address.call()
          2.静态调用：address.staticcall()
        2.Token：decimals和totalSupply存储变为一个槽位，减少256位存储消耗：1441845-》1387923=53922
        3.NFT只动了一个mapping优化：变高了：2391422-》2432342 = 40920
        4.事件添加索引：2399665-》2391422=82433
        5.NFT使用错误代替require：报错了哈哈
        6.NFT多个require()语句，可以合并成一个require()语句，提高gas效率:2392433->2311645=80788




