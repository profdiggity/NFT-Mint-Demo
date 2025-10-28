# NFT Minting (ERC-721)

A simple ERC-721 NFT minting demo using Hardhat, Solidity, Ethers.js, and a basic HTML/JS web interface. Deploy and test NFT minting locally with MetaMask and a local blockchain. Great for learning and experimenting with NFT smart contracts and dApp integration.

## 1. Install & Start Local Blockchain

```bash
npm install
npx hardhat compile
npx hardhat node
```

## 2. Deploy the Smart Contract to Localhost
Open a new terminal:
```bash
npx hardhat run scripts/deploy.js --network localhost
```
Copy the contract address printed in the terminal (e.g., `0x...`).

## 3. Import Owner Account into MetaMask
- When running `npx hardhat node`, the terminal will show a list of accounts and private keys.
- Copy the private key of the first account and import it into MetaMask.
- Switch MetaMask to the “Localhost 8545” network.

## 4. Edit `index.html`
- Replace the `CONTRACT_ADDRESS` variable with your deployed contract address.

## 5. Run a Local Web Server and Open the Demo
```bash
npx serve .
```
- Visit `http://localhost:3000/index.html` (or the corresponding port).
- Connect MetaMask, mint, and view your NFT.

## 6. Notes
- **Never** push your `.env` file or private keys to GitHub.
- Contract address and owner wallet address must be different.
- Only the owner (deployer account) can mint NFT (unless you modify the smart contract).

## 7. References
- [Hardhat Documentation](https://hardhat.org/getting-started/)
- [MetaMask Documentation](https://metamask.io/)
- [Ethers.js Documentation](https://docs.ethers.org/)


## Additional Examples
- Refer to `contracts/Example.sol` for a simple ERC-721 contract.
- This simple contract correlates with the `scripts/demo.js` Hardhat script.
- If you are teaching these examples, refer to `contracts/Example.sol.md`


<!-- Author
Hi, I'm the creator and maintainer of this project. I'm passionate about software development and always eager to improve. If you find this project helpful, please consider giving it a star ⭐ – your support means a lot!

If you encounter any bugs or issues, feel free to report them via email. I appreciate your feedback! -->

📧 **Email:** naruto3285@gmail.com
