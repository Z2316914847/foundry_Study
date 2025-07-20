// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract DeployMyToken is Script {
    function run() external {
        // 方法 1：直接硬编码私钥（推荐）
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // 加载.env文件中的MNEMONIC的配置变量
        // string memory mnemonic = vm.envString("MNEMONIC");

        // (deployer, ) = deriveRememberKey(mnemonic, 0);
        
        // 开始广播交易,使用私钥广播交易
        vm.startBroadcast(deployerPrivateKey);
        // 开始广播，使用助记词广播交易
        // vm.startBroadcast(deployer);

        // 部署 MyToken
        string memory name = "MyToken";
        string memory symbol = "MTK";
        MyToken token = new MyToken(name, symbol);

        // 结束广播
        vm.stopBroadcast();

        // 输出合约地址
        console.log("MyToken deployed at:", address(token));
    }
}


//  forge script script/DeployMyToken.s.sol:DeployMyToken     
//   --rpc-url $SEPOLIA_RPC_URL     --broadcast     --verify   --etherscan-api-key $ETHERSCAN_API_KEY