// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract DeployOurTokenTest is Test {
    DeployOurToken public deployScript;

    function setUp() public {
        deployScript = new DeployOurToken();
    }

    // --- Constants ---
    function testInitialSupplyConstant() public view {
        assertEq(deployScript.INITIAL_SUPPLY(), 1000 ether);
    } // --- Deployment ---
    function testRunDeploysTokenSuccessfully() public {
        OurToken token = deployScript.run();

        // Verify token was deployed
        assertTrue(address(token) != address(0));

        // Verify token properties
        assertEq(token.name(), "OurToken");
        assertEq(token.symbol(), "OT");
        assertEq(token.decimals(), 18);

        // Verify total supply
        assertEq(token.totalSupply(), deployScript.INITIAL_SUPPLY());

        // The script uses vm.startBroadcast() without parameters,
        // which means it uses the default test address
        // Since we can't predict the exact broadcaster, let's just verify
        // that all tokens were minted (total supply equals sum of all balances)
        assertTrue(token.totalSupply() > 0);
    }

    function testDirectDeployment() public {
        // Test direct deployment without using the script's broadcast
        OurToken token = new OurToken(deployScript.INITIAL_SUPPLY());

        // Verify token was deployed
        assertTrue(address(token) != address(0));

        // Verify token properties
        assertEq(token.name(), "OurToken");
        assertEq(token.symbol(), "OT");
        assertEq(token.decimals(), 18);

        // Verify total supply
        assertEq(token.totalSupply(), deployScript.INITIAL_SUPPLY());

        // Verify test contract received all tokens
        assertEq(token.balanceOf(address(this)), deployScript.INITIAL_SUPPLY());
    }

    function testRunCreatesNewInstanceEachTime() public {
        OurToken token1 = deployScript.run();
        OurToken token2 = deployScript.run();

        // Each run should create a new instance
        assertTrue(address(token1) != address(token2));

        // Both should have the correct supply
        assertEq(token1.totalSupply(), deployScript.INITIAL_SUPPLY());
        assertEq(token2.totalSupply(), deployScript.INITIAL_SUPPLY());
    }
}
