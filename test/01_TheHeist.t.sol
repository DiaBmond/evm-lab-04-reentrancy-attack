// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "../src/Attacker.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";

contract TheHeist is Test {
    Attacker attacker;
    VulnerableVault vulnerableVault;

    function setUp() public {
        vulnerableVault = new VulnerableVault();
        // send address contract for vule to construct for attacker
        attacker = new Attacker(vulnerableVault);
    }

    function test_Reentrancy() public {
        address victim = address(1);
        address hacker = address(2);

        //step1 victim deposit 10 ether
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        vulnerableVault.deposit{value: 10 ether}();

        //step2 magical 1 ether for hacker
        vm.deal(hacker, 10 ether);
        vm.prank(hacker);
        attacker.attack{value: 1 ether}(1 ether);

        assertEq(address(vulnerableVault).balance, 0 ether);
        assertEq(address(attacker).balance, 11 ether);
    }
}
