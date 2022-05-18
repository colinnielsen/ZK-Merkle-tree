# ZK / Solidity Merkle Proof Verifier
> This is a merkle proof verifier that allows a user to prove they know a leaf within a given merkle tree, without revealing the leaf itself.

This system is a very simple version of the code used in mixers like Tornado Cash classic or more generalized applications like Semaphore.

**Remember**: a ZK circuit proves for _honest computation_ of a function output.

Why is this important? Well, it allows you to store public secrets (like a merkle root hash) in public (on a blockchain) that relate to secret inputs (merkle tree leaves). A system like this allows users to submit proofs that they have _honestly computed a public hash output given a secret input_ (a merkle proof) that they know.

```bash
    # do  s e c r e t  things
    # 🕵🏼‍♂️ 🤫 🕵🏼 🤐 🕵🏼‍♀️ #
    yarn test

    # if rebuild is necessary
    yarn build
```