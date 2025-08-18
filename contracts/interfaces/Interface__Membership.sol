// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IMembership
/// @notice Interface for the Membership contract

interface IMembership {
    // ------------------------
    // Errors
    // ------------------------
    error Membership__ZeroAddressError();
    error Membership__NotDAOMember();
    error Membership__InsufficientVotingBalance();
    error Membership__AdminAndProposalAuthorOnly();

    // ------------------------
    // Structs
    // ------------------------
    struct DAOMember {
        address memberAddress;
        uint256 addedAt;
    }

    // ------------------------
    // Events
    // ------------------------
    event DAOMembersManagement(
        string message,
        address memberAddress,
        uint256 addedAt
    );

    // ------------------------
    // Functions
    // ------------------------
    function addDAOMember(address _memberAddress) external;
    function removeDAOMember(address _memberAddress) external;
    function updateDAOMemberProfile(address _memberAddress, address _newAddress) external;
    function checkIsDAOMember(address _memberAddress) external view returns (bool);
    function getDAOMemberProfile(address _memberAddress) external view returns (DAOMember memory);
    function getDAOMembers() external view returns (DAOMember[] memory);
}