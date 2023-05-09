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

    // 玩家
    struct Players {
        mapping(address => uint) accountToNum;
        mapping(address => bool) isInput;
        mapping(uint => bool) hasInput;
    }
    
    Players players;

    address[] public playersArray;

    // 自定义游戏开始时间和结束时间
    // constructor(uint _startTime,uint _deadline) {
    //     player.playerA = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    //     player.playerB = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    //     startTime = _startTime;
    //     endTime = _deadline + startTime;
    // }

    constructor() payable {
        require(msg.value == 1 ether,"deploy need 1 ether!");
        startTime = block.timestamp;
        endTime = 10 minutes + startTime;
    }

    // 玩家输入一个任意值
    function player_input(uint _number) payable external {
        require(block.timestamp <= endTime , "Too late!");
        require(players.isInput[msg.sender] == false,"account had input before");
        require(players.hasInput[_number] == false,"number had input before");
        require(msg.value == 0.5 ether,"must give 0.5 ether to contract");
        require(counts < 2,"must two accounts are allowed!");

        playersArray.push(msg.sender);

        counts++;

        players.accountToNum[msg.sender] = _number;
        players.isInput[msg.sender] = true;
        players.hasInput[_number] = true;
    }

    // 开始游戏,只有创建游戏的玩家A可以操作
    function pickWinner() external nonReentrant {
        // require(block.timestamp >= endTime,"time not over yet!");
        require(msg.sender == owner(),"only owner can pickWinner");
        require(address(this).balance >= 1 ether,"not enough balance in contract!");
        require(playersArray[0] != address(0x0) || playersArray[1] != address(0x0),"0x0 is not allowed!");

        uint playerA_NUM = players.accountToNum[playersArray[0]];
        uint playerB_NUM = players.accountToNum[playersArray[1]];

        uint avg_num = (playerA_NUM + playerB_NUM) / 2;

        // 如果随机数大于平均值
        if(_getRandom(playerA_NUM,playerB_NUM) > avg_num){
            payable(playersArray[0]).transfer(1 ether);
            // 监听转账事件
            emit TransferEvent(address(this),playersArray[0],1 ether);

            players.accountToNum[playersArray[0]] = 0;
            players.accountToNum[playersArray[1]] = 0;

            players.hasInput[playerA_NUM] = false;
            players.hasInput[playerB_NUM] = false;

            players.isInput[playersArray[0]] = false;
            players.isInput[playersArray[1]] = false;

            playersArray = new address[](0);

            counts = 0;
        }

        // 如果随机数小于平均值
        if(_getRandom(playerA_NUM,playerB_NUM) < avg_num){
             payable(playersArray[1]).transfer(1 ether);
            // 监听转账事件
            emit TransferEvent(address(this),playersArray[1],1 ether);
            
            players.accountToNum[playersArray[0]] = 0;
            players.accountToNum[playersArray[1]] = 0;

            players.hasInput[playerA_NUM] = false;
            players.hasInput[playerB_NUM] = false;

            players.isInput[playersArray[1]] = false;
            players.isInput[playersArray[1]] = false;

            playersArray = new address[](0);

            counts = 0;
        }
    }   

    // 获取账户eth的余额
    function getBalance(address _address) external view returns(uint) {
        return _address.balance;
    }

    // 合约内eth的总额
    function total() external view returns(uint) {
        return address(this).balance;
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
