// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVoting {
    // ---------------- Errors ----------------
    error Voting__NotDAOMember();
    error Voting__ZeroAddressError();
    error Voting__InvalidIdError();
    error Voting__EmptyProposalCodeName();
    error Voting__NoExistingVote();
    error Voting__NoMutipleVoting();
    error Voting__CannotDeleteQueuedVote();
    error Voting__InsufficientVotingBalance();
    error Voting__ProposalIsNotActive();

    // ---------------- Enums ----------------
    enum VoteAction { Approve, Reject }

    // ---------------- Structs ----------------
    struct Vote {
        uint256 id;
        uint256 addedAt;           
        uint256 proposalId;        
        address memberAddress;     
        VoteAction action;
    }

    // ---------------- Events ----------------
    event DAOVoteRecorded(
        string message,       
        uint256 voteId,         
        uint256 indexed proposalId,
        address indexed memberAddress, 
        VoteAction action,
        uint256 timestamp
    );

    // ---------------- Functions ----------------
    function castVote(
        uint256 _proposalId,
        VoteAction _action
    ) external;

    function updateVote(
        VoteAction _newAction,
        uint256 _voteId
    ) external;

    function removeVote(
        uint256 _voteId
    ) external;

    function getMemberVoteOnProposal(
        address _memberAddress,
        uint256 _proposalId
    ) external view returns (Vote memory);

    function getMemberVoteHistory(
        address _memberAddress
    ) external view returns (Vote[] memory);

    function getDAOVoteHistory() 
        external 
        view 
        returns (Vote[] memory);

    function getDAOVoteHistoryOnProposal() 
        external 
        view 
        returns (Vote[] memory);

    function getDAOVoteCountsOnProposal(
        uint256 _proposalId
    ) external view returns (uint256 approvals, uint256 rejections);
}
