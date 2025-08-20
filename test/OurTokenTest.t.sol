// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployOurToken;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address deployer;
    uint256 public initialSupply;

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployOurToken = new DeployOurToken();
        initialSupply = deployOurToken.INITIAL_SUPPLY();

        // Deploy the token directly so we control who gets the initial supply
        ourToken = new OurToken(initialSupply);
        deployer = address(this);

        // Give Bob some tokens
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    // --- Deployment ---
    function testTokenProperties() public {
        assertEq(ourToken.name(), "OurToken");
        assertEq(ourToken.symbol(), "OT");
        assertEq(ourToken.decimals(), 18);
    }

    function testInitialSupplyAssignedToDeployer() public {
        uint256 total = ourToken.totalSupply();
        assertEq(ourToken.balanceOf(deployer), total - STARTING_BALANCE);
    }

    // --- Transfers ---
    function testBobBalance() public {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testTransferUpdatesBalances() public {
        uint256 amount = 10 ether;

        vm.prank(bob);
        ourToken.transfer(alice, amount);

        assertEq(ourToken.balanceOf(alice), amount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - amount);
    }

    function testTransferFailsIfNotEnoughBalance() public {
        uint256 tooMuch = STARTING_BALANCE + 1;
        vm.prank(bob);
        vm.expectRevert(); // ERC20: transfer amount exceeds balance
        ourToken.transfer(alice, tooMuch);
    }

    // --- Allowances ---
    function testAllowances() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(
            ourToken.allowance(bob, alice),
            initialAllowance - transferAmount
        );
    }

    function testTransferFromFailsIfAllowanceTooLow() public {
        uint256 approval = 5 ether;

        vm.prank(bob);
        ourToken.approve(alice, approval);

        vm.prank(alice);
        vm.expectRevert(); // ERC20: insufficient allowance
        ourToken.transferFrom(bob, alice, approval + 1);
    }

    // --- Events ---
    function testApprovalEventEmitted() public {
        vm.expectEmit(true, true, false, true);
        emit Approval(bob, alice, 100);

        vm.prank(bob);
        ourToken.approve(alice, 100);
    }

    function testTransferEventEmitted() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, 50);

        vm.prank(bob);
        ourToken.transfer(alice, 50);
    }

    // Pull in ERC20 events for vm.expectEmit
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // --- Additional Edge Cases ---
    function testTransferToZeroAddress() public {
        vm.prank(bob);
        vm.expectRevert(); // Should revert when transferring to zero address
        ourToken.transfer(address(0), 1 ether);
    }

    function testTransferFromToZeroAddress() public {
        uint256 approval = 10 ether;

        vm.prank(bob);
        ourToken.approve(alice, approval);

        vm.prank(alice);
        vm.expectRevert(); // Should revert when transferring to zero address
        ourToken.transferFrom(bob, address(0), 1 ether);
    }

    function testApproveZeroAmount() public {
        vm.prank(bob);
        ourToken.approve(alice, 0);

        assertEq(ourToken.allowance(bob, alice), 0);
    }

    function testApproveToZeroAddress() public {
        vm.prank(bob);
        vm.expectRevert(); // Should revert when approving zero address
        ourToken.approve(address(0), 100);
    }

    function testTransferZeroAmount() public {
        uint256 bobInitialBalance = ourToken.balanceOf(bob);
        uint256 aliceInitialBalance = ourToken.balanceOf(alice);

        vm.prank(bob);
        ourToken.transfer(alice, 0);

        // Balances should remain unchanged but transfer should succeed
        assertEq(ourToken.balanceOf(bob), bobInitialBalance);
        assertEq(ourToken.balanceOf(alice), aliceInitialBalance);
    }

    function testTransferFromZeroAmount() public {
        uint256 approval = 10 ether;

        vm.prank(bob);
        ourToken.approve(alice, approval);

        uint256 bobInitialBalance = ourToken.balanceOf(bob);
        uint256 aliceInitialBalance = ourToken.balanceOf(alice);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 0);

        // Balances should remain unchanged but transfer should succeed
        assertEq(ourToken.balanceOf(bob), bobInitialBalance);
        assertEq(ourToken.balanceOf(alice), aliceInitialBalance);
        // Allowance should remain unchanged for zero transfers
        assertEq(ourToken.allowance(bob, alice), approval);
    }

    function testTransferToSelf() public {
        uint256 transferAmount = 10 ether;
        uint256 initialBalance = ourToken.balanceOf(bob);

        vm.prank(bob);
        ourToken.transfer(bob, transferAmount);

        // Balance should remain the same when transferring to self
        assertEq(ourToken.balanceOf(bob), initialBalance);
    }

    function testApproveOverride() public {
        // Test that a new approval overrides the previous one
        vm.prank(bob);
        ourToken.approve(alice, 100 ether);
        assertEq(ourToken.allowance(bob, alice), 100 ether);

        vm.prank(bob);
        ourToken.approve(alice, 50 ether);
        assertEq(ourToken.allowance(bob, alice), 50 ether);
    }

    function testMultipleTransfers() public {
        uint256 transferAmount = 10 ether;

        // Transfer from bob to alice
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);

        // Transfer from alice back to bob
        vm.prank(alice);
        ourToken.transfer(bob, transferAmount / 2);

        assertEq(ourToken.balanceOf(alice), transferAmount / 2);
        assertEq(
            ourToken.balanceOf(bob),
            STARTING_BALANCE - transferAmount / 2
        );
    }
}
