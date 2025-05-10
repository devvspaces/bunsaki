// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-contracts-5.1.0/access/AccessControl.sol";
import "src/PropertyListing.sol";
import "src/PropertyNFT.sol";

contract ValidatorManagement is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum KycStatus {
        PENDING,
        VERIFIED,
        REJECTED
    }
    enum ValidatorStatus {
        NOT_APPLIED,
        PENDING,
        APPROVED,
        REJECTED,
        SUSPENDED
    }
    struct Validator {
        string firstName;
        string lastName;
        string email;
        string phone;
        string country;
        string state;
        string city;
        string postalCode;
        KycStatus kycStatus;
        uint256 baseReputationScore;
        uint256 accuracyScore;
        ValidatorStatus status;
        uint256 createdAt;
    }
    mapping(address => Validator) public validators;

    struct VerificationRequest {
        uint256 propertyId;
        address[] verifiers;
        mapping(address => bool) hasVerified;
        uint256 approvalCount;
        uint256 rejectionCount;
        bool isCompleted;
    }

    mapping(uint256 => VerificationRequest) public verificationRequests;
    uint256 private _requestIds;

    PropertyNFT public propertyNFT;
    PropertyListing public propertyListing;

    uint256 public BASE_REPUTATION_SCORE = 500;
    uint256 public ACCURACY_SCORE_WEIGHT = 10;
    uint256 public LONGEVITY_SCORE_WEIGHT = 10;

    constructor(address _propertyNFTAddress, address _propertyListingAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        propertyNFT = PropertyNFT(_propertyNFTAddress);
        propertyListing = PropertyListing(_propertyListingAddress);
    }

    function setPropertyListing(
        address _propertyListingAddress
    ) external onlyRole(ADMIN_ROLE) {
        propertyListing = PropertyListing(_propertyListingAddress);
    }

    function createValidator(
        string memory _firstName,
        string memory _lastName,
        string memory _email,
        string memory _phone,
        string memory _country,
        string memory _state,
        string memory _city,
        string memory _postalCode
    ) external {
        require(!validators[msg.sender], "Validator already exists");
        validators[msg.sender] = Validator(
            _firstName,
            _lastName,
            _email,
            _phone,
            _country,
            _state,
            _city,
            _postalCode,
            KycStatus.PENDING,
            BASE_REPUTATION_SCORE,
            0,
            ValidatorStatus.NOT_APPLIED,
            block.timestamp
        );
    }

    function updateKYCStatus(KycStatus status) external onlyRole(ADMIN_ROLE) {
        users[msg.sender].status = status;
    }

    function applyForValidator() external {
        require(validators[msg.sender].kyStatus == KycStatus.VERIFIED, "KYC not verified");
        validators[msg.sender].status = ValidatorStatus.PENDING;
    }

    function approveValidator(address validator) external onlyRole(ADMIN_ROLE) {
        validators[validator].status = ValidatorStatus.APPROVED;
    }

    function updateValidatorReputation(
        address validator,
        uint256 newScore
    ) external onlyRole(ADMIN_ROLE) {
        validators[validator].baseReputationScore = newScore;
    }

    function requestVerification(uint256 propertyId) external {
        PropertyListing.Property memory property = propertyListing.getProperty(propertyId);
        require(property.owner == msg.sender, "Not the owner");
        _requestIds++;
        VerificationRequest storage newRequest = verificationRequests[
            _requestIds
        ];
        newRequest.tokenId = tokenId;
    }

    function assignVerifiers(
        uint256 requestId,
        address[] memory _verifiers
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VerificationRequest storage request = verificationRequests[requestId];
        request.verifiers = _verifiers;
    }

    function submitVerification(
        uint256 requestId,
        bool isApproved
    ) external onlyRole(VERIFIER_ROLE) {
        VerificationRequest storage request = verificationRequests[requestId];
        require(!request.hasVerified[msg.sender], "Already verified");

        request.hasVerified[msg.sender] = true;
        if (isApproved) {
            request.approvalCount++;
        }

        if (request.approvalCount >= 3) {
            request.isCompleted = true;
            propertyNFT.mintPropertyNFT(
                propertyNFT.ownerOf(request.tokenId),
                ""
            ); // Mint verified NFT
        }
    }
}
