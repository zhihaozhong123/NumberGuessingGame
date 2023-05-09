// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NumberGuessingGame is ReentrancyGuard, Ownable {

    // 转账事件
    event TransferEvent(address indexed _from, address indexed _to, uint indexed _amount);

    uint public startTime;
    uint public endTime;

    uint public counts;

    address[] public playersArray;

    mapping(address => uint) public accountToNum;
    mapping(address => bool) public isInput;
    mapping(uint => bool) public hasInput;

    // 自定义游戏开始时间和结束时间
    constructor(uint _startTime,uint _deadline) payable {
        require(msg.value == 1 ether,"deploy need 1 ether!");

        startTime = _startTime;
        endTime = _deadline + startTime;
    }

    // 玩家输入一个任意值
    function player_input(uint _number) payable external {
        require(block.timestamp <= endTime , "Too late!");
        require(isInput[msg.sender] == false,"account had input before");
        require(hasInput[_number] == false,"number had input before");
        require(msg.value == 0.5 ether,"must give 0.5 ether to contract");
        require(counts < 2,"must two accounts are allowed!");

        playersArray.push(msg.sender);

        counts++;

        accountToNum[msg.sender] = _number;
        isInput[msg.sender] = true;
        hasInput[_number] = true;
    }

    // 开始游戏,只有创建游戏的玩家A可以操作
    function pickWinner() external nonReentrant {
        _pickWinner();
    }   

    function _pickWinner() internal {
        // require(block.timestamp >= endTime,"time not over yet!");
        require(msg.sender == owner(),"only owner can pickWinner");
        require(address(this).balance >= 1 ether,"not enough balance in contract!");
        require(playersArray[0] != address(0x0) || playersArray[1] != address(0x0),"0x0 is not allowed!");

        uint playerA_NUM = accountToNum[playersArray[0]];
        uint playerB_NUM = accountToNum[playersArray[1]];

        uint avg_num = (playerA_NUM + playerB_NUM) / 2;

        // 如果随机数大于平均值
        if(_getRandom(playerA_NUM,playerB_NUM) > avg_num){
            _playerA_winer();
        }

        // 如果随机数小于平均值
        if(_getRandom(playerA_NUM,playerB_NUM) < avg_num){
            _playerB_winer();
        }
    }  

    function _playerA_winer() internal {
        payable(playersArray[0]).transfer(1 ether);
        // 监听转账事件
        emit TransferEvent(address(this),playersArray[0],1 ether);

        tool();
    }

    function _playerB_winer() internal {
        payable(playersArray[1]).transfer(1 ether);
        // 监听转账事件
        emit TransferEvent(address(this),playersArray[1],1 ether);

        tool();
    }

    function tool() internal nonReentrant {
        accountToNum[playersArray[0]] = 0;
        accountToNum[playersArray[1]] = 0;

        hasInput[accountToNum[playersArray[0]]] = false;
        hasInput[accountToNum[playersArray[1]]] = false;

        isInput[playersArray[0]] = false;
        isInput[playersArray[1]] = false;

        playersArray = new address[](0);

        counts = 0;
    }

    function _getRandom(uint num1,uint num2) internal view returns(uint) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.coinbase,block.prevrandao, block.timestamp))) % 2;

        if(random == 0) return num1;
        if(random == 1) return num2;

        return 0;
    }

    function emergencyWithdraw() payable external {
        payable(owner()).transfer(address(this).balance);
        emit TransferEvent(address(this),owner(),address(this).balance);
    }    

    // 获取账户eth的余额
    function getBalance(address _address) external view returns(uint) {
        return _address.balance;
    }

    // 合约内eth的总额
    function total() external view returns(uint) {
        return address(this).balance;
    }

}
