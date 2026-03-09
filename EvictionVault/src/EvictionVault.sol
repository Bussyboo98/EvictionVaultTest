// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IEvictVault} from "./interface/IEvictVault.sol";
import {EvictionVaultAccessControl} from "./EvictionVaultAccessControl.sol";


contract EvictionVault is IEvictVault, EvictionVaultAccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    uint256 public threshold;
    uint256 public txCount;
    uint256 public totalVaultValue;
    bytes32 public merkleRoot;

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;
    mapping(address => uint256) public balances;
    mapping(address => bool) public claimed;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    constructor(address[] memory _owners, uint256 _threshold, address _admin)
        EvictionVaultAccessControl(_admin)
        payable
    {
        require(_owners.length > 0, "No owners provided");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

        threshold = _threshold;

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            _grantRole(OWNER_ROLE, owner);
        }

        totalVaultValue = msg.value;
    }

    receive() external payable {
        _deposit(msg.sender, msg.value);  
    }

    function deposit() external payable override {
        _deposit(msg.sender, msg.value);
    }

    function _deposit(address account, uint256 amount) internal {
        balances[account] += amount;
        totalVaultValue += amount;
        emit Deposit(account, amount);
    }

    function withdraw(uint256 amount) external override whenNotPaused nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        totalVaultValue -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(msg.sender, amount);
    }

    function submitTransaction(address to, uint256 value, bytes calldata data) external 
    override onlyRole(OWNER_ROLE) whenNotPaused {
        uint256 id = txCount++;
        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });
        confirmed[id][msg.sender] = true;
        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external override onlyRole(OWNER_ROLE) whenNotPaused {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "Transaction already executed");
        require(!confirmed[txId][msg.sender], "Already confirmed");

        confirmed[txId][msg.sender] = true;
        txn.confirmations++;

        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }

        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external override whenNotPaused nonReentrant {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold, "Insufficient confirmations");
        require(!txn.executed, "Already executed");
        require(block.timestamp >= txn.executionTime, "Timelock not expired");

        txn.executed = true;

        if (txn.value > 0) {
            require(totalVaultValue >= txn.value, "Vault value insufficient");
            totalVaultValue -= txn.value;
        }

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Execution failed");

        emit Execution(txId);
    }

    function setMerkleRoot(bytes32 root) external override onlyRole(ADMIN_ROLE) {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount) external override whenNotPaused nonReentrant {
        require(!claimed[msg.sender], "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        claimed[msg.sender] = true;
        totalVaultValue -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Claim transfer failed");

        emit Claim(msg.sender, amount);
    }

    function emergencyWithdrawAll() external override onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        totalVaultValue = 0;

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Emergency withdrawal failed");
    }

    function verifySignature(address signer, bytes32 messageHash, bytes memory signature) external pure returns (bool) {
    return messageHash.toEthSignedMessageHash().recover(signature) == signer;

    }
    

    function pause() external override onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() external override onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function paused() public view override(IEvictVault, EvictionVaultAccessControl) returns (bool) {
        return super.paused();
    }

}