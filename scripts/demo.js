// scripts/demo.js
// correlates to contracts/Example.sol please read Example.sol.md for context
const { ethers } = require("hardhat");

async function main() {
  const [deployer, alice, bob, operator] = await ethers.getSigners();

  const Factory = await ethers.getContractFactory("Sample721Token");
  const nft = await Factory.deploy("Sample721", "S721", "https://api.example.com/meta/");

  await nft.waitForDeployment();

  // Owner mints to Alice
  await (await nft.mint(alice.address)).wait();

  // Alice grants full approval to operator
  const nftAsAlice = nft.connect(alice);
  await (await nftAsAlice.setApprovalForAll(operator.address, true)).wait();

  // Operator transfers token 1 from Alice to Bob
  const nftAsOp = nft.connect(operator);
  await (await nftAsOp.transferFrom(alice.address, bob.address, 1)).wait();

  // Owner sets per token URI
  await (await nft.setTokenURI(1, "1.json")).wait();

  console.log("Owner of 1:", await nft.ownerOf(1));
  console.log("tokenURI of 1:", await nft.tokenURI(1));
}

main().catch((e) => { console.error(e); process.exit(1); });
