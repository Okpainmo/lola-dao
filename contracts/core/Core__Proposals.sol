// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../ProposalManagement.sol";

contract Core__Proposals is ProposalManagement {
    error ProposalAndVotingCore__ZeroAddressError();

    event Logs(string message, uint256 timestamp, string indexed contractName);


    string private constant CONTRACT_NAME = "Core__Proposals"; // set in one place to avoid mispelling elsewhere

    constructor(address _adminManagementCoreContractAddress) {
        if(_adminManagementCoreContractAddress == address(0)) {
            revert ProposalAndVotingCore__ZeroAddressError();
        }

        // i_owner(variable) - from ProposalManagement.sol -> OnlyOwnerAuth.sol
        i_owner = msg.sender;
        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
        // s_lolaUSDCoreContractAddress = _lolaUSDCoreContractAddress; // needed for checking users' balance to ensure requirements are met for voting, and likely more

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

    function updateAdminManagementCoreContractAddress(address _newAddress) public {
         if(_newAddress == address(0)) {
            revert ProposalAndVotingCore__ZeroAddressError();
        }

        s_adminManagementCoreContractAddress = _newAddress;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}