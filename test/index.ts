//@ts-ignore
import { poseidonContract } from "circomlibjs";
import { expect } from "chai";
import { ethers } from "hardhat";
//@ts-ignore
import { groth16 } from "snarkjs";
import { Contract } from "ethers";

function unstringifyBigInts(o: any): any {
  if (typeof o == "string" && /^[0-9]+$/.test(o)) {
    return BigInt(o);
  } else if (typeof o == "string" && /^0x[0-9a-fA-F]+$/.test(o)) {
    return BigInt(o);
  } else if (Array.isArray(o)) {
    return o.map(unstringifyBigInts);
  } else if (typeof o == "object") {
    if (o === null) return null;
    const res: Record<string, BigInt> = {};
    const keys = Object.keys(o);
    keys.forEach((k) => {
      res[k] = unstringifyBigInts(o[k]);
    });
    return res;
  } else {
    return o;
  }
}

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

    const Input = {
      leaf: "1",
      path_elements: ["2", node9, node13],
      path_index: ["0", "0", "0"],
    };
    const { proof, publicSignals } = await groth16.fullProve(
      Input,
      "circuits/build/MerkleTree_js/MerkleTree.wasm",
      "circuits/commitment/MerkleTree__final.zkey"
    );

    const editedPublicSignals = unstringifyBigInts(publicSignals);
    const editedProof = unstringifyBigInts(proof);
    const calldata = await groth16.exportSolidityCallData(
      editedProof,
      editedPublicSignals
    );

    const argv = calldata
      .replace(/["[\]\s]/g, "")
      .split(",")
      .map((x: string) => BigInt(x).toString());
    const a = [argv[0], argv[1]];
    const b = [
      [argv[2], argv[3]],
      [argv[4], argv[5]],
    ];
    const c = [argv[6], argv[7]];
    const input = argv.slice(8);

    expect(await merkleTree.verify(a, b, c, input)).to.be.true;
  });
});
