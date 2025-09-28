```
需求
    编写一个 Vesting 合约（可参考 OpenZepplin Vesting 相关合约）， 相关的参数有：
    beneficiary： 受益人
    锁定的 ERC20 地址
    Cliff：12 个月
    线性释放：接下来的 24 个月，从 第 13 个月起开始每月解锁 1/24 的 ERC20
    Vesting 合约包含的方法 release() 用来释放当前解锁的 ERC20 给受益人，Vesting 合约部署后，开始计算 Cliff ，并转入 100 万 ERC20 资产。
    要求在 Foundry 包含时间模拟测试， 请贴出你的 githu 代码库。

思路：Vesting 合约部署后，token 合约授权代币给 Vesting 合约地址，token 合约在调用 transfer( address(vesting), amount)
    token中的代币授权给vesting地址，这个授权额度只能由vesting地址才能被使用，Vesting通过release()来释放锁定的token代币。
```

#### Defi
  - WEB3 - 进程之路(截止2025年)
    - 同文件夹下有一张图片：WEB3_Development_Path.png
  - Token分为：服务性（平台提供服务，使用服务，消耗代币）和权益性（享受平台资产的未来价值：分红、投票治理、债券等等）
  - Token发行
    - 项目构思、白皮书(技术优势、token经济模型，一个好的经济模型十分重要)
    - 寻找投资机构
    - 产品开发、测试、上线
    - 产品推广、社区建设、运营、维护产品
    - Token公开发行：ICO（首次代币发行）、STO（证券型代币发行）、IEO（首次交易所发行）等方式公开出售Token，获取项目开发资金
    - Token上线交易所
  - 代币被锁仓后，代币释放方式
    - 线性释放：按时间等额释放
    - 周期释放：每个季度或者每年释放
    - 参与型释放：根据任务、指标释放等等。例如：社区激励
    - 有一些项目会额外设置 Cliff 期（悬崖期），在 Cliff 期间，代币会被锁定，直到 Cliff 期结束后才会释放。这个Cliff主要是针对项目方，因为项目方持有大量项目代币。
  - DEX：接下来快速过一下UniswapV1，后面会详细介绍V2、v3
    - uniswap 使用常量乘积模型 K = x * y
      - X：代表用户提供的 代币A 数量
      - Y：代表用户提供的 代币B 数量
    - 流动性：sqrt(K)。总流动性就是 K 开平方
    - 在兑换时，K保持不变
      - 用户用代币A兑换代币B，则 代币A增加，代币B减少
      - 用户用代币B兑换代币A，则 代币A减少，代币B增加
