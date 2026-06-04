// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // VULNERABILITY: Intentionally violating the CEI (Checks-Effects-Interactions) pattern.
        // Interaction (external call) occurs BEFORE the Effect (state update), enabling reentrancy.
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        balances[msg.sender] -= amount;
        require(success, "Transfer failed");
    }
}
