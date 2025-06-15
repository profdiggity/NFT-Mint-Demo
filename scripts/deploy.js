const { ethers } = require("hardhat");

async function main() {
  // Thay đổi URL này thành URL metadata IPFS thật khi bạn đã upload metadata
  const baseTokenURI = "https://ipfs.io/ipfs/<your_metadata_cid>/";
  const MyNFT = await ethers.getContractFactory("MyNFT");
  const myNFT = await MyNFT.deploy(baseTokenURI);
  await myNFT.waitForDeployment();
  const address = await myNFT.getAddress();
  console.log("MyNFT deployed to:", address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
