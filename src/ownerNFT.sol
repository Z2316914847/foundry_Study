// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
interface IERC165 {
    // 如果合约实现了函数，返回true
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

interface IERC721 is IERC165 {

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

contract ERC721 is IERC721, IERC721Metadata {
    using Strings for uint256;  // 关键：启用 toString() 方法

    string public name_;
    string public symbol_;
    string public baseURI_;

    // 某个地址的NFT数量，单纯的个数，刚开始我还理解到集合了，搞错了，哈哈哈哈哈
    mapping( address=>uint256 ) public balances_;
    // NFT对应地址 永久性授权
    mapping( uint256=>address ) public owners_;
    // NFT对应地址 临时性授权:ERC721单次授权，被授权使用完了NFT,那么address便变成address(0)地址
    mapping( uint256=>address) public approve_;
    // 所有者将所有的NFT授权给被授权人
    mapping(address=>mapping(address=>bool)) public isApprovedReNew_; 

    event Transfer(address indexed , address indexed , uint256 indexed );
    event Approval(address indexed , address indexed , uint256 indexed );
    event ApprovalForAll(address indexed , address indexed , bool indexed );

    // 跨合约失效，报错
    error ERC721InvalidReceiver(address);

    constructor(string memory _name, string memory _symbol, string memory _baseURI){
        name_ = _name;
        symbol_ = _symbol;
        baseURI_ = _baseURI;
    }

    // 六个方法
    // 查看某个地址的NFT个数
    function balanceOf(address owner) public view override  returns (uint256) {
        require( owner!=address(0), "owner is not valid");
        return balances_[owner];
    }
    // 查看某个TokenId属于那个地址
    function ownerOf(uint256 tokenId) public view override  returns (address) {
        // return owners[tokenId];  // mapping的value会有默认值
        address owner = owners_[tokenId];
        require(owner!=address(0), "tokenId not exist");
        return owner;
    }

    // 授权函数No1，被授权不能在授权NFT，除非授权将所有都授权给被授权者(isApprovedReNew_查询为true的话，就可以额授权)
    // 参数：owner2是被授权人，tokenId是NFT的Id
    function approve(address owner2, uint256 tokenId ) public override {
        address owner1 = owners_[tokenId];
        require( owners_[tokenId]!=address(0), "tokenId is not exist");
        require( owner2!=address(0), "to is not valid");
        require(
            msg.sender == owner1 || isApprovedReNew_[owner1][msg.sender],
            "not owner nor approved for all"
        );
        _approve2(owner1, owner2, tokenId);

    }

    // 授权No2。单次授权。 更新临时授权状态变量
    // 参数：owner1是授权人，owner2是被授权人，tokenId是NFT的Id
    function _approve2(address owner1, address owner2, uint256 tokenId) public {
        approve_[tokenId] = owner2;
        emit Approval(owner1, owner2, tokenId);
    }

    // 多次授权，将所有NFT授权给被授权人
    // 参数：owner2是被授权人，approved判断是否被授权
    function setApprovalForAll(address owner2, bool approved) public override {
        isApprovedReNew_[msg.sender][owner2] = approved;
        emit ApprovalForAll(msg.sender, owner2, approved);
    }

    // 查询批量NFT是否被全部授权
    function isApprovedForAll( address owner1, address owner2 ) public view override  returns (bool) {
        return isApprovedReNew_[owner1][owner2];
    }

    // 查询单次NFT是否被授权 
    function getApproved(uint256 tokenId) public view override  returns (address) {
         require(owners_[tokenId] != address(0), "token doesn't exist");
        return approve_[tokenId];
    }

    // 查询owner2r(msg.sender == spender)是否有被授权处理 tokenId。
    function _isApprovedOrOwner( address owner1, address owner2, uint256 tokenId ) public view  returns (bool) {
        return owner1 == owner2 || approve_[tokenId] == owner2 || isApprovedReNew_[owner1][owner2];
    }

    // 普通转让，不推荐使用，不安全
    // 参数：from要和NFT持有者地址一样，owner2：接受NFT持有者，tokenId：NFT的ID
    function transferFrom(address from, address owner2, uint256 tokenId) public override  {
        address owner1 = ownerOf(tokenId);
        require( _isApprovedOrOwner(owner1, msg.sender, tokenId), "not owner nor approved" );
        _transfer(owner1, from, owner2, tokenId);
    }

    // 参数：owner1为NFT持有者地址，from也是NFT持有者(前提是前端输入的地址是NFT持有者地址)
    function _transfer( address owner1, address from, address owner2, uint tokenId ) private {
        require(owner2 != address(0), "transfer to the zero address");
        require(from == owner1, "not owner");
        owners_[tokenId] = owner2;
        balances_[from] -= 1;  // balances_[from]等价balances_[owner1]
        balances_[owner2] += 1;
        _approve2(owner1, address(0), tokenId);
        emit Transfer(from, owner2, tokenId);
    }

    // 安全装让不加Data函数
    function safeTransferFrom( address from, address owner2, uint256 tokenId) public override  {
        safeTransferFrom(from, owner2, tokenId, "");
    }

    // 安全转让 + Data函数
    function safeTransferFrom( address from, address owner2, uint256 tokenId, bytes memory _data ) public override  {
        address owner1 = ownerOf(tokenId);
        require( _isApprovedOrOwner(owner1, msg.sender, tokenId), "not owner nor approved" );
        _safeTransfer(owner1, from, owner2, tokenId, _data);
    }

    // 安全转让
    function _safeTransfer(address owner1, address from, address owner2, uint tokenId, bytes memory _data) public {
        // 转账 + 跨合约方法
        _transfer(owner1, from, owner2, tokenId);
        _checkOnERC721Received(from, owner2, tokenId, _data);
    }

    // 跨合约同步方法
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) public  {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    // 构造NFT，相当于存款
    function _mint(uint tokenId, address owner1) public {
        require(owner1 != address(0), "mint to zero address");
        require(owners_[tokenId] == address(0), "token already minted");
        balances_[owner1] += 1;
        owners_[tokenId] = owner1;
        emit Transfer(address(0), owner1, tokenId);
    }

    // 销毁函数，通过调整_balances和_owners变量来销毁tokenId，同时释放Transfer事件。条件：tokenId存在。
    function _burn(uint tokenId) internal virtual {
        address owner1 = ownerOf(tokenId);
        require(msg.sender == owner1, "not owner of token");
        _approve2(owner1, address(0), tokenId);
        balances_[owner1] -= 1;
        delete owners_[tokenId];
        emit Transfer(owner1, address(0), tokenId);
    }

    /**
     * 查询Data:根据固定baseURI的值，在拼接tokenId,以获得IPFS元数据访问地址
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(owners_[tokenId] != address(0), "Token Not Exist");
        string memory baseURI = _baseURI();
        // return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "")) : "";
    }

    // 获取固定的baseURI
    function _baseURI() public view returns (string memory) {
        return baseURI_;
    }

    // 实现IERC165接口supportsInterface
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function name() public override view  returns (string memory){
        return name_;
    }

    function symbol() public override view  returns (string memory){
        return symbol_;
    }
}

