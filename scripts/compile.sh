#!/bin/bash

cd circuits

if [ -f ./build/powers_of_tau__10.ptau ]; then
    echo  ""
else
    echo 'Downloading powers_of_tau__10.ptau'
    curl https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau -o powers_of_tau__10.ptau
fi

echo "Compiling circuit.circom..."

# compile circuit

circom MerkleTree.circom --r1cs --wasm --sym -o ./build/

# Start a new zkey and make a contribution

# create a groth16 SNARK setup with Hermez's prebuild powers of tau 2^10th ceremony and export the proof a zkey file
snarkjs g16s build/MerkleTree.r1cs build/powers_of_tau__10.ptau commitment/MerkleTree_0000.zkey
# make a contribution that file and export the result to a __final zkey file
snarkjs zkey contribute commitment/MerkleTree_0000.zkey commitment/MerkleTree__final.zkey --name="colin" -v -e="rando"
# export the verification key to a
snarkjs zkey export verificationkey commitment/MerkleTree__final.zkey commitment/verification_key.json

# generate solidity contract to verify the proof
snarkjs zkey export solidityverifier commitment/MerkleTree__final.zkey ../contracts/MerkleProofVerifier.sol

cd ..