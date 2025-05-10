// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-contracts-5.1.0/access/AccessControl.sol";
import "@openzeppelin-contracts-5.1.0/security/ReentrancyGuard.sol";
import "@openzeppelin-contracts-5.1.0/token/ERC20/IERC20.sol";

// 1. User Management Contract
contract UserManagement is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum KycStatus {
        PENDING,
        VERIFIED,
        REJECTED
    }
    struct User {
        string firstName;
        string lastName;
        string email;
        string phone;
        string country;
        string state;
        string city;
        string postalCode;
        KycStatus status;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    mapping(address => User) public users;

    function createUser(
        string memory _firstName,
        string memory _lastName,
        string memory _email,
        string memory _phone,
        string memory _country,
        string memory _state,
        string memory _city,
        string memory _postalCode
    ) external {
        require(!users[msg.sender], "User already exists");
        users[msg.sender] = User(
            _firstName,
            _lastName,
            _email,
            _phone,
            _country,
            _state,
            _city,
            _postalCode,
            KycStatus.PENDING
        );
    }

    function updateKYCStatus(KycStatus status) external onlyRole(ADMIN_ROLE) {
        require(users[msg.sender], "User does not exist");
        users[msg.sender].status = status;
    }
}
