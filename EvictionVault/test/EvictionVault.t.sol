// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {EvictionVault} from "../src/EvictionVault.sol";
import {IEvictVault} from "../src/Interface/IEvictVault.sol";

contract EvictionVaultTest is Test {
    EvictionVault vault;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address admin = address(0xA);
    address user = address(0xB);
    address recipient = address(0xC);

    address[] owners;

    function setUp() public {
        // Initialize owners array
        owners = new address ;
        owners[0] = owner1;
        owners[1] = owner2;

        // Fund owners and user
        vm.deal(owner1, 10 ether);
        vm.deal(owner2, 10 ether);
        vm.deal(user, 5 ether);
        vm.deal(admin, 10 ether);

        // Deploy vault with 1 ether initial balance
        vm.prank(admin);
        vault = new EvictionVault{value: 1 ether}(owners, 2, admin);
    }

    function testDepositAndWithdraw() public {
        // Deposit from user
        vm.prank(user);
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(user), 1 ether);

        // Withdraw half
        vm.prank(user);
        vault.withdraw(0.5 ether);
        assertEq(vault.balances(user), 0.5 ether);
    }

    function testSubmitConfirmExecuteTransaction() public {
        // Owner1 submits a transaction
        vm.prank(owner1);
        vault.submitTransaction(recipient, 1 ether, "");

        // Owner2 confirms
        vm.prank(owner2);
        vault.confirmTransaction(0);

        // Fast forward 1 hour to pass timelock
        vm.warp(block.timestamp + 3600);

        // Execute transaction
        vm.prank(owner1);
        vault.executeTransaction(0);

        // Vault value reduced
        assertEq(vault.totalVaultValue(), 0);
    }

    function testSetMerkleRootAndClaim() public {
        bytes32 leaf = keccak256(abi.encodePacked(user, 1 ether));

        // Simple proof (empty array for testing)
        bytes32 ;

        // Only admin can set root
        vm.prank(admin);
        vault.setMerkleRoot(leaf);

        // Fund vault
        vm.deal(address(vault), 1 ether);

        // Claim funds
        vm.prank(user);
        vault.claim(proof, 1 ether);

        assertTrue(vault.claimed(user));
    }

    function testEmergencyWithdraw() public {
        // Fund vault
        vm.deal(address(vault), 1 ether);

        // Only admin can call
        vm.prank(admin);
        vault.emergencyWithdrawAll();

        assertEq(vault.totalVaultValue(), 0);
    }

    function testPauseAndUnpause() public {
        // Pause
        vm.prank(admin);
        vault.pause();
        assertTrue(vault.paused());

        // Unpause
        vm.prank(admin);
        vault.unpause();
        assertFalse(vault.paused());
    }
}