// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-contracts-5.1.0/access/AccessControl.sol";
import "@openzeppelin-contracts-5.1.0/security/ReentrancyGuard.sol";
import "src/PropertyNFT.sol";
import "src/ValidatorManagement.sol";

contract PropertyListing is ReentrancyGuard, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Property {
        string owner;
        string metadataURI;
    }
    Property[] public properties;

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Listing) public listings;
    uint256 private _listingIds;

    PropertyNFT public propertyNFT;
    ValidatorManagement public validatorManagement;

    constructor(address _propertyNFTAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        propertyNFT = PropertyNFT(_propertyNFTAddress);
    }

    function setValidatorManagement(
        address _validatorManagementAddress
    ) external onlyRole(ADMIN_ROLE) {
        validatorManagement = ValidatorManagement(_validatorManagementAddress);
    }

    function setPropertyNFT(
        address _propertyNFTAddress
    ) external onlyRole(ADMIN_ROLE) {
        propertyNFT = PropertyNFT(_propertyNFTAddress);
    }

    function addProperty(
        string memory owner,
        string memory country,
        string memory state,
        string memory city,
        string memory postalCode,
        string memory streetAddress,
        string memory deedURI,
        string memory surveyURI,
        string memory geoJson
    ) external returns (uint256) {
        properties.push(
            Property(
                owner,
                country,
                state,
                city,
                postalCode,
                streetAddress,
                deedURI,
                surveyURI,
                geoJson
            )
        );
        uint256 newPropertyId = properties.length - 1;
    }

    function getProperty(uint256 propertyId) external view returns (Property memory) {
        return properties[propertyId];
    }

    function createListing(uint256 tokenId, uint256 price) external {
        require(propertyNFT.ownerOf(tokenId) == msg.sender, "Not the owner");
        _listingIds++;
        listings[_listingIds] = Listing(tokenId, msg.sender, price, true);
    }

    function buyProperty(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");

        listing.isActive = false;
        propertyNFT.transferProperty(listing.tokenId, msg.sender);
        payable(listing.seller).transfer(msg.value);
    }
}
