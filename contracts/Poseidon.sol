//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @dev We only expose an interface here because hardhat will inject the bytecode of the poseidonT3 hash function into our contract at runtime
library PoseidonT3 {
    function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}
