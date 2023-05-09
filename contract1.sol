// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NumberGuessingGame is ReentrancyGuard, Ownable {

    // 转账事件
    event TransferEvent(address indexed _from, address indexed _to, uint indexed _amount);

    uint public startTime;
    uint public endTime;

    // 玩家
    struct Player {
        address playerA;
        address playerB;
    }

    Player public player;

    mapping(address => uint) public accountToNum;
    mapping(address => bool) public isInput;
    

    // 自定义游戏开始时间和结束时间
    // constructor(uint _startTime,uint _deadline) {
    //     player.playerA = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    //     player.playerB = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    //     startTime = _startTime;
    //     endTime = _deadline + startTime;
    // }

    constructor() payable {
        require(msg.value == 1 ether,"deploy need 1 ether!");
        player.playerA = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        player.playerB = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

        startTime = block.timestamp;
        endTime = 10 minutes + startTime;
    }

    // 玩家输入一个任意值
    function player_input(uint _number) payable external {
        require(msg.value == 0.5 ether,"must give 0.5 ether to contract");
        require(msg.sender == player.playerA || msg.sender == player.playerB,"you do not have right!");
        require(block.timestamp <= endTime , "Too late!");
        require(isInput[msg.sender] == false,"had input before");

        accountToNum[msg.sender] = _number;
        isInput[msg.sender] = true;
    }

    // 开始游戏,只有创建游戏的玩家A可以操作
    function pickWinner() external nonReentrant {
       _pickWinner();
    }   

    // 获取账户eth的余额
    function getBalance(address _address) external view returns(uint) {
        return _address.balance;
    }

    // 合约内eth的总额
    function total() external view returns(uint) {
        return address(this).balance;
    }

    function _pickWinner() internal {
        // require(block.timestamp >= endTime,"time not over yet!");
        require(msg.sender == owner(),"only owner can pickWinner");
        require(address(this).balance >= 1 ether,"not enough balance in contract!");

        uint playerA_NUM = accountToNum[player.playerA];
        uint playerB_NUM = accountToNum[player.playerB];

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
        payable(player.playerA).transfer(1 ether);
        // 监听转账事件
        emit TransferEvent(address(this),player.playerA,1 ether);

        isInput[player.playerA] = false;
        isInput[player.playerB] = false;
    }

    function _playerB_winer() internal {
        payable(player.playerB).transfer(1 ether);
        // 监听转账事件
        emit TransferEvent(address(this),player.playerB,1 ether);

        isInput[player.playerA] = false;
        isInput[player.playerB] = false;
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

}
