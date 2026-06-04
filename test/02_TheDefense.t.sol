// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "../src/Attacker.sol";
import {SecureVault} from "../src/SecureVault.sol";

contract TheDefense is Test {
    Attacker attacker;
    SecureVault secureVault;

    function setUp() public {
        secureVault = new SecureVault();
        // send address contract for vule to construct for attacker
        attacker = new Attacker(address(secureVault));
    }

    function test_Reentrancy() public {
        address victim = address(1);
        address hacker = address(2);

        //step1 victim deposit 10 ether
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        secureVault.deposit{value: 10 ether}();

        //step2 magical 1 ether for hacker
        vm.deal(hacker, 10 ether);
        vm.prank(hacker);
        vm.expectRevert();
        attacker.attack{value: 1 ether}(1 ether);

        assertEq(address(secureVault).balance, 10 ether);
    }
}
