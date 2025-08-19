// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
    uint8 public constant decimals = 18;
    uint public totalSupply;  // LP 总供应量
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    // DOMAIN_SEPARATOR 包含了本条链的 chainId, 当前合约名称, 版本, 合约地址等信息
    bytes32 public DOMAIN_SEPARATOR;
    // PERMIT_TYPEHASH 的值是通过对 permit 函数的参数进行哈希计算而得到的固定值，用于验证 permit 函数的调用
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // DOMAIN_SEPARATOR和PERMIT_TYPEHASH被添加到签名信息中, 目的是让这个签名只能用于本条链, 本合约, 本功能(Permit)使用, 从而避免这个签名被拿到其他合约或者其他链的合约实施重放攻击
    // 某个地址的nonce值，某个地址发送交易到这个ERC20合约，需要nonce值，防止重放攻击
    mapping(address => uint) public nonces;

    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint256 chainId = block.chainid;
        // assembly 内编汇联：允许开发者直接编写 EVM（以太坊虚拟机）级别的操作码（opcode），以实现更底层、更高效的操作。
        // assembly {
        //     // Solidity 0.8.0 之前没有 block.chainid 全局变量，必须用汇编获取。现在可以通过 block.chainid 获取当前链的 ID。
        //     chainId := chainid
        // }
        // 固定域信息
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }


    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        // 判断是否已经被授权
        // if (allowance[from][msg.sender] != uint(-1)) { // 0.8.0 之前版本
        if (allowance[from][msg.sender] != type(uint).max) {
            // 先对授权金额进行减少，其中若授权金额小于转账金额会require失败
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        // 判断是否在有效时间内
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            // 将多个变量打包为紧密压缩的字节数组
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        // ecrecover 函数可以返回与签名者对应的公钥地址
        address recoveredAddress = ecrecover(digest, v, r, s);
        // 判断签名者对应的公钥地址与授权地址是否一致
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
