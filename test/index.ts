import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
const { poseidonContract } = require("circomlibjs");
const { groth16 } = require("snarkjs");

describe("MerkleTree", function () {
  let merkleTree: Contract;

  beforeEach(async function () {
    const PoseidonT3 = await ethers.getContractFactory(
      poseidonContract.generateABI(2),
      poseidonContract.createCode(2)
    );
    const poseidonT3 = await PoseidonT3.deploy();
    await poseidonT3.deployed();

    const MerkleTree = await ethers.getContractFactory("MerkleTree", {
      libraries: {
        PoseidonT3: poseidonT3.address,
      },
    });
    merkleTree = await MerkleTree.deploy();
    await merkleTree.deployed();
  });

  it("Insert two new leaves and verify the first leaf in an inclusion proof", async function () {
    await merkleTree.insertLeaf(1);
    await merkleTree.insertLeaf(2);

    const node9 = (await merkleTree.hashes(9)).toString();
    const node13 = (await merkleTree.hashes(13)).toString();

    const inputSignals = {
      leaf: "1",
      path_elements: ["2", node9, node13],
      path_index: ["0", "0", "0"],
    };

    const { proof, publicSignals } = await groth16.fullProve(
      inputSignals,
      "circuits/build/MerkleTree_js/MerkleTree.wasm",
      "circuits/commitment/MerkleTree__final.zkey"
    );

    const [a, b, c] = Object.values(proof)
      .filter((x): x is string[] => Array.isArray(x))
      .map((tuple) => tuple.slice(0, -1))
      .map(([a, b]) =>
        Array.isArray(a) && Array.isArray(b)
          ? [a.reverse(), b.reverse()]
          : [a, b]
      );

    expect(await merkleTree.verify(a, b, c, publicSignals)).to.be.true;
  });
});
