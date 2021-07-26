// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/566a774222707e424896c0c390a84dc3c13bdcb2/contracts/access/Ownable.sol";

contract Allowance is Ownable {

    event AllowanceChanged(address indexed _forWho, address indexed _byWhom, uint _oldAmount, uint _newAmount);

    mapping(address => uint) public allowance;

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    function setAllowance(address _who, uint _amount) public onlyOwner {
        require(allowance[msg.sender] >= _amount);
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[msg.sender] -= _amount;
        allowance[_who] += _amount;
    }

    modifier ownerOrAllowed(uint _amount) {
        require(isOwner() || allowance[msg.sender] >= _amount, "You are not allowed!");
        _;
    }

    function reduceAllowance(address _who, uint _amount) internal {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] - _amount);
        allowance[_who] -= _amount;
    }
}

contract SharedWallet is Allowance {

    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);


    function renounceOwnership() public virtual override onlyOwner {
        revert("can't renounceOwnership here"); //not possible with this smart contract
    }

    function allocatableFunds() public view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function accountBalance() public view returns(uint) {
        return allowance[msg.sender];
    }

    function addMoney() public payable onlyOwner{
        allowance[msg.sender] += msg.value;
    }

    function transferMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Top up the Skrilla $$$ brah!");
        if(!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }

    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }

    fallback() external {

    }

}
