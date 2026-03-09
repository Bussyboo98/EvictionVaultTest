### EvictionVault

EvictionVault is a secure Ethereum vault built for multiple owners. It supports multi-signature transactions with timelocks, Merkle-based claims for distributing funds, and emergency withdrawals for admins. This project modularizes the original single-file vault and fixes critical security issues.

What’s Inside

Multi-signature transaction support with a configurable threshold.

Timelock execution to prevent instant fund transfers.

Merkle tree-based claims for safe, verifiable distribution.

Deposit and withdrawal functionality for individual users.

Admin-only emergency withdrawals.

Ability to pause the contract in emergencies.

Reentrancy protection on all critical operations.

Safe Ether transfers using .call instead of .transfer.

Project Structure

Here’s a quick look at how the project is organized:

EvictionVault/
│
├─ contracts/
│   ├─ EvictionVault.sol            # Main vault contract
│   ├─ EvictionVaultAccessControl.sol # Access control for owners/admin
│   └─ interfaces/
│       └─ IEvictionVault.sol      # Vault interface
│
├─ test/
│   └─ EvictionVault.t.sol         # Basic tests
│
│
└─ README.md

Security Fixes Implemented
Problem	How We Fixed It
setMerkleRoot callable by anyone	Only admins can set the Merkle root now
emergencyWithdrawAll could be called by anyone	Restricted to admins; removed unsafe duplicate function
pause / unpause controlled by a single owner	Only admins can pause/unpause the contract
receive() used tx.origin	Replaced with msg.sender to avoid phishing risks
Withdrawals and claims used .transfer	Now use safe .call{value: amount}("")
Timelock execution not enforced	Execution requires confirmations and timelock duration

How to Set It Up

Clone the repository:

git clone https://github.com/yourusername/EvictionVault.git

cd EvictionVault

Install dependencies:

forge install

Compile the contracts:

forge build

Testing

The project includes basic tests to verify key functionality:

Deposits and withdrawals

Multi-sig transaction submission, confirmation, and execution

Merkle claim verification

Admin emergency withdrawals

Run tests with:

forge test


License

This project is released under the MIT License.