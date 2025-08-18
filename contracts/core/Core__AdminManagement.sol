// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../AdminManagement.sol";

contract Core__AdminManagement is AdminManagement {
    event Logs(string message, uint256 timestamp, string indexed contractName);

    address private i_owner;

    string private constant CONTRACT_NAME = "Core__AdminManagement"; // set in one place to avoid mispelling elsewhere

    function makeMasterAdmin() private {
        // Admin(struct) - from AdminManagement.sol
        Admin memory masterAdmin = Admin({
            adminAddress: msg.sender,
            addedBy: msg.sender,
            addedAt: block.timestamp
        });

        // s_platformAdmins - from AdminManagement.sol
        s_platformAdmins.push(masterAdmin);

        Admin[]
            storage senderAdminAdditions_admin = s_adminAddressToAdditions_admin[
                msg.sender
            ];
        senderAdminAdditions_admin.push(masterAdmin);

        s_adminAddressToAdditions_admin[
            msg.sender
        ] = senderAdminAdditions_admin;
        // s_isAdmin(variable) - from AdminAuth.sol
        s_isAdmin[msg.sender] = true;
        s_adminAddressToAdminProfile[msg.sender] = masterAdmin;

        emit AddedNewAdmin(
            "new admin added successfully",
            block.timestamp,
            CONTRACT_NAME,
            msg.sender,
            msg.sender
        );
    }

    constructor() {
        i_owner = msg.sender;
        s_isAdmin[msg.sender] = true;
        makeMasterAdmin();

        emit Logs(
            "contract deployed successfully with constructor chores completed",
            block.timestamp,
            CONTRACT_NAME
        );
    }

    function getContractName() public pure returns (string memory) {
        return CONTRACT_NAME;
    }

    function getContractOwner() public view returns (address) {
        return i_owner;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}
