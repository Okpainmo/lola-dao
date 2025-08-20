// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./auth/AdminAuth.sol";

contract AdminManagement is AdminAuth {
    error AdminManagement__ZeroAddressError();

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

    struct Admin {
        address adminAddress;
        address addedBy;
        uint256 addedAt;
    }

    error AdminManagement__AlreadyAddedAsAdmin(Admin admin);

    error AdminManagement__AddressIsNotAnAdmin();

    Admin[] internal s_platformAdmins;

    mapping(address => Admin[]) internal s_adminAddressToAdditions_admin;

    mapping(address => Admin) internal s_adminAddressToAdminProfile;

    string private constant CURRENT_CONTRACT_NAME = "AdminManagement"; // keep name in one variable to avoid mispelling it at any point

    function _verifyIsAddress(address _address) internal virtual pure {
        if (_address == address(0)) {
            revert AdminManagement__ZeroAddressError();
        }
    }
    
    function addAdmin(address _address) public adminOnly(msg.sender) {
        _verifyIsAddress(_address);

        // s_isAdmin(variable) - from AdminAuth.sol
        if (s_isAdmin[_address]) {
            Admin storage admin = s_adminAddressToAdminProfile[_address];

            revert AdminManagement__AlreadyAddedAsAdmin(admin);
        }

        Admin memory newAdmin = Admin({
            adminAddress: _address,
            addedBy: msg.sender,
            addedAt: block.timestamp
        });

        s_platformAdmins.push(newAdmin);

        Admin[] storage senderAdminAdditions = s_adminAddressToAdditions_admin[msg.sender];
        senderAdminAdditions.push(newAdmin);

        s_adminAddressToAdditions_admin[msg.sender] = senderAdminAdditions;
        s_isAdmin[_address] = true;
        s_adminAddressToAdminProfile[_address] = newAdmin;

        emit AddedNewAdmin("new admin added successfully", block.timestamp, CURRENT_CONTRACT_NAME, _address, msg.sender);
    }

    function removeAdmin(address _address) public adminOnly(msg.sender) {
        _verifyIsAddress(_address);

        // s_isAdmin(variable) - from AdminAuth.sol
        if (!s_isAdmin[_address]) {
            revert AdminManagement__AddressIsNotAnAdmin();
        }

        s_isAdmin[_address] = false;

        // Remove from global admin list
        for (uint256 i = 0; i < s_platformAdmins.length; i++) {
            if (s_platformAdmins[i].adminAddress == _address) {
                s_platformAdmins[i] = s_platformAdmins[s_platformAdmins.length - 1];
                s_platformAdmins.pop();

                break;
            }
        }

        Admin[] storage senderAdminAdditions = s_adminAddressToAdditions_admin[msg.sender];

        // Remove from additions-list of the admin who added this admin
        for (uint256 i = 0; i < senderAdminAdditions.length; i++) {
            if (senderAdminAdditions[i].adminAddress == _address) {
                senderAdminAdditions[i] = senderAdminAdditions[senderAdminAdditions.length - 1];
                senderAdminAdditions.pop();

                break;
            }
        }

        delete s_adminAddressToAdminProfile[_address];

        emit RemovedAdmin("admin removed successfully", block.timestamp, CURRENT_CONTRACT_NAME, _address, msg.sender);
    }

    function getPlatformAdmins() public view returns (Admin[] memory) {
        return s_platformAdmins;
    }

    function getAdminAdminRegistrations(address _adminAddress) public view returns (Admin[] memory) {
        _verifyIsAddress(_adminAddress);

        return s_adminAddressToAdditions_admin[_adminAddress];
    }

    function checkIsAdmin(address _adminAddress) public view returns (bool) {
        _verifyIsAddress(_adminAddress);

        return (s_isAdmin[_adminAddress]);
    }

    function getAdminProfile(address _adminAddress) public view returns (Admin memory) {
        _verifyIsAddress(_adminAddress);

        if (!s_isAdmin[_adminAddress]) {
            revert AdminManagement__AddressIsNotAnAdmin();
        }

        Admin memory admin = s_adminAddressToAdminProfile[_adminAddress];

        return admin;
    }
}
