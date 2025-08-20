// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../ProposalManagement.sol";

contract Core__Proposals is ProposalManagement {
    error ProposalCore__ZeroAddressError();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    function _verifyIsAddress(address _address) internal override pure {
        if (_address == address(0)) {
            revert ProposalCore__ZeroAddressError();
        }
    }

    string private constant CONTRACT_NAME = "Core__Proposals"; // set in one place to avoid mispelling elsewhere

    constructor(
        address _adminManagementCoreContractAddress 
        // address _votingCoreContractAddress, 
        // address _membershipCoreContractAddress
    ) {
        _verifyIsAddress(_adminManagementCoreContractAddress);
        // _verifyIsAddress(_votingCoreContractAddress);
        // _verifyIsAddress(_membershipCoreContractAddress);

        // i_owner(variable) - from ProposalManagement.sol -> OnlyOwnerAuth.sol
        i_owner = msg.sender;
        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
        // s_votingCoreContractAddress = _votingCoreContractAddress;
        // s_membershipCoreContractAddress = _membershipCoreContractAddress;

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
        _verifyIsAddress(_newAddress);

        s_adminManagementCoreContractAddress = _newAddress;
    }

    function updateVotingCoreContractAddress(address _newAddress) public {
        _verifyIsAddress(_newAddress);

        s_votingCoreContractAddress = _newAddress;
    }

    function updateMembershipCoreContractAddress(address _newAddress) public {
        _verifyIsAddress(_newAddress);

        s_membershipCoreContractAddress = _newAddress;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}