// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract BaseScript is Script{

    function setUp() public virtual {
        
        // 加载.env文件中的MNEMONIC的配置变量
        // string memory mnemonic = vm.envString("MNEMONIC");
        // (deployer, ) = deriveRememberKey(mnemonic, 0);
        // 开始广播，使用助记词广播交易
        // vm.startBroadcast(deployer);
        
        
         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // 开始广播交易,使用私钥广播交易
        vm.startBroadcast(deployerPrivateKey);

        
        // 结束广播
        vm.stopBroadcast();
        
    }

    // 保存合约地址
    function saveContract(string memory name, address addr) public {
        string memory chainId = vm.toString(block.chainid);

        string memory json1 = "key";
        string memory finalJson = vm.serializeAddress(json1, "address", addr);
        string memory dirPath = string.concat(string.concat("deployments/", name), "_");
        vm.writeJson(finalJson, string.concat(dirPath, string.concat(chainId, ".json")));
    }
}