// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title SecureVault
 * @dev A secured version of the vault utilizing the Checks-Effects-Interactions (CEI) pattern
 * and a custom Mutex Lock (Reentrancy Guard) to prevent single-function reentrancy attacks.
 */
contract SecureVault {
    mapping(address => uint256) public balances;

    // Mutex lock state: 1 = unlocked, 2 = locked
    uint256 private _status = 1;

    /**
     * @dev Custom modifier to prevent reentrancy.
     * Locks the state before function execution and unlocks it afterward.
     */
    modifier nonReentrant() {
        require(_status == 1, "ReentrancyGuard: reentrant call");
        _status = 2; // Lock the door
        _;
        _status = 1; // Unlock the door
    }

    /**
     * @dev Allows users to deposit ETH into the vault.
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @dev SECURE FUNCTION: Implements CEI pattern and Reentrancy Guard (Double Layer Protection).
     * @param amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 amount) external nonReentrant {
        // Check: Ensure the user has enough balance
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Effect: Update the state BEFORE interacting with external contracts
        balances[msg.sender] -= amount;

        // Interaction: Safely send ETH after the state is secured
        (bool success,) = payable(msg.sender).call{value: amount}("");

        require(success, "Transfer failed");
    }
}
