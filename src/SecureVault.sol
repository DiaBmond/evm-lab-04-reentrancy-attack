// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract SecureVault {
    mapping(address => uint256) public balances;
    uint256 private _status = 1;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        require(success, "Transfer failed");
    }

    modifier nonReentrant() {
        require(_status == 1, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }
}
