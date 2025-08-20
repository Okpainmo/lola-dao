    // Should not be possible. Voting should simulate real-life voting scenarios - once voted - you've voted
    // function updateVote(
    //     VoteAction _newAction,
    //     uint256 _voteId
                
    // // onlyDAOMember(modifier) - MembershipAuth.sol
    // // onlyOwner(modifier) - OnlyOwnerAuth.sol
    // ) external onlyDAOMember(msg.sender) onlyOwner(msg.sender) {
    //     _checkIds(_voteId);
    //     Vote memory existingVote = voteIdToVote[_voteId];

    //     if (existingVote.id != _voteId) {
    //         revert Voting__NoExistingVote();
    //     }

    //     uint256 nowTs = block.timestamp;

    //     Vote memory updatedVote = Vote({
    //         id: existingVote.id,
    //         addedAt: existingVote.addedAt,
    //         proposalId: existingVote.proposalId,
    //         // proposalCodeName: existingVote.proposalCodeName,
    //         memberAddress: existingVote.memberAddress,
    //         action: _newAction
    //     });

    //     voteIdToVote[_voteId] = updatedVote;

    //     // update the all votes array
    //     for (uint256 i = 0; i < s_allVotes.length; i++) {
    //         if (existingVote.id == _voteId) {
    //             s_allVotes[i] = updatedVote;

    //             break;
    //         }
    //     }

    //     Vote[] memory memberVotes = memberAddressToMemberVoteHistory[msg.sender]; 

    //     // also update the member votes array
    //     for (uint256 i = 0; i < memberVotes.length; i++) {
    //         if (memberVotes[i].id == _voteId) {
    //             memberVotes[i] = updatedVote;

    //             break;
    //         }
    //     }

    //     Vote[] memory proposalVoteHistory = proposalIdToProposalVoteHistory[existingVote.proposalId]; 

    //     // also update the proposal votes history array
    //     for (uint256 i = 0; i < proposalVoteHistory.length; i++) {
    //         if (proposalVoteHistory[i].id == _voteId) {
    //             proposalVoteHistory[i] = updatedVote;

    //             break;
    //         }
    //     }

    //     emit DAOVoteRecorded(
    //         "vote updated successfully",
    //         existingVote.id,
    //         existingVote.proposalId,
    //         // keccak256(bytes(existingVote.proposalCodeName)),
    //         msg.sender,
    //         _newAction,
    //         nowTs
    //     );
    // }

    // Should not be possible. Voting should simulate real-life voting scenarios - once voted - you've voted
    // function removeVote(
    //     uint256 _voteId
                
    // // onlyDAOMember(modifier) - MembershipAuth.sol
    // // onlyOwner(modifier) - OnlyOwnerAuth.sol
    // ) external onlyDAOMember(msg.sender) onlyOwner(msg.sender) {
    //     Vote memory existingVote = voteIdToVote[_voteId];

    //     if (existingVote.id != _voteId) {
    //         revert Voting__NoExistingVote();
    //     }

    //     IProposalManagement.Proposal memory proposalToUpdate =  proposalManagementContract.getProposalById(existingVote.proposalId);

    //     // reference ProposalManagement.sol
    //     if (existingVote.proposalId == proposalToUpdate.id) {
    //         if (proposalToUpdate.proposalStatus == IProposalManagement.ProposalStatus.Queued) {
    //             revert Voting__CannotDeleteQueuedVote();
    //         }
    //     }

    //     delete existingVote;
    
    //     uint256 nowTs = block.timestamp;

    //     // Remove from DAO votes list
    //     for (uint256 i = 0; i < s_allVotes.length; i++) {
    //         if (s_allVotes[i].id == _voteId) {
    //             s_allVotes[i] = s_allVotes[s_allVotes.length - 1];
    //             s_allVotes.pop();

    //             break;
    //         }
    //     }

    //     Vote[] memory memberVotes = memberAddressToMemberVoteHistory[msg.sender]; 

    //     // Also remove from member's votes list
    //     for (uint256 i = 0; i < memberVotes.length; i++) {
    //         if (memberVotes[i].id == _voteId) {
    //             memberVotes[i] = memberVotes[memberVotes.length - 1];
    //             memberAddressToMemberVoteHistory[msg.sender].pop();

    //             break;
    //         }
    //     }
        
    //     Vote[] memory proposalVoteHistory = proposalIdToProposalVoteHistory[existingVote.proposalId]; 

    //     // Also remove from the proposals votes history array
    //     for (uint256 i = 0; i < proposalVoteHistory.length; i++) {
    //         if (proposalVoteHistory[i].id == _voteId) {
    //             proposalVoteHistory[i] = proposalVoteHistory[proposalVoteHistory.length - 1];
    //             proposalIdToProposalVoteHistory[proposalVoteHistory[i].id].pop();

    //             break;
    //         }
    //     }

    //     emit DAOVoteRecorded(
    //         "vote removed succesfully",
    //         _voteId,
    //         existingVote.proposalId,
    //         // keccak256(bytes(existingVote.proposalCodeName)),
    //         existingVote.memberAddress,
    //         existingVote.action,
    //         nowTs
    //     );
    // }