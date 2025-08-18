// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "./ProposalManagement.sol";
import "./auth/MembershipAuth.sol";
import "./auth/OnlyOwnerAuth.sol";
import "./interfaces/Interface__LolaUSD.sol";
import "./interfaces/Interface__ProposalManagement.sol";
import "./interfaces/Interface__Membership.sol";

contract Voting is MembershipAuth, OnlyOwnerAuth {
    error Voting__NotDAOMember();
    error Voting__ZeroAddressError();
    // error Voting__InvalidMemberId();
    error Voting__InvalidIdError();
    error Voting__EmptyProposalCodeName();
    error Voting__NoExistingVote();
    error Voting__NoMutipleVoting();
    error Voting__CannotDeleteQueuedVote();
    error Voting__InsufficientVotingBalance();
    error Voting__ProposalIsNotActive();

    enum VoteAction { Approve, Reject }

    /* NB: only the proposal id(which cannot changed or be updated) should be added(linked) to a vote. This will 
    prevent the need to handle the gas-intensive process of having to update all platform votes(in case of 
    a proposal update) - to reflect the update on the(their) parent proposal */

    struct Vote {
        uint256 id;
        uint256 addedAt;           
        uint256 proposalId;
        // string proposalCodeName;   
        address memberAddress;           
        VoteAction action;
    }

    event DAOVoteRecorded(
        string message,       
        uint256 voteId,         
        uint256 indexed proposalId,
        // bytes32 indexed proposalCodeHash, 
        address indexed memberAddress, 
        VoteAction action,
        uint256 timestamp
    );

    uint256 internal s_minimumVotingBalanceRequirement = 10 * 10 ** 18; // 10 USDL

    mapping(address => Vote[]) public memberAddressToMemberVoteHistory;    
    mapping(address => mapping(uint256 => Vote)) public memberAddressToProposalIdToVote;
    mapping(uint256 => Vote[]) public proposalIdToProposalVoteHistory;
    mapping(uint256 => Vote) public voteIdToVote;

    address internal s_lolaUSDCoreContractAddress;
    address internal s_proposalManagementContractAddress;
    address internal s_membershipContractAddress;

    ILolaUSD internal lolaUSDContract = ILolaUSD(s_lolaUSDCoreContractAddress);
    IProposalManagement internal proposalManagementContract = IProposalManagement(s_proposalManagementContractAddress);
    IMembership internal membershipContract = IMembership(s_membershipContractAddress);

    Vote[] private s_allVotes;

    function _checkIds(uint256 _proposalId) internal pure {
        if (_proposalId == 0) revert Voting__InvalidIdError();
    }

    function _checkProposalCodeName(string memory _proposalCodeName) internal pure {
        if (bytes(_proposalCodeName).length == 0) revert Voting__EmptyProposalCodeName();
    }

    function castVote(
        uint256 _proposalId,
        // string calldata _proposalCodeName,
        VoteAction _action

    // onlyDAOMember(modifier) - from => ProposalManagement.sol -> MembershipAuth.sol
    ) external onlyDAOMember(msg.sender) {
        _checkIds(_proposalId);
        // _checkProposalCodeName(_proposalCodeName);

        if(lolaUSDContract.balanceOf(msg.sender) < s_minimumVotingBalanceRequirement) {
            revert Voting__InsufficientVotingBalance();
        }

        IProposalManagement.Proposal memory proposal =  proposalManagementContract.getProposalById(_proposalId);

        // todos:
        // check if voting time has elapsed and voting is also already completed - throw error
        // permit voting if time has elapsed and voting is yet to be completed
        if(proposal.proposalStatus == IProposalManagement.ProposalStatus.Created) {
            revert Voting__ProposalIsNotActive();
        }

        // prevent duplicate voting
        Vote[] memory proposalVotes = proposalIdToProposalVoteHistory[_proposalId];

        for(uint256 i=0; i < proposalVotes.length; i++) {
            if(proposalVotes[i].memberAddress == msg.sender) {
                revert Voting__NoMutipleVoting();
            } 
        } 

        uint256 voteId = s_allVotes.length > 0 ? s_allVotes[s_allVotes.length - 1].id + 1 : 1;
        uint256 nowTs = block.timestamp;

        Vote memory newVote = Vote({
            id: voteId,
            addedAt: block.timestamp,
            proposalId: _proposalId,
            // proposalCodeName: _proposalCodeName,
            memberAddress: msg.sender,
            action: _action
        });

        memberAddressToMemberVoteHistory[msg.sender].push(newVote);
        proposalIdToProposalVoteHistory[_proposalId].push(newVote);
        memberAddressToProposalIdToVote[msg.sender][_proposalId] = newVote;
        voteIdToVote[voteId] = newVote; 
        s_allVotes.push(newVote);

        emit DAOVoteRecorded(
            "vote casted successfully",
            voteId,
            _proposalId,
            // keccak256(bytes(_proposalCodeName)),
            msg.sender,
            _action,
            nowTs
        );

        // todo: update voting status to successful or failed - use the automated function inside proposal mangement
    }

    function updateVote(
        VoteAction _newAction,
        uint256 _voteId
                
    // onlyDAOMember(modifier) - MembershipAuth.sol
    // onlyOwner(modifier) - OnlyOwnerAuth.sol
    ) external onlyDAOMember(msg.sender) onlyOwner(msg.sender) {
        _checkIds(_voteId);
        Vote memory existingVote = voteIdToVote[_voteId];

        if (existingVote.id != _voteId) {
            revert Voting__NoExistingVote();
        }

        uint256 nowTs = block.timestamp;

        Vote memory updatedVote = Vote({
            id: existingVote.id,
            addedAt: existingVote.addedAt,
            proposalId: existingVote.proposalId,
            // proposalCodeName: existingVote.proposalCodeName,
            memberAddress: existingVote.memberAddress,
            action: _newAction
        });

        voteIdToVote[_voteId] = updatedVote;

        // update the all votes array
        for (uint256 i = 0; i < s_allVotes.length; i++) {
            if (existingVote.id == _voteId) {
                s_allVotes[i] = updatedVote;

                break;
            }
        }

        Vote[] memory memberVotes = memberAddressToMemberVoteHistory[msg.sender]; 

        // also update the member votes array
        for (uint256 i = 0; i < memberVotes.length; i++) {
            if (memberVotes[i].id == _voteId) {
                memberVotes[i] = updatedVote;

                break;
            }
        }

        Vote[] memory proposalVoteHistory = proposalIdToProposalVoteHistory[existingVote.proposalId]; 

        // also update the proposal votes history array
        for (uint256 i = 0; i < proposalVoteHistory.length; i++) {
            if (proposalVoteHistory[i].id == _voteId) {
                proposalVoteHistory[i] = updatedVote;

                break;
            }
        }

        emit DAOVoteRecorded(
            "vote updated successfully",
            existingVote.id,
            existingVote.proposalId,
            // keccak256(bytes(existingVote.proposalCodeName)),
            msg.sender,
            _newAction,
            nowTs
        );
    }

    function removeVote(
        uint256 _voteId
                
    // onlyDAOMember(modifier) - MembershipAuth.sol
    // onlyOwner(modifier) - OnlyOwnerAuth.sol
    ) external onlyDAOMember(msg.sender) onlyOwner(msg.sender) {
        Vote memory existingVote = voteIdToVote[_voteId];

        if (existingVote.id != _voteId) {
            revert Voting__NoExistingVote();
        }

        IProposalManagement.Proposal memory proposalToUpdate =  proposalManagementContract.getProposalById(existingVote.proposalId);

        // reference ProposalManagement.sol
        if (existingVote.proposalId == proposalToUpdate.id) {
            if (proposalToUpdate.proposalStatus == IProposalManagement.ProposalStatus.Queued) {
                revert Voting__CannotDeleteQueuedVote();
            }
        }

        delete existingVote;
    
        uint256 nowTs = block.timestamp;

        // Remove from DAO votes list
        for (uint256 i = 0; i < s_allVotes.length; i++) {
            if (s_allVotes[i].id == _voteId) {
                s_allVotes[i] = s_allVotes[s_allVotes.length - 1];
                s_allVotes.pop();

                break;
            }
        }

        Vote[] memory memberVotes = memberAddressToMemberVoteHistory[msg.sender]; 

        // Also remove from member's votes list
        for (uint256 i = 0; i < memberVotes.length; i++) {
            if (memberVotes[i].id == _voteId) {
                memberVotes[i] = memberVotes[memberVotes.length - 1];
                memberAddressToMemberVoteHistory[msg.sender].pop();

                break;
            }
        }
        
        Vote[] memory proposalVoteHistory = proposalIdToProposalVoteHistory[existingVote.proposalId]; 

        // Also remove from the proposals votes history array
        for (uint256 i = 0; i < proposalVoteHistory.length; i++) {
            if (proposalVoteHistory[i].id == _voteId) {
                proposalVoteHistory[i] = proposalVoteHistory[proposalVoteHistory.length - 1];
                proposalIdToProposalVoteHistory[proposalVoteHistory[i].id].pop();

                break;
            }
        }

        emit DAOVoteRecorded(
            "vote removed succesfully",
            _voteId,
            existingVote.proposalId,
            // keccak256(bytes(existingVote.proposalCodeName)),
            existingVote.memberAddress,
            existingVote.action,
            nowTs
        );
    }

    function getMemberVoteOnProposal(
        address _memberAddress,
        uint256 _proposalId
    ) external view returns (Vote memory) {
        // _verifyIsAddress(function) -       _verifyIsAddress(_memberAddress);
        _checkIds(_proposalId);
        
        return (memberAddressToProposalIdToVote[_memberAddress][_proposalId]);
    }

    function getMemberVoteHistory(
        address _memberAddress
    ) external view returns (Vote[] memory) {
        // _verifyIsAddress(function) -       _verifyIsAddress(_memberAddress);

        return memberAddressToMemberVoteHistory[_memberAddress];
    }

    function getDAOVoteHistory() external view returns (Vote[] memory) {
        return s_allVotes;
    }

    function getDAOVoteHistoryOnProposal(
        uint256 _proposalId
    ) external view returns (Vote[] memory) {
        _checkIds(_proposalId);

        return proposalIdToProposalVoteHistory[_proposalId];
    }
}
