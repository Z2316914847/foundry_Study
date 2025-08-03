// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint256) public balances;
    mapping(address => address) public nextUser; // 用更清晰的命名替代 total_top10
    address constant GUARD = address(1);
    uint256 public listSize;
    uint256 public constant MAX_TOP = 3; // 明确排名数量限制  最多4个人上部署者

    constructor() payable {
        nextUser[GUARD] = GUARD; // 初始化守卫节点指向自己
        balances[msg.sender] = msg.value;
        listSize = 1;
    }

    receive() external payable {
        deposit();
    }

    // 修正函数名并优化逻辑
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be positive");
        
        // 更新余额
        balances[msg.sender] += msg.value;
        
        // 如果是新用户且列表未满，增加列表大小
        if (nextUser[msg.sender] == address(0) && listSize < MAX_TOP) {
            listSize++;
        }
        
        // 更新排名
        _updateRank(msg.sender, balances[msg.sender]);
    }

    // 完整的排名更新逻辑
    function _updateRank(address addr, uint256 amount) private {
        address current = nextUser[GUARD];
        address prev = GUARD;
        uint256 count = 0;

        // 遍历链表找到插入位置
        while (current != GUARD && count < MAX_TOP) {
            if (balances[current] < amount) {
                break;
            }
            prev = current;
            current = nextUser[current];
            count++;
        }

        // 如果已在链表中，先移除
        if (nextUser[addr] != address(0)) {
            _removeFromRank(addr);
        }

        // 插入到合适位置
        nextUser[addr] = current;
        nextUser[prev] = addr;

        // 如果超过最大排名，移除最后一个
        if (listSize > MAX_TOP) {
            _removeLastFromRank();
        }
    }

    // 从链表中移除节点
    function _removeFromRank(address addr) private {
        address current = nextUser[GUARD];
        address prev = GUARD;

        while (current != GUARD) {
            if (current == addr) {
                nextUser[prev] = nextUser[current];
                nextUser[current] = address(0);
                listSize--;
                return;
            }
            prev = current;
            current = nextUser[current];
        }
    }

    // 移除链表最后一个节点
    function _removeLastFromRank() private {
        address current = nextUser[GUARD];
        address prev = GUARD;

        while (nextUser[current] != GUARD) {
            prev = current;
            current = nextUser[current];
        }

        nextUser[prev] = GUARD;
        nextUser[current] = address(0);
        listSize--;
    }

    // 获取排名信息
    function getTopUsers(uint256 n) public view returns (address[] memory) {
        require(n <= MAX_TOP && n <= listSize, "Invalid number of top users");
        
        address[] memory topUsers = new address[](n);
        address current = nextUser[GUARD];
        
        for (uint256 i = 0; i < n && current != GUARD; i++) {
            topUsers[i] = current;
            current = nextUser[current];
        }
        
        return topUsers;
    }
}