// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


// 多签钱包
contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction( address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);

    address[] public owners;  // 多签地址
    uint public threshold;  // 多签批准最少人数
    mapping(address => bool) public isOwner;  // 判断某地址是否为多签

    // 交易结构
    struct Transaction {
        address to;  // 目标地址
        uint value;  // 转账金额
        bytes data;  // 调用数据
        bool executed;  // 是否执行
        uint confirmationCount;  // 当前确认数
    }

    // 记录提案同意人数
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;  // 交易结构的数组

    // 仅允许所有者调用
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    // 是否存在这个提案
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Tx does not exist");
        _;
    }
    
    // 假如存在这个提案，必须要求这个 提案 为 未执行状态
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Tx already executed");
        _;
    }

    // 判断该地址是否已经确认过该 提案
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "This address cannot be approved repeatedly");
        _;
    }

    // 接收ETH的回退函数
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // 构造函数
    constructor(address[] memory _owners, uint _threshold) {
        _setupOwners(_owners, _threshold);
    }

    // 设置多签地址和最少批准人数
    function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
        require(_owners.length > 0, "The number of multi-signatures must be greater than 0");
        require(
            _threshold > 0 && _threshold <= _owners.length,
            "The number of approvers must be greater than 0 and the number of approvers must be less than or equal to the maximum number of multi-signatures."
        );

        // 循环设置多签地址
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            // 该地址不能为 '0' 地址 && 该地址不能为之前不能为多签地址 && 该地址不为本合约地址
            require(owner != address(0) && !isOwner[owner] && owner != address(this), "multi-sig address not zero");

            isOwner[owner] = true;
            owners.push(owner);
        }

        threshold = _threshold;
    }

    // 提交一个新交易提案
    // 参数：_to 目标地址、_value 转账金额(wei)、_data 调用数据
    function submitTransaction( address _to, uint _value, bytes memory _data ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmationCount: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // 确认一个交易提案
    // 参数：_txIndex 交易索引
    function confirmTransaction( uint _txIndex ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        // 增加确认数并且将该地址的确认状态设置为 true
        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmationCount += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // 执行一个已确认的交易
    // 参数：_txIndex 交易索引
    function executeTransaction( uint _txIndex ) public txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require( transaction.confirmationCount >= threshold, "The number of approved people must be greater than the minimum value" );
        transaction.executed = true;

        // 执行提案具体内容
        (bool success, ) = transaction.to.call{value: transaction.value}( transaction.data );
        require(success, "transaction execution failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // 撤销对交易的确认
    // 参数：_txIndex 交易索引
    function revokeConfirmation( uint _txIndex ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "This address cannot be revoked");

        // 减少确认数并且将该地址的确认状态设置为 false
        transaction.confirmationCount -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    // 获取所有者列表
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // // 获取交易总数
    // function getTransactionCount() public view returns (uint) {
    //     return transactions.length;
    // }

    // // 获取交易详情
    // function getTransaction( uint _txIndex ) public view returns ( address to, uint value, bytes memory data, bool executed, uint confirmationCount ) {
    //     Transaction storage transaction = transactions[_txIndex];
    //     return (
    //         transaction.to,
    //         transaction.value,
    //         transaction.data,
    //         transaction.executed,
    //         transaction.confirmationCount
    //     );
    // }
}