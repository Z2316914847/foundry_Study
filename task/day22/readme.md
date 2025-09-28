```
需求：
  先实现一个 Bank 合约， 用户可以通过 deposit() 存款， 然后使用 ChainLink Automation 、Gelato 或 OpenZepplin Defender Action 实现一个自动化任务， 
  自动化任务实现：当 Bank 合约的存款超过 x (可自定义数量)时， 转移一半的存款到指定的地址（如 Owner）。
  请贴出你的代码 github 链接以及在第三方的执行工具中的执行链接。


```

外部执行我们已上线的合约，是由chainlink的automation实现，内含：时间触发器，满足条件触发器，日志触发器。 

##### 静态分析工具使用 - slither
  - 首先安装slither：pip install slither-analyzer
      - 报错：没有安装pip/python-pip：sudo apt update && sudo apt install python3-pip
      - 验证安装成功：pip3 --version
      - 再次安装slither报错：
        - 报错信息：externally-managed-environment
        - 解决方法：​创建虚拟环境：
          - 首先保证安装好了： python3-venv 和 python3-full
            - 安装：sudo apt update && sudo apt install python3-venv python3-full
          - 然后项目目录中创建一个虚拟环境（确保在项目里：foundry_study）:
            - python3 -m venv .venv
          - 激活虚拟环境
            - source .venv/bin/activate
          - 激活环境后，控制台会出现这样的：(.venv) test01@DESKTOP-7MO4R69:~/foundry_study$ 
      - 再次安装slither成功
  - 验证安装成功：slither --version
  - 使用 - slither
    - 如果下次想在这个项目使用slither，都需要激活这个虚拟环境：
      - 进入项目：cd ~/foundry_study
      - 激活环境：source .venv/bin/activate
      - 然后就可以使用：slither .
      - 退出：deactivate
    - 分析task/day20/upGradeNFT_V1.sol合约(快速扫描)
      - slither task/day20/upGradeNFT_V1.sol
        - 分析结果：可以根据对应的 提示，去文档查找。下面这个 提示 就是：unused-state-variable（ unused state variable：没有使用状态变量）。这里说的 提示 安装slither说法是 探测器 == 提示
          ```
          INFO:Detectors:
          upGradeNFTV1.__gap (task/day20/upGradeNFT_V1.sol#44) is never used in upGradeNFTV1 (task/day20/upGradeNFT_V1.sol#16-47)
          Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-state-variable
          ```
    - 生成一个详细的 Markdown 格式报告：slither . --checklist
    - 排除 node_modules 和 lib 目录
      - slither . --exclude-dependencies
    - 或者手动指定要排除的目录
      - slither . --filter-paths "lib/|node_modules/"
    - 指定探测器
      - 列出所有可用的检测器
        - slither --list-detectors
      - 只运行特定的检测器（例如只检查重入和整数溢出）
        - slither . --detect reentrancy-eth,incorrect-equality
      - 排除特定的检测器（例如排除所有优化建议）
        - slither . --exclude-detect optimization
    - 可视化功能 (非常强大)
      - 生成继承关系图（会生成 .dot 文件）
        - slither . --print inheritance-graph
      - 生成调用图
        - slither . --print call-graph
      - 将 .dot 文件转换为 PNG 图片（需要安装 graphviz）
        - dot -Tpng contracts.MyContract.sol_InheritanceGraph.dot -o inheritance.png

  
      




##### 有了 slither 为什么还需要 Mythril？
  - slither 在不运行代码情况下，仔细检查每一行代码的结构和模式，找出所有“看起来不对劲”的地方。
  - Mythril 它实际模拟执行代码，尝试各种疯狂的输入，看程序在“运行时”会不会崩溃或行为异常。
| 特性 | Slither (静态分析) | Mythril (动态分析) |
|------|-------------------|-------------------|
| 工作原理 | 检查源代码的语法和结构模式，而不执行它 | 执行合约字节码（符号执行、卷积、模糊测试），模拟运行时状态 |
| 分析方式 | 类似于一个超级 linter，基于预定义的漏洞模式进行匹配 | 类似于一个自动化黑客，尝试探索所有可能的执行路径 |
| 速度 | 非常快（秒级）。可以即时反馈 | 相对较慢（分钟级甚至更长），因为它要探索无数路径 |
| 覆盖率 | 可以检查100%的代码，但仅限于静态模式 | 可能无法覆盖100%的路径（路径爆炸问题），但能发现动态行为 |
| 主要优势 | 速度快、优化建议好、可视化能力强、能找代码风格问题 | 能发现更深层、更复杂的逻辑漏洞和边界情况漏洞 |