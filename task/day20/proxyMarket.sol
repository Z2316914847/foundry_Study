// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract proxyMarket is ERC1967Proxy{
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {
    }
}