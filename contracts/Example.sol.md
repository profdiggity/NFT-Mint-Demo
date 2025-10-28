# Explanation of Example.sol ERC-721 smart contract

## What is Solidity?

Solidity is a contract oriented programming language used to write smart contracts that run on Ethereum and other EVM compatible blockchains. Files use the .sol extension and are compiled to EVM bytecode along with an ABI so apps can interact with the contract.

* Syntax feels similar to JavaScript and C++
* Statically typed with features like structs, enums, modifiers, events, libraries, and inheritance
* Common tooling includes Remix in the browser, plus local frameworks such as Hardhat and Foundry
* Security is critical because code is immutable after deployment unless you design an upgrade pattern
* 
Here is a tiny example: 

```solidity
pragma solidity ^0.8.20;

contract SimpleStore {
    uint256 private value;

    function set(uint256 newValue) public {
        value = newValue;
    }

    function get() public view returns (uint256) {
        return value;
    }
}
```

## Developing with Ethereum: Caveats

* Use recent compiler versions with a fixed pragma to avoid unexpected behavior
* Watch for risks such as reentrancy and integer overflows which are mostly prevented in modern compilers but still require careful design
* Prefer well reviewed libraries like OpenZeppelin for common patterns such as ERC token standards and access control

## What is an NFT smart contract?

* ERC721 is the standard for non-fungible tokens (NFTs) where every tokenId is unique
* The contract keeps track of who owns each token, how many each address holds, and who is allowed to move a given token

## Mint and burn

* Mint creates a brand new token and assigns it to someone
  In this contract there are two paths

  1. `mint(to)` is restricted to the contract owner through OpenZeppelin `Ownable`
  2. `safeMint(to)` is public in this code, so anyone can mint to any address
* Burn destroys a token by sending it to the zero address through internal logic, and it requires that the caller is the owner or has approval

## Approvals

* `approve(to, tokenId)` lets one address move one specific token a single time until cleared
* `setApprovalForAll(operator, approved)` gives an operator blanket permission to move all of your tokens until you revoke it
* `getApproved` and `isApprovedForAll` are the read functions that report those permissions

## Transfers

* `transferFrom(from, to, tokenId)` moves a token if the caller is the owner, the per-token approved address, or an approved operator
* `safeTransferFrom` adds a safety check when the recipient is a smart contract
  It calls `onERC721Received` on the recipient to confirm it knows how to accept NFTs
  If the recipient contract does not implement that interface, the transfer reverts, which prevents tokens from being trapped

## Why the “Ownable” part matters

* `Ownable` gives the contract a single admin address with special powers
  In this file the owner can mint through `mint`, and manage metadata through `setBaseURI` and `setTokenURI`
* Ownership is set to the deployer in the constructor and can be transferred later if needed

## About the Internals

* `_update` is the core engine used by mint, transfer, and burn
  It verifies authorization when asked, adjusts balances, clears stale approvals, writes the new owner, and emits the `Transfer` event
* Custom errors like `ERC721NonexistentToken` and `ERC721InvalidReceiver` make failures explicit and cheaper than string messages
* Metadata comes from a base URI plus an optional per-token override, or falls back to base plus the numeric id

## Practical Takeaways

* Use `safeTransferFrom` whenever the recipient might be a contract
* Decide whether you really want `safeMint` to be public in production
  If not, add `onlyOwner` to it so minting is controlled
* Clearing approvals on every transfer avoids approval-race issues and is already handled here
