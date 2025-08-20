// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {ManualToken} from "../src/ManualToken.sol";

contract ManualTokenTest is Test {
    ManualToken public manualToken;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        manualToken = new ManualToken();

        // Give Alice some initial balance for testing
        // We need to use a lower-level approach since ManualToken doesn't have mint
        // We'll use the transfer function after manually setting a balance
        vm.store(
            address(manualToken),
            keccak256(abi.encode(alice, 0)), // slot 0 is s_balances mapping
            bytes32(uint256(1000 ether))
        );
    }

    // --- Token Properties ---
    function testTokenProperties() public view {
        assertEq(manualToken.name(), "Manual Token");
        assertEq(manualToken.totalSupply(), 100 ether);
        assertEq(manualToken.decimals(), 18);
    }

    // --- Balance Functions ---
    function testBalanceOf() public view {
        assertEq(manualToken.balanceOf(alice), 1000 ether);
        assertEq(manualToken.balanceOf(bob), 0);
    }

    // --- Transfer Functions ---
    function testTransferUpdatesBalances() public {
        uint256 transferAmount = 100 ether;
        uint256 aliceInitialBalance = manualToken.balanceOf(alice);
        uint256 bobInitialBalance = manualToken.balanceOf(bob);

        vm.prank(alice);
        manualToken.transfer(bob, transferAmount);

        assertEq(
            manualToken.balanceOf(alice),
            aliceInitialBalance - transferAmount
        );
        assertEq(
            manualToken.balanceOf(bob),
            bobInitialBalance + transferAmount
        );
    }

    function testTransferFailsWithInsufficientBalance() public {
        uint256 transferAmount = 2000 ether; // More than Alice has

        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        manualToken.transfer(bob, transferAmount);
    }

    function testTransferFailsWithZeroBalance() public {
        vm.prank(bob); // Bob has 0 balance
        vm.expectRevert("Insufficient balance");
        manualToken.transfer(alice, 1);
    }

    function testTransferToSelf() public {
        uint256 transferAmount = 50 ether;
        uint256 initialBalance = manualToken.balanceOf(alice);

        vm.prank(alice);
        manualToken.transfer(alice, transferAmount);

        // Balance should remain the same when transferring to self
        assertEq(manualToken.balanceOf(alice), initialBalance);
    }

    function testTransferZeroAmount() public {
        uint256 aliceInitialBalance = manualToken.balanceOf(alice);
        uint256 bobInitialBalance = manualToken.balanceOf(bob);

        vm.prank(alice);
        manualToken.transfer(bob, 0);

        // Balances should remain unchanged
        assertEq(manualToken.balanceOf(alice), aliceInitialBalance);
        assertEq(manualToken.balanceOf(bob), bobInitialBalance);
    }

    function testTransferEntireBalance() public {
        uint256 aliceBalance = manualToken.balanceOf(alice);

        vm.prank(alice);
        manualToken.transfer(bob, aliceBalance);

        assertEq(manualToken.balanceOf(alice), 0);
        assertEq(manualToken.balanceOf(bob), aliceBalance);
    }
}
