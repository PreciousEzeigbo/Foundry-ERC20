// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ManualToken {
    mapping(address => uint256) private s_balances;

    function name() public view returns (string memory) {
        return "Manual Token";
    }

    function totalSupply() public view returns (uint256) {
        return 100 ether;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return s_balances[account];
    }

    function transfer(address to, uint256 _amount) public {
        require(s_balances[msg.sender] >= _amount, "Insufficient balance");
        uint256 previousBalances = s_balances[msg.sender] + s_balances[to];
        s_balances[msg.sender] -= _amount;
        s_balances[to] += _amount;
        require(
            s_balances[msg.sender] + s_balances[to] == previousBalances,
            "Invariant violation"
        );
    }
}
