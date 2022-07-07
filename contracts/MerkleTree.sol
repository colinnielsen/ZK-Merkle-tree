//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./MerkleProofVerifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256 private constant DEPTH = 3;
    uint256 private constant WIDTH = 8;
    uint256[15] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        for (uint256 i = 0; i < 15; i++)
            hashes[i] = uint256(keccak256(abi.encodePacked(i)));
        root = updateTree();
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        hashes[index] = hashedLeaf;
        index++;
        root = updateTree();
        return root;
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        return verifyProof(a, b, c, input) && input[0] == root;
    }

    /// @notice updates the tree in the `hash` array
    /// @return the roothash
    function updateTree() private returns (uint256) {
        uint256[8][DEPTH + 1] memory rows;

        uint256 treeIndex;

        for (uint256 i = 0; i < DEPTH + 1; i++) {
            uint256 nodes_in_row = 2**(DEPTH - i);
            for (uint256 k = 0; k < nodes_in_row; k++) {
                uint256 leaf = i == 0
                    ? hashes[k]
                    : PoseidonT3.poseidon(
                        [rows[i - 1][k * 2], rows[i - 1][k * 2 + 1]]
                    );

                rows[i][k] = leaf;
                hashes[treeIndex] = leaf;
                treeIndex++;
            }
        }

        return rows[DEPTH][0];
    }
}
