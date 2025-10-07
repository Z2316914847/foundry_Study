// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20Permit {
    // 根据 owner 的签名
    // 参数：owner就是签名者，spender就是owner2，value就是代币数量，deadline就是签名存在时间有效期
    function permit( address owner, address spender, uint256 value,  uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external ;

    // 返回当前 owner签名者的nonce 
    // 参数：owner就是签名者
    function nonces(address owner) external view returns (uint256);

    // 返回用于编码 {permit} 的签名的域分隔符（domain separator）
    function DOMAIN_SEPARATOR() external returns(bytes32) ;
}


contract ownerERC20Permit is IERC20Permit{
    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint256 public totalSupply;   // 设置供应量归部署者所有

    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowances;   // owner1授权owne2 x个代币

    // 记录所有当前用户nonce
    mapping(address => uint) private _nonces;  
    // ERC721结构化数据 - 域 状态变量
    bytes32 private immutable _DOMAIN_SEPARATOR;
    // 这是 ​EIP-712 类型哈希（Type Hash）​，定义了 Permit 消息的结构。它确保链下签名和链上验证的数据结构一致。
    bytes32 private constant _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor()  {
        name = 'Base';
        symbol = 'Base';
        decimals = 18;
        totalSupply = 10000*10**18;
        balances[msg.sender] = totalSupply;

        // 初始化域分隔符  separator
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // 允许任何一个人查看某地址金额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // 从调用者地址向目标地址转账
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value){
            revert("ERC20: transfer amount exceeds balance");
        } 
        // 转账前，判断目标地址是否是合约地址，如果是，则调用 transferWithCallback() 方法
        if(_to.code.length != 0){
            require(transferWithCallback(_to, _value),"transfer tokens failed");  
        }
        balances[msg.sender]  =balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }

    // 从 from地址向to地址转账(需要授权),转账者的地址其实是授权者地址
    // 这个方法是被授权者调用，把owner1授权者的代币用掉
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // 判断地址和value输入是否符合要求，注意这里有一种情况没有判断，假如用户收取余额给Bank后，用户又自己花掉他所有资产，
        // 这样后来Bank转账给用户时，就会失败，因为用户没有余额了。   balances[_from] >= _value
        require(_from!=address(0), "approve address to the zero address");
        require(_to!=address(0), "receive address to the zero address");
        require(_value>0,"ERC20: approve value less than zero");
        // 查询被授权人 spender 余额>value
        uint256  approveBalance= allowance( _from, msg.sender);
        require(approveBalance>=_value ,"ERC20: approve value greater than balance");

        // 授权的记录更新 + balances更新转账
        allowances[_from][msg.sender] = approveBalance - _value;
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    // 允许 spender多次从调用者地址提款 ：允许 Token 的所有者批准某个地址消费他们的一部分Token（approve）
    function approve(address _spender, uint256 _value) public returns (bool) {
        // 授权地址要有效
        require(_spender!=address(0), "ERC20: approve to the zero address");
        // 授权value额度必须大于0，但是没有检查用户是否有足够的余额
        require(_value>0,"ERC20: approve value less than zero");
        // 授权记录更新
        bool success = approve2(msg.sender, _spender, _value);
        require(success,"ERC20: approve failed");
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function approve2(address _from ,address _spender, uint256 _value) public returns (bool) {
        allowances[_from][_spender] = allowances[_from][_spender] + _value;
        return true; 
    }

    // 查询owner授权给 spender地址额度
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {  
        return allowances[_owner][_spender];
    }

    // 转账函数.在转账时，如果目标地址是合约地址的话，调用目标地址的 tokensReceived() 方法。
    function transferWithCallback(address to, uint256 amount) public  returns (bool){
        (bool success,) = to.call(abi.encodeWithSelector(bytes4(keccak256("tokensReceived(address,uint256)")), msg.sender, amount));
        return success;
    }

    // bank合约调用permit函数，完成签名授权转账
    // 参数：owner就是签名者，spender就是owner2，value就是代币数量，deadline就是签名存在时间有效期
    // 参数：(v, r, s)是用户在前端（如 MetaMask）对 Permit 消息进行签名生产的。所有（v，r，s）代表签名
    function permit( address owner, address spender, uint256 value,  uint256 deadline, uint8 v, bytes32 r, bytes32 s ) public override {
        require( block.timestamp<=deadline, "ERC20Permit: expired deadline");

        // 第一次hash：生成结构化数据哈希，以便后续进行链下签名和链上验证。它的作用是构造一个符合 EIP-712 标准的消息，用于 ​免 Gas 费授权
        bytes32 structHash = keccak256(abi.encode( _PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        // 第二次hash：完整 EIP-712 哈希。 将 structHash 和 ​EIP-712 域信息（Domain Separator）​​ 组合，生成最终的 ​符合 EIP-712 标准的哈希。这个哈希才是真正用于 ​签名验证​ 的数据
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash));

        // ecrecover 是 Solidity 的内置函数，直接使用内置的 errecover函数前提是，获得的 r、s、v要符合要求。如果签名不符合要求，直接使用内置errecover会造成漏洞。
        //   所以推荐使用 Openzeppelin的 ECDSA.sol合约。这个合约内置 检查签名是否符合要求，如果签名符合要求的话，才会调用 内置函数 ecrecover 。
        // 具体ecrecover代码逻辑可以自己查看资料
        address signer = ecrecover(hash, v, r, s);

        // 前端签名地址等于 owner 地址，说明是owner是签名者本人，否则就是有人伪造签名
        require(signer != address(0) && signer == owner, "ERC20Permit: invalid signature");
        // 没有检查用户是否有足够的余额，就授权这是一个问题点。
        allowances[owner][spender] = value;
        emit Approval(owner, spender, value);

    } 

    // 返回当前 owner签名者的nonce 
    // 参数：owner就是签名者
    function nonces(address owner) public  view override returns (uint256){
        return _nonces[owner];
    }

    // 返回用于编码 {permit} 的签名的域分隔符（domain separator）
    function DOMAIN_SEPARATOR() public override view  returns (bytes32){
        return _DOMAIN_SEPARATOR;
    }

    // 消费nonce": 返回 `owner` 当前的 `nonce`，并增加 1。
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] += 1;
    }

}
   