// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    // bytes32 public _requestId;
    bytes32 public _requestId = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    
    uint256 public randomResult;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId = requestRandomness(keyHash, fee);
        _requestId = requestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    /**
     * Withdraw LINK from this contract
     * 
     * DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES.
     */
    function withdrawLink() external {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}

contract NumberGuessingGame is ReentrancyGuard, Ownable, RandomNumberConsumer {

    // 转账事件
    event TransferEvent(address indexed _from, address indexed _to, uint indexed _amount);

    uint public startTime;
    uint public endTime;

    uint public counts;

    struct Wanjia {
        address account;
        uint number;
        bool isInput;
        bool hasInput;
    }

    mapping(address => Wanjia) public addrToWanjia;

    address[] public playersArray;

    // 自定义游戏开始时间和结束时间
    constructor(uint _startTime,uint _deadline) payable {
        require(msg.value == 0.00001 ether,"deploy need 1 ether!");

        startTime = _startTime;
        endTime = _deadline + startTime;
    }

    // 玩家输入一个任意值
    function player_input(uint _number) payable external {
        Wanjia storage wanjia = addrToWanjia[msg.sender];

        require(block.timestamp <= endTime , "Too late!");
        require(wanjia.isInput == false,"account had input before");
        require(wanjia.hasInput == false,"number had input before");
        require(msg.value == 0.00005 ether,"must give 0.5 ether to contract");
        require(counts < 2,"must two accounts are allowed!");

        addrToWanjia[msg.sender] = Wanjia({
            account: msg.sender,
            number: _number,
            isInput: true,
            hasInput: true
        });

        playersArray.push(msg.sender);

        counts++;

    }

    // 开始游戏,只有创建游戏的玩家A可以操作
    function pickWinner() external nonReentrant {
        _pickWinner();
    }   

    function _pickWinner() internal {
        // require(block.timestamp >= endTime,"time not over yet!");
        require(msg.sender == owner(),"only owner can pickWinner");
        require(address(this).balance >= 0.000001 ether,"not enough balance in contract!");
        require(playersArray[0] != address(0x0) || playersArray[1] != address(0x0),"0x0 is not allowed!");

        Wanjia storage wanjia0 = addrToWanjia[playersArray[0]];
        Wanjia storage wanjia1 = addrToWanjia[playersArray[1]];

        uint playerA_NUM = wanjia0.number;
        uint playerB_NUM = wanjia1.number;

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
        payable(playersArray[0]).transfer(0.00001 ether);
        // 监听转账事件
        emit TransferEvent(address(this),playersArray[0],1 ether);

        tool();
    }

    function _playerB_winer() internal {
        payable(playersArray[1]).transfer(0.00001 ether);
        // 监听转账事件
        emit TransferEvent(address(this),playersArray[1],1 ether);
            
        tool();
    }

    function tool() internal {
        Wanjia storage wanjia0 = addrToWanjia[playersArray[0]];
        Wanjia storage wanjia1 = addrToWanjia[playersArray[1]];

        wanjia0.number = wanjia1.number = 0;
        wanjia0.hasInput = wanjia1.hasInput = false;
        wanjia0.isInput = wanjia1.isInput = false;
        playersArray = new address[](0);
        counts = 0;
    }

    function _getRandom(uint num1,uint num2) internal view returns(uint) {
        require(_requestId != 0x0,"requestId 0x0 error!");
        uint256 random = bytes32ToUint(_requestId) % 2; 

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

    // bytes32 转 uint
    function bytes32ToUint(bytes32  _number) internal pure returns (uint256){
        uint number;
        for(uint i= 0; i<_number.length; i++){
            number = number + uint8(_number[i])*(2**(8*(_number.length-(i+1))));
        }
        return  number;
    }

}
