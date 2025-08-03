// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 存款记录映射
    mapping(address => uint256) public balances;
    
    // 前10名用户链表结构
    struct Rank {
        address user;
        uint256 amount;
        address next;
    }
    
    // 链表头节点
    address public head;
    
    // 用户到链表节点的映射
    mapping(address => address) public userToNode;
    
    // 节点到Rank的映射
    mapping(address => Rank) public nodes;
    
    // 存款事件
    event Deposited(address indexed user, uint256 amount);
    // 排名更新事件
    event RankUpdated(address indexed user, uint256 amount, uint256 rank);

    // 接收以太币存款
    receive() external payable {
        deposit();
    }
    
    // 存款函数
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新用户余额
        balances[msg.sender] += msg.value;
        
        // 更新排行榜
        _updateRank(msg.sender, balances[msg.sender]);
        
        emit Deposited(msg.sender, msg.value);
    }
    
    // 更新排行榜
    function _updateRank(address user, uint256 newAmount) private {
        // 如果用户已经在排行榜中
        if (userToNode[user] != address(0)) {
            // 先移除现有节点
            _removeNode(user);
        }
        
        // 插入新节点
        _insertNode(user, newAmount);
        
        // 如果链表长度超过10，移除末尾节点
        if (_getLength() > 10) {
            _removeLastNode();
        }
    }
    
    // 在链表中插入新节点
    function _insertNode(address user, uint256 amount) private {
        address newNode = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, user)))));
        
        // 如果链表为空
        if (head == address(0)) {
            head = newNode;
            nodes[newNode] = Rank(user, amount, address(0));
            userToNode[user] = newNode;
            return;
        }
        
        // 查找插入位置
        address current = head;
        address prev = address(0);
        
        while (current != address(0)) {
            if (amount > nodes[current].amount) {
                break;
            }
            prev = current;
            current = nodes[current].next;
        }
        
        // 插入新节点
        if (prev == address(0)) {
            // 插入到头部
            nodes[newNode] = Rank(user, amount, head);
            head = newNode;
        } else {
            // 插入到中间
            nodes[newNode] = Rank(user, amount, current);
            nodes[prev].next = newNode;
        }
        
        userToNode[user] = newNode;
    }
    
    // 从链表中移除节点
    function _removeNode(address user) private {
        address nodeToRemove = userToNode[user];
        require(nodeToRemove != address(0), "User not in ranking");
        
        // 查找前驱节点
        address current = head;
        address prev = address(0);
        
        while (current != nodeToRemove) {
            prev = current;
            current = nodes[current].next;
        }
        
        // 移除节点
        if (prev == address(0)) {
            // 移除头节点
            head = nodes[nodeToRemove].next;
        } else {
            nodes[prev].next = nodes[nodeToRemove].next;
        }
        
        // 清理映射
        delete nodes[nodeToRemove];
        delete userToNode[user];
    }
    
    // 移除链表末尾节点
    function _removeLastNode() private {
        address current = head;
        address prev = address(0);
        
        while (nodes[current].next != address(0)) {
            prev = current;
            current = nodes[current].next;
        }
        
        if (prev == address(0)) {
            // 只有一个节点
            delete nodes[head];
            delete userToNode[nodes[head].user];
            head = address(0);
        } else {
            // 移除最后一个节点
            delete nodes[current];
            delete userToNode[nodes[current].user];
            nodes[prev].next = address(0);
        }
    }
    
    // 获取链表长度
    function _getLength() private view returns (uint256) {
        uint256 count = 0;
        address current = head;
        
        while (current != address(0)) {
            count++;
            current = nodes[current].next;
        }
        
        return count;
    }
    
    // 获取前10名用户
    function getTop10() public view returns (Rank[] memory) {
        Rank[] memory top10 = new Rank[](_getLength());
        address current = head;
        uint256 index = 0;
        
        while (current != address(0)) {
            top10[index] = nodes[current];
            current = nodes[current].next;
            index++;
        }
        
        return top10;
    }
    
    // 获取用户排名
    function getUserRank(address user) public view returns (uint256) {
        if (userToNode[user] == address(0)) {
            return 0; // 不在排行榜中
        }
        
        uint256 rank = 1;
        address current = head;
        
        while (current != userToNode[user]) {
            rank++;
            current = nodes[current].next;
        }
        
        return rank;
    }
}