/ SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin-contracts/access/Ownable.sol"; // Module for ownership control (e.g., onlyOwner)
import "@openzeppelin-contracts/token/ERC721/utils/ERC721Utils.sol"; // Utility for verifying ERC721 receiver on safeTransferFrom
import "@openzeppelin-contracts/utils/Strings.sol"; // String utility for converting uint256 to string

/**
 * @title Sample721Token
 * @dev A custom ERC721 contract implementing minimal functionalities
 *      - mint and burn can only be performed by the owner
 *      - implements basic approve, transferFrom, safeTransferFrom
 *      - Uses OpenZeppelin's Ownable to grant ownership privileges to the deployer
 */
contract Sample721Token is Ownable {
    using Strings for uint256;

    // ----------------------
    // ░░░ Error Definitions ░░░
    // ----------------------

    error ERC721InvalidOwner(address owner); // Invalid owner address
    error ERC721NonexistentToken(uint256 tokenId); // Nonexistent token
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner); // Not the owner
    error ERC721InvalidSender(address sender); // Invalid sender
    error ERC721InvalidReceiver(address receiver); // Invalid receiver
    error ERC721TokenAlreadyMinted(uint256 tokenId); // Token already minted
    error ERC721NotAuthorized(address operator, uint256 tokenId); // Unauthorized
    error ERC721InsufficientApproval(address operator, uint256 tokenId); // Insufficient approval
    error ERC721InvalidApprover(address approver); // Invalid approver
    error ERC721InvalidOperator(address operator); // Invalid operator

    // ----------------------
    // ░░░ Event Definitions ░░░
    // ----------------------

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // Transfer event
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // Approval event
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // Approval for all event
    event MetadataUpdate(uint256 _tokenId); // Metadata update notification
    event BaseURIChanged(string newBaseURI); // Base URI change notification
    event TokenMinted(address indexed to, uint256 indexed tokenId); // Token mint event

    // ----------------------
    // ░░░ State Variables ░░░
    // ----------------------

    string public name; // NFT name
    string public symbol; // NFT symbol
    string private _baseURI; // Base metadata URI
    mapping(uint256 tokenId => string) private _tokenURIs; // Individual token URIs

    uint256 private _nextTokenId; // Next token ID to mint

    mapping(uint256 => address) private _owners; // Token ownership mapping
    mapping(address => uint256) private _balances; // Token balance per address
    mapping(uint256 => address) private _tokenApprovals; // Token-level approval mapping
    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals; // Operator approvals

    // ----------------------
    // ░░░ Constructor ░░░
    // ----------------------

    /**
     * @param name_   NFT collection name
     * @param symbol_ NFT collection symbol
     * @param baseURI Base metadata URI
     */
    constructor(string memory name_, string memory symbol_, string memory baseURI) Ownable(msg.sender) {
        name = name_;
        symbol = symbol_;
        _baseURI = baseURI;
    }


    // ----------------------
    // ░░░ ERC721 Standard Functions ░░░
    // ----------------------

    /// @notice Returns the number of tokens owned by a given address
    /// @param owner The address of the token owner
    /// @return The number of tokens owned
    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

    /// @notice Returns the address of the owner of a specific token
    /// @param tokenId The ID of the token to query
    /// @return The address of the owner
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _requireOwned(tokenId);
    }

    /// @notice Grants approval to a specific address for a specific token
    /// @param to The address to be approved
    /// @param tokenId The ID of the token to approve
    function approve(address to, uint256 tokenId) external {
        _approve(to, tokenId, msg.sender, true);
    }

    /// @dev Internal function to handle approval logic
    /// @param to The address to be approved
    /// @param tokenId The token ID to approve
    /// @param auth The caller (for permission check)
    /// @param emitEvent Whether to emit the Approval event
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal {
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);
            // Reject if the caller is not authorized to approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    /// @notice Returns the approved address for a specific token
    /// @param tokenId The token ID to query
    /// @return The approved address
    function getApproved(uint256 tokenId) external view returns (address) {
        if (_owners[tokenId] == address(0)) revert ERC721NonexistentToken(tokenId);
        return _tokenApprovals[tokenId];
    }

    /// @notice Sets or unsets operator approval for all of the caller's tokens
    /// @param operator The address to be approved as operator
    /// @param approved Whether the approval is granted (true) or revoked (false)
    function setApprovalForAll(address operator, bool approved) external {
        address owner = msg.sender;
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /// @notice Checks if an operator is approved to manage all tokens of a specific owner
    /// @param owner The address of the token owner
    /// @param operator The address to check for operator approval
    /// @return Whether the operator is approved
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Transfers a token to another address if the caller is authorized
    /// @param from The current owner's address
    /// @param to The recipient's address
    /// @param tokenId The token ID to transfer
    function transferFrom(address from, address to, uint256 tokenId) public {
        if (to == address(0)) revert ERC721InvalidReceiver(address(0));

        // Check authorization and perform state update
        address previousOwner = _update(to, tokenId, msg.sender);
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /// @notice Safe transfer: includes ERC721 receiver interface check if recipient is a contract
    /// @param from The current owner's address
    /// @param to The recipient's address
    /// @param tokenId The token ID to transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Safe transfer with additional data: includes ERC721 receiver interface check if recipient is a contract
    /// @param from The current owner's address
    /// @param to The recipient's address
    /// @param tokenId The token ID to transfer
    /// @param data Additional data to include with the transfer
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        ERC721Utils.checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }

    /// @notice Returns whether the contract supports a given interface ID (ERC165)
    /// @param interfaceId The interface identifier
    /// @return Whether the interface is supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f;   // ERC721Metadata
    }

    /// @notice Returns the metadata URI of a specific token
    /// @param tokenId The ID of the token
    /// @return The metadata URI of the token
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI;

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return bytes(base).length > 0 ? string.concat(base, tokenId.toString()) : "";
    }

    /// @notice Sets the metadata URI for a specific token
    /// @param tokenId The ID of the token
    /// @param _tokenURI The metadata URI string
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }

    /// @notice Sets the base URI for all token metadata
    /// @param baseURI The base URI string
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI = baseURI;
        emit BaseURIChanged(baseURI);
    }


    // ----------------------
    // ░░░ Owner-Only Functions (Mint/Burn) ░░░
    // ----------------------

    /// @notice Minting function that can only be called by the contract owner. Mints a token and emits an event.
    /// @param to The address that will receive the token
    function mint(address to) external onlyOwner {
        uint256 tokenId = ++_nextTokenId;
        _mint(to, tokenId);
        emit TokenMinted(to, tokenId);
    }

    /// @notice Publicly callable safe minting function. Verifies receiver if it's a contract.
    /// @param to The address that will receive the token
    function safeMint(address to) external {
        uint256 tokenId = ++_nextTokenId;
        _safeMint(to, tokenId, "");
    }

    /// @dev Internally called safe minting function. Verifies that receiver implements the ERC721 receiver interface if it's a contract.
    /// @param to The address that will receive the token
    /// @param tokenId The token ID to mint
    /// @param data Additional data (usually an empty value)
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal {
        _mint(to, tokenId);
        ERC721Utils.checkOnERC721Received(_msgSender(), address(0), to, tokenId, data);
    }

    /// @notice Burns the token if the caller is authorized
    /// @dev Uses _update to set ownership to address(0), effectively burning it. Emits a Transfer event.
    /// @param tokenId The ID of the token to burn
    function burn(uint256 tokenId) external {
        // _update handles authorization, ownership validation, state update, and event emission
        address previousOwner = _update(address(0), tokenId, _msgSender());

        // Revert if the token doesn't exist
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    // ----------------------
    // ░░░ Internal Transfer Logic ░░░
    // ----------------------

    /// @dev Mints a new token. Reverts if the token already exists.
    /// @param to The address that will receive the token
    /// @param tokenId The token ID to mint
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }

        // Call _update to assign the token to 'to'
        address previousOwner = _update(to, tokenId, address(0));

        // Revert if the token already exists
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /// @dev Transfers an existing token to another address. Requires that 'from' is the actual owner.
    /// @param from The current owner of the token
    /// @param to The recipient address
    /// @param tokenId The token ID to transfer
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }

        // Perform transfer without checking auth (used for internal calls)
        address previousOwner = _update(to, tokenId, address(0));

        // Revert if token doesn't exist
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }

        // Revert if 'from' is not the actual owner
        else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /// @dev Performs a safe transfer without any additional data
    /// @param from The current owner of the token
    /// @param to The recipient address
    /// @param tokenId The token ID to transfer
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /// @dev Performs a safe transfer and checks if the recipient is a contract that implements the ERC721 receiver interface
    /// @param from The current owner of the token
    /// @param to The recipient address
    /// @param tokenId The token ID to transfer
    /// @param data Additional data
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
    }


    /// @dev Updates the ownership information of a token and emits a Transfer event
    /// @param to The new owner of the token
    /// @param tokenId The ID of the token to update
    /// @param auth The caller's address used for authorization checks (skip check if 0)
    /// @return from The previous owner's address
    function _update(address to, uint256 tokenId, address auth) internal returns (address) {
        address from = _owners[tokenId];

        // If auth is provided, perform authorization check
        if (auth != address(0)) {
            if (!_isAuthorized(from, auth, tokenId)) {
                if (from == address(0)) {
                    revert ERC721NonexistentToken(tokenId);
                } else {
                    revert ERC721InsufficientApproval(auth, tokenId);
                }
            }
        }

        // If there was a previous owner, decrease balance and remove approval
        if (from != address(0)) {
            _approve(address(0), tokenId, address(0), false);
            unchecked {
                _balances[from] -= 1;
            }
        }

        // If there is a new owner, increase balance
        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        // Update ownership
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
        return from;
    }

    /// @dev Checks whether the caller is an authorized operator for the given token
    /// @param owner The current owner of the token
    /// @param spender The address attempting to act on the token
    /// @param tokenId The token ID in question
    /// @return true if authorized, false otherwise
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _tokenApprovals[tokenId] == spender);
    }

    /// @dev Ensures the token exists and returns its owner address
    /// @param tokenId The token ID to check
    /// @return owner The address of the token owner
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

}
