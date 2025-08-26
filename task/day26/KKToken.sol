// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract KKToken is ERC20 {
    constructor() ERC20("KK Token", "KK") {
        _mint(msg.sender, 10000*1e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}