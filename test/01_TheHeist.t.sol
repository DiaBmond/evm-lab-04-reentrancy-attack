// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "../src/Attacker.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";

/**
 * @title TheHeist
 * @dev Foundry test to simulate a successful single-function reentrancy attack
 * on the VulnerableVault. It proves that the EVM call stack can be hijacked.
 */
contract TheHeist is Test {
    Attacker attacker;
    VulnerableVault vulnerableVault;

    /**
     * @dev Deploys the target vault and the attacker contract.
     * Passes the vulnerable vault's address to the attacker's constructor.
     */
    function setUp() public {
        vulnerableVault = new VulnerableVault();
        // Send address of the vulnerable contract to construct the universal attacker
        attacker = new Attacker(address(vulnerableVault));
    }

    /**
     * @dev Executes the heist to prove the vulnerability.
     * Expects the attacker to drain all funds from the vault.
     */
    function test_Reentrancy() public {
        // Define actors
        address victim = address(1);
        address hacker = address(2);

        // Step 1: The Bait - Victim deposits 10 ether into the vault
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        vulnerableVault.deposit{value: 10 ether}();

        // Step 2: The Attack - Provide magical 1 ether for hacker's initial deposit
        vm.deal(hacker, 10 ether);
        vm.prank(hacker);

        // Hacker triggers the inception loop using 1 ether as bait
        attacker.attack{value: 1 ether}(1 ether);

        // Step 3: The Verification - Check the devastating results
        // The vault should be completely drained (0 ether)
        assertEq(address(vulnerableVault).balance, 0 ether);
        // The attacker should have stolen the 10 ether + kept their 1 ether bait (11 ether total)
        assertEq(address(attacker).balance, 11 ether);
    }
}
