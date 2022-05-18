pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/Switcher.circom";

/** 
*   @notice a helper template to build one level of the merkle tree
*   @param width_in: the width of the current row
*   @input in: an array[width_in] bits
*   @output out: an array[width_in / 2] bits 
*/
template BuildRow(width_in) {
    signal input in[width_in];

    var width_out = width_in / 2;
    signal output out[width_out];

    component hash_fns[width_out];

    for(var i = 0; i < width_out; i++) {
        hash_fns[i] = Poseidon(2);
        hash_fns[i].inputs[0] <== in[i * 2];
        hash_fns[i].inputs[1] <== in[i * 2+ 1];

        out[i] <== hash_fns[i].out;
    }
}

/** 
*   @notice returns the merkle root given an array of leaves
*   @param depth: the depth of / total levels of the merkle tree
*   @input leaves: an array[2**depth] of leaves in the tree
*   @output root: the merkle root computed from the leaves
*/
template GetRoot(depth) {
    signal input leaves[2**depth];

    signal output root;

    component rows[depth];
    component t[2**depth];

    for(var i = 0; i < depth; i++) {
        var nodes_in_row = 2 ** (depth - i);
        rows[i] = BuildRow(nodes_in_row);
        for(var k = 0; k < nodes_in_row; k++) {
            rows[i].in[k] <== i == 0 ? leaves[k] : rows[i - 1].out[k];
        }
    }
    root <== rows[depth - 1].out[0];
}

/** 
*   @notice returns the merkle root given a merkle proof
*   @param leaf: the leaf we are proving exisits in a merkle tree given a certain hash
*   @input path_elements: an array[depth] incrementing bottom up from the first neighboring leaf to the last node before the root. 0 indicates the current path_element is on the left, 1 for the right
*   @output root: the merkle root computed from the leaves
*/
template MerkleTreeInclusionProof(depth) {
    signal input leaf;
    signal input path_elements[depth];
    signal input path_index[depth]; // proof index are 0's and 1's indicating whether the current element is on the left or right

    signal output root; // note that this is an OUTPUT signal

    // n array of path_element switching computations - this is because you can't use if-else branches to assign signal inputs in circom
    component switchers[depth];
    // n array of poseidon hash functions
    component hashers[depth];

    for (var i = 0; i < depth; i++) {
        // instantiate a switcher that will swap the values of L and R depending on input
        switchers[i] = Switcher();
        // set the switchers selector - what decides output position - to the path_index, remember it will be 0 or 1
        switchers[i].sel <== path_index[i];
        // instantiate the poseidon hash circuit
        hashers[i] = Poseidon(2);

        // set input 1 to either the leaf (the first hash) or the previous iteration's hash
        switchers[i].L <== i == 0 ? leaf : hashers[i - 1].out;
        // set input 2 to the proof element
        switchers[i].R <== path_elements[i];

        // based on the path_index - which tells us the input and outputs - set the R and L values on the poseidon hash input
        hashers[i].inputs[0] <== switchers[i].outL;
        hashers[i].inputs[1] <== switchers[i].outR;
    }

    // after all iterations, the computed root will be the last poseidon hash output
    root <== hashers[depth - 1].out;
}

component main = MerkleTreeInclusionProof(3);
