# EVM Lab 04: Reentrancy Attack Research & Prevention

Welcome to my security research sandbox. Following the foundational testing concepts established in Lab 03, this repository dives deep into one of the most devastating and infamous smart contract vulnerabilities in Web3 history: **The Reentrancy Attack**.

This project simulates a complete EVM heist, exploring how manipulating the Call Stack and violating the Checks-Effects-Interactions (CEI) pattern can allow a malicious contract to drain funds. Furthermore, it demonstrates how to engineer robust defenses using custom Mutex locks and strict state-management rules.

## Repository Structure

This project is divided into the core operational directories used in Foundry:

### 1. `src/` (The Vulnerability, The Weapon, & The Shield)

Contains the target contracts and the malicious exploit.

* **`VulnerableVault.sol`**: A vault contract intentionally designed with a critical flaw. It updates the user's balance (`balances[msg.sender] -= amount;`) **after** making an external call to transfer ETH (`msg.sender.call`). This violates the CEI pattern. To accurately simulate this in Solidity 0.8+, the state update is wrapped in an `unchecked` block to allow underflow without reverting the transaction upon trace unwinding.
* **`Attacker.sol`**: The Universal Exploit. It utilizes a generalized `interface IVault` to attack any contract matching the function signatures. The core logic lies in its `receive() external payable` fallback function, which acts as a trapdoor. When it receives ETH, it checks the target's balance and recursively calls `withdraw()` again before the target can update its internal state.
* **`SecureVault.sol`**: The hardened version of the vault. It implements a **Double-Layer Defense**:
1. **CEI Compliance:** State changes occur strictly before external interactions.
2. **Custom Mutex Lock:** A strictly tailored `nonReentrant` modifier using a private `_status` variable (values 1 and 2 for optimal gas usage) to lock the contract state during execution, entirely preventing recursive entries.



### 2. `test/` (Simulating the Heist & The Defense)

Contains the Foundry test suites to prove the vulnerability and the mitigation.

* **`01_TheHeist.t.sol`**: Simulates a devastating attack. A victim deposits 10 ETH. The attacker deposits 1 ETH as "bait" to pass the initial `require` check, then triggers the exploit. The test proves via `assertEq()` that the EVM is tricked into transferring 11 ETH to the attacker, leaving the vault at 0.
* **`02_TheDefense.t.sol`**: Points the exact same `Attacker` contract at the `SecureVault`. Utilizing `vm.expectRevert()`, it proves that the Mutex lock successfully catches the recursive call, reverts the entire transaction, and keeps the victim's 10 ETH perfectly safe.

---

## Core Concepts Mastered

Through this lab, I have deeply analyzed and implemented the following security concepts:

* **Single-Function Reentrancy:** Understanding how the EVM pauses the execution of a calling contract to execute a receiving contract's fallback logic.
* **Checks-Effects-Interactions (CEI) Pattern:** The golden rule of smart contract development; realizing the catastrophic consequences of placing "Interactions" before "Effects".
* **Mutex Locks (Mutual Exclusion):** Engineering custom Reentrancy Guards from scratch without relying on external libraries like OpenZeppelin.
* **Interfaces & Function Selectors:** Understanding that EVM execution relies on 4-byte function signatures, allowing attackers to exploit contracts using minimal interfaces without needing the victim's source code.

---

## Deep Dive: EVM Call Trace Analysis

By executing the test suite with maximum verbosity (`-vvvv`), we can observe the exact moment the EVM Call Stack is hijacked.

### The Heist Trace Analysis (`01_TheHeist.t.sol`)

```text
  ├─ [144010] Attacker::attack{value: 1000000000000000000}(1000000000000000000 [1e18])
  │  ├─ [22413] VulnerableVault::deposit{value: 1000000000000000000}()
  │  ├─ [111751] VulnerableVault::withdraw(1000000000000000000 [1e18])
  │  │  ├─ [104131] Attacker::receive{value: 1000000000000000000}()
  │  │  │  ├─ [103358] VulnerableVault::withdraw(1000000000000000000 [1e18])
  │  │  │  │  ├─ [95738] Attacker::receive{value: 1000000000000000000}()
...
```

**What is happening here?** This is the **"Inception"** effect. The `VulnerableVault` sends ETH via `.call`. This immediately triggers the `Attacker`'s `receive()` function. Because the Vault's state (`balances`) hasn't been reduced yet, the `Attacker` calls `withdraw()` again. The EVM stacks these calls one on top of another (recursion). The Vault continues to approve the withdrawals because it believes the attacker still has a 1 ETH balance, repeating this loop until the Vault is completely drained.

### The Defense Trace Analysis (`02_TheDefense.t.sol`)

```text
  ├─ [0] VM::expectRevert(custom error 0xf4844814)
  ├─ [46428] Attacker::attack{value: 1000000000000000000}(1000000000000000000 [1e18])
  │  ├─ [22413] SecureVault::deposit{value: 1000000000000000000}()
  │  ├─ [14163] SecureVault::withdraw(1000000000000000000 [1e18])
  │  │  ├─ [1227] Attacker::receive{value: 1000000000000000000}()
  │  │  │  ├─ [438] SecureVault::withdraw(1000000000000000000 [1e18])
  │  │  │  │  └─ ← [Revert] ReentrancyGuard: reentrant call
  │  │  │  └─ ← [Revert] ReentrancyGuard: reentrant call
  │  │  └─ ← [Revert] Transfer failed
  │  └─ ← [Revert] Transfer failed
  └─ ← [Stop]
```

**The Shield in action:** The attacker successfully initiates the first `withdraw()` and receives the first ETH, which triggers their `receive()` trapdoor. However, when the attacker recursively calls `withdraw()` a second time, the `SecureVault`'s `nonReentrant` modifier catches them. Because `_status` was set to `2` (Locked) on the first entry, the `require(_status == 1)` check fails. This triggers a massive cascading `[Revert]`, undoing the entire transaction and protecting all funds.

---

## How to Run the Experiments

To replicate this environment, ensure you have [Foundry](https://getfoundry.sh/) installed.

**1. Run the entire test suite (Standard output):**

```bash
forge test
```

**2. Observe the Reentrancy Call Stack (Maximum verbosity):**

```bash
forge test -vvvv
```

**3. Test only the Heist:**

```bash
forge test --match-test test_Reentrancy --match-contract TheHeist -vvvv
```

**4. Test only the Defense:**

```bash
forge test --match-test test_Reentrancy --match-contract TheDefense -vvvv
```

---

*Disclaimer: This repository is strictly for educational purposes and security research. Do not deploy these vulnerable contracts to a live network.*
