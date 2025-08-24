// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAdminManagement__Base {
    // ------------------------
    // Errors
    // ------------------------
    error AdminManagement__ZeroAddressError();
    error AdminManagement__AlreadyAddedAsAdmin(Admin admin);
    error AdminManagement__AddressIsNotAnAdmin();

    // ------------------------
    // Structs
    // ------------------------
    struct Admin {
        address adminAddress;
        address addedBy;
        uint256 addedAt;
    }

    // ------------------------
    // Events
    // ------------------------
    event AddedNewAdmin(
        string message,
        uint256 timestamp,
        string indexed contractName,
        address indexed addedAdminAddress,
        address indexed addedBy
    );

    event RemovedAdmin(
        string message,
        uint256 timestamp,
        string indexed contractName,
        address indexed removedAdminAddress,
        address indexed removedBy
    );

    // ------------------------
    // Functions
    // ------------------------
    function addAdmin(address _address) external;

    function removeAdmin(address _address) external;

    function getPlatformAdmins() external view returns (Admin[] memory);

    function getAdminAdminRegistrations(
        address _adminAddress
    ) external view returns (Admin[] memory);

    function checkIsAdmin(address _adminAddress) external view returns (bool);

    function getAdminProfile(
        address _adminAddress
    ) external view returns (Admin memory);
}
