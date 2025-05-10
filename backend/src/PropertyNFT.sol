// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-contracts-5.1.0/token/ERC721/ERC721.sol";
import "@openzeppelin-contracts-5.1.0/access/AccessControl.sol";
import "@openzeppelin-contracts-5.1.0/token/ERC20/IERC20.sol";

contract PropertyNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct Property {
        string metadataURI;
        uint256 timeLock;
    }

    mapping(uint256 => Property) public properties;
    uint256 private _tokenIds;

    constructor() ERC721("PropertyNFT", "PNFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mintPropertyNFT(
        address owner,
        string memory metadataURI
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _safeMint(owner, newTokenId);
        properties[newTokenId] = Property(
            metadataURI,
            block.timestamp + 30 days
        ); // 30-day time lock
        return newTokenId;
    }

    function tokenURI(tokenId) external view returns (string memory) {
        return properties[tokenId].metadataURI;
    }

    function transferProperty(uint256 tokenId, address newOwner) external {
        require(
            block.timestamp >= properties[tokenId].timeLock,
            "Property is time-locked"
        );
        safeTransferFrom(ownerOf(tokenId), newOwner, tokenId);
    }
}
