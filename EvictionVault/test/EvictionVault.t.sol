// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";



contract EvictionVaultTest is Test {
    EvictionVault vault;
    address owner;
    address user;

    function setUp() public {
        owner = address(this);
        user = address(1);

        vault = new EvictionVault();

        vm.deal(user, 10 ether);
    }

    // Deposit Test
    function testDepositETH() public {
        vm.prank(user);
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success);

        uint256 balance = vault.balances(user);
        assertEq(balance, 1 ether);
    }

    // Withdraw Test
    function testWithdrawETH() public {
        vm.startPrank(user);
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success);

        vault.withdraw(1 ether);
        vm.stopPrank();

        assertEq(user.balance, 10 ether);
        assertEq(vault.balances(user), 0);
    }

    // Pause Test
    function testPauseSystem() public {
        vault.pause();
        bool pausedState = vault.paused();
        assertTrue(pausedState);
    }

    // Multiple Deposits
    function testMultipleDeposits() public {
        vm.startPrank(user);
        (bool s1,) = address(vault).call{value: 1 ether}("");
        (bool s2,) = address(vault).call{value: 1 ether}("");
        require(s1 && s2);
        vm.stopPrank();

        assertEq(vault.balances(user), 2 ether);
    }

    // Withdraw Partial
    function testWithdrawPartial() public {
        vm.startPrank(user);
        (bool s,) = address(vault).call{value: 2 ether}("");
        require(s);

        vault.withdraw(1 ether);
        vm.stopPrank();

        assertEq(vault.balances(user), 1 ether);
        assertEq(user.balance, 9 ether);
    }

    // Cannot Over Withdraw
    function testCannotOverWithdraw() public {
        vm.startPrank(user);
        (bool s,) = address(vault).call{value: 1 ether}("");
        require(s);

        vm.expectRevert();
        vault.withdraw(2 ether);
        vm.stopPrank();
    }

    // Deposit Reverts When Paused
    function testDepositRevertsWhenPaused() public {
        vault.pause();
        vm.prank(user);
        vm.expectRevert();
        (bool s,) = address(vault).call{value: 1 ether}("");
    }

    // Only Owner Can Pause
    function testOnlyOwnerCanPause() public {
        vm.prank(user);
        vm.expectRevert();
        vault.pause();

        vault.pause(); // owner can pause
        assertTrue(vault.paused());
    }

    

}