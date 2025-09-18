# 仅供初学者参考：一步一步来存在
 - 有不懂的可以加我QQ：2844847674

## 一：前期步骤
### 1.工具准备安装wsl->foundry(开发环境，优先安装foundry，或者安装hardhat/truffle)
### 2.构建项目：
    1.forge init 项目名   // 创建项目
    2.cd 项目名  // 因为要在对应项目下编译
    3.cursor .  // 启动cursor,回到第二步指定文件夹
### 3.编译项目
    1.forge build
        遇到错误：Failed to install Solc 0.8.30: error sending request for 
            url (https://binaries.soliditylang.org/linux-amd64/list.json) 
        因为网络问题导致编译失败，手动配置Solc 0.8.30
            .# 创建目标目录:mkdir -p ~/.svm/0.8.30
            .# 从 GitHub 官方发布下载:wget https://github.com/ethereum/
              solidity/releases/download/v0.8.30/solc-static-linux -O ~/.svm/0.8.30/solc-0.8.30
            .# 设置可执行权限:chmod +x ~/.svm/0.8.30/solc-0.8.30
            .# 验证安装:~/.svm/0.8.30/solc-0.8.30 --version # 应该输出: 0.
              8.30+commit.1abaa4ba
            .启动cursor：cursor .
### 4.项目结构：
    1.cache文件夹：放forge缓存信息，在forge build后出现
    2.lib文件夹：存放依赖库
    3.out文件夹：存放编译输出文件
    4.script文件夹：放合约脚本，脚本可用于部署合约，广播交易
    5.src文件夹：合约源文件夹
    6.test文件夹：放测试合约代码
    7.foundry.toml：项目foundry配置信息

### 5.将foundry项目上传到github上
    1.git init  // 初始化本地仓库
    2.git add .    // 添加项目所有文件到本地仓库
    3.配置git信息：
        .git config --global user.name "github用户名"(头像下面的昵称)
        .git config --global user.email "github的email"（获取：setting-》account-》pblic email-》email-setting变可得到）
    .git commit -m "提交文件的信息"
    .github上创建仓库(注意不要添加：reamde.gitignore/license因为你的项目中有了)
    .本地仓库链接github：git remote add origin https://github.com/<你的用户名>/<仓库名>.git
    .代码推送到github上：git push -u origin main
        遇到问题：
            本地仓库没有main分支：
                检查你的分支：git branch
                    1.将你查到的分支推到远程Main分支上：git push -u origin master:main
                    2.重命名本地分支为main：git branch -M master main
            要设备码：需
                注意电脑弹窗就会有，你留一下

## 二：进入项目
### 获取节点和环境：
    1.当前项目下：anvil
### 运行测试用例
    1.运行所有测试用例：forge test
    2.运行特定测试用例：forge test -m test/Counter.t.sol
    3.运行特定测试函数：forge test -m "test_Increment"
### 部署
    1.forge create 合约名 --private-key 私钥  --rpc-url  http://localhost:8545  --broadcast
    2.forge script script文件夹中的脚本合约名 --private-key 私钥  --rpc-url  http://localhost:8545  --broadcast
###  命令行forge：
    1.forge inspect [OPTIONS] <TARGET> <FIELD>：获取合约或项目元数据的命令
    2.forge remapping：映射推导
    3.forge install OpenZeppelin/openzeppelin-contracts：更新OpenZeppelin依赖
    4.forge remove OpenZeppelin/openzeppelin-contracts：移除OpenZeppelin依赖
### 命令行Anvil：
    1.anvil --fork-url <RPC-URL>:基于网络的状态启动一个本地模拟环境
### mateMask导入Anvil虚拟账户：
    1.复制私钥和URI(http://127.0.0.1:8545)
    2.将私钥导入metaMask中
    3.添加测试完：将URI填入RPC URI中，网络名称随便填（随你心意）
    4.等一会，就会出现10000个虚拟ETH了
### 将remix中的合约部署到anvil测试网络中
    1.直接在remxi中部署合约就行（前提是账户选择Anvil）
### 将自己部署的合约或者被人部署的合约加载到remix中，并调用其中某个方法A
    1.将合约部署地址填到remix中的 At Address中即可(前提是remix合约中有那个方法A)
### 加载openzeppelin到项目
    1.命令行：forge install OpenZeppelin/openzeppelin-contracts
### 准备部署账号：evn-sample
    1.这个文件通常记录相关信息，私钥通常以三种方式存在：私钥，助记词，keystore文件(加密更安全)
    2.在这个文件中配置了私钥，以后部署合约就不要填私钥。
### 用cast创建钱包
    1.为什么还要创建钱包：
        1.可以无限生成新账户，
        2.私钥保存到文件中长期有效
        3.支持导入任何私钥或助记词
        4.专门用于签名
### 创建钱包几种方式
    1.cast wallet new：返回一个账户(包含账户地址，私钥)
    2.cast wallet new-mnemonic：返回一个账户(包含助记词，账户地址，私钥)
    3.cast wallet address private_key：返回一个？
    4.cast wallet import -i -k 指定目录 账户名称A：需要导入账户的私钥，账户A保存至某处，没指定目录的话，账户放在：~/.foundry/keystores下。
        可以设定密码，也可以不设定密码，设置密码只是让账户更安全一些(假如黑客获取到账户，keystores问件会被加密+黑客没密码，没有密码的话，他们难搞一点)
    5.cast wallet inport --mnemonic "助记词" -k：同上一条命令结果。
     注意：cast wallet new ./keys    ./keys文件： 是一个创建新钱包账户并将私钥保存到指定文件的命令
### 每次部署不用输入私钥：待更新
    1.写一个脚本，读取到你的配置文件（配置文件配置了助记词），然后在推到出账号，这样就完成了，不用每次都输入私钥：
### 保存地址技巧：待更新
    1.写脚本，将合约部署地址放到文件中（为什么要这样做呢，因为输出文件中找太蛮烦了（broadcast文件夹中），所有有了这个技巧）：待更新
### 配置RPC-URL：待更新 
    1.enc_sample问价中配置
    2.foundry.toml文件中配置
    注意：配置完，这个简化命令就可以代替之前繁杂的部署命令了

### 开源合约代码：待更新
- 代码是已字节码形式发送到链上(etherscan)。合约代码发给浏览器，浏览器在根据你的代码编译生产一个字节码，浏览器会根据浏览器字节码和本地字节码对比。字节码一样的话，浏览器就会显示你的合约代码。
- 部署时开源合约代码（后面升级代码，浏览器也是不会认得，因为升级的代码的字节码和上一个版本字节码不匹配。
        所以浏览器不认，所以好多人不愿部署时就开源，大家都想部署后面在开源）
- 部署时不开源，后面还是可以开源的
- 开源步骤：
    - 命令行：forge create src/OpenSourceContract.sol:OpenSourceContract --private-key 11111 --rpc-url 11111 --etherscan-api-key 11111 --verify --broadcast
    - 输完上面命令，foudry会自动版我们去etherscan上验证，如果验证失败(系统会验证4词)，会提示错误消息。
    - 输完上面命令，如果你不信为什么验证不通过，你可以手动验证：
        - 第一步进入该合约，点击contract选项卡
        - 点击右上角的“verify and publish”按钮。
        - 我是选择Single File（因为我只要验证一个sol文件）
        - 选择你合约使用的编译器
        - 选择你合约开源许可证（就是我们编写合约顶部的那段文字）
        - 进入下一个页面，将你的合约代码粘贴进去
        - 点击验证，通过的话，会变绿色（我已验证通过：合约地址：https://sepolia.etherscan.io/address/0xd0a9960641a4565d8d5afeda2e8f8fd50cc7a372#code）
### 将一个本地部署合约移交到测试网上
    1.在.env文件中配置：sepolia_rpc_url=https://sepolia.infura.io/v3/0ecc55a11dfe4ef6b50caedf71c07b6b意味着将从
        本地开发链，移动到连接到 ​Sepolia 测试网，所有操作将公开在以太坊测试链上，可被全网节点验证。

### 部署test合约
    1.使用完整命令：forge create test/Counter.t.sol:CounterTest --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545 --broadcast  --constructor-args 参数1 参数2 参数3
        注意：test/合约文件名:合约文件里的合约名
    2.使用简化命令：source .env && forge create test/Counter.t.sol:CounterTest --private-key $PRIVATE_KEY --rpc-url $LOCAL_RPC_URL --broadcast
        或者 forge create test/Counter.t.sol:CounterTest --private-key $PRIVATE_KEY --rpc-url $LOCAL_RPC_URL --broadcast
        注意：source .env 是 Linux/Unix shell 中的一个命令，它的作用是将 .env 文件中的环境变量加载到当前的 shell 会话中，这样后续的命令就可以直接使用这些变量
    3.中间简化：使用keystores部署合约
    4.超级简化：在合约文件里的setUp中加载账户
    注意：部署完合约，在test中如何调用合约中的方法：
        1.forge test --match-test 测试文件中合约的方法 -vvv（--match-test：别名--mt）
        2.forge test 具体测试合约文件名 --mt  合约中的方法  -vvv
### 部署Script合约
    1.使用完整命令：forge create script/Counter.s.sol:CounterScript --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545 --broadcast
    2.使用简化命令：forge script script/Counter.s.sol:CounterScript --private-key $PRIVATE_KEY --rpc-url $LOCAL_RPC_URL --broadcast
    3.中间简化：使用keystores部署合约
    4.超级简化：在合约文件里的setUp中加载账户
    注意：如果想调用合约中的方法，可以在setUp中直接调用即可

## 三：其他问题

### 使用部署地址查找合约中的状态变量值：
    1.查找状态变量token的地址值：cast call 部署合约地址 "token()(address)" --rpc-url http://localhost:8545

### 拉去github某个文件(不支持文件夹哦)到本地某个文件夹中; curl -o frontend/viem_front 文件的copy permalink地址链接（三个小按钮中）;

### 运行ts文件：npx ts-node NFTMarketEvent.ts

### 使用 Cast CLI 直接调用智能合约方法
    cast send 部署合约的地址 "方法名(参数1，参数2)" 参数值1 参数值2
        --rpc-url $SEPOLIA_RPC \
        --private-key $PRIVATE_KEY
### 购买NFT
cast send 0xMarketAddress "buyNFT(address,uint256)" 0xNFTAddress 1 \
  --value 0.1ether \
  --rpc-url $SEPOLIA_RPC \
  --private-key $PRIVATE_KEY






























