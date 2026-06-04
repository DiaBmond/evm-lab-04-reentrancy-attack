// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title VulnerableVault
 * @dev A vault contract intentionally designed with a Reentrancy vulnerability.
 * Demonstrates the danger of violating the Checks-Effects-Interactions (CEI) pattern.
 */
contract VulnerableVault {
    mapping(address => uint256) public balances;

    /**
     * @dev Allows users to deposit ETH into the vault.
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @dev VULNERABLE FUNCTION: Bypasses the CEI pattern.
     * The external call (Interaction) is made BEFORE updating the balance (Effect).
     * This allows a malicious contract to recursively call withdraw() before its balance is zeroed.
     * @param amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 amount) external {
        // Check: Ensure the user has enough balance
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Interaction: Send ETH to the user BEFORE updating state (VULNERABILITY!)
        (bool success,) = payable(msg.sender).call{value: amount}("");

        // Effect: Update the balance (This is reached too late during a reentrancy attack)
        unchecked {
            balances[msg.sender] -= amount;
        }

        require(success, "Transfer failed");
    }
}
