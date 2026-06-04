// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "../src/Attacker.sol";
import {SecureVault} from "../src/SecureVault.sol";

/**
 * @title TheDefense
 * @dev Foundry test to verify the effectiveness of the Checks-Effects-Interactions (CEI)
 * pattern and the custom Reentrancy Guard. Proves that the shield holds against the attack.
 */
contract TheDefense is Test {
    Attacker attacker;
    SecureVault secureVault;

    /**
     * @dev Deploys the secured target vault and the attacker contract.
     * Passes the secure vault's address to the attacker's constructor.
     */
    function setUp() public {
        secureVault = new SecureVault();
        // Send address of the secure contract to construct the universal attacker
        attacker = new Attacker(address(secureVault));
    }

    /**
     * @dev Attempts the same heist on the secured vault.
     * Expects the transaction to revert and the victim's funds to remain safe.
     */
    function test_Reentrancy() public {
        // Define actors
        address victim = address(1);
        address hacker = address(2);

        // Step 1: The Bait - Victim deposits 10 ether into the secured vault
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        secureVault.deposit{value: 10 ether}();

        // Step 2: The Setup - Provide magical 1 ether for hacker's initial deposit
        vm.deal(hacker, 10 ether);
        vm.prank(hacker);

        // Step 3: The Defense - Anticipate the trapdoor revert
        // The Mutex lock (_status) will block the recursive call and revert the entire transaction
        vm.expectRevert();

        // Hacker attempts to trigger the inception loop
        attacker.attack{value: 1 ether}(1 ether);

        // Step 4: The Verification - Ensure the shield held
        // The victim's 10 ether must still be safely stored in the vault
        assertEq(address(secureVault).balance, 10 ether);
    }
}
