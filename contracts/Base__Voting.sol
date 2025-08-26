// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "./ProposalManagement.sol";
import "./auth/MembershipAuth.sol";
import "./auth/OnlyOwnerAuth.sol";
import "./interfaces/ILolaUSD__Base.sol";
import "./interfaces/IProposalManagement__Base.sol";
import "./interfaces/IMembership__Base.sol";
import "./interfaces/IAdminManagement__Base.sol";

contract Base__Voting is MembershipAuth, OnlyOwnerAuth {
    // error Voting__NotDAOMember();
    // error Voting__ZeroAddressError();
    // error Voting__InvalidMemberId();
    error Voting__InvalidIdError();
    error Voting__EmptyProposalCodeName();
    // error Voting__NoExistingVote();
    error Voting__NoMutipleVoting();
    // error Voting__CannotDeleteQueuedVote();
    error Voting__InsufficientVotingBalance();
    error Voting__ProposalIsNotActive();
    // error Voting__VotingIsCompleted(IProposalManagement__Base.ProposalStatus _proposalStatus);

    enum VoteAction {
        Approve,
        Reject
    }

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

    mapping(address => Vote[]) public s_memberAddressToMemberVoteHistory;
    mapping(address => mapping(uint256 => Vote))
        public s_memberAddressToProposalIdToVote;
    mapping(uint256 => Vote[]) public s_proposalIdToProposalVoteHistory;
    mapping(uint256 => Vote) public s_voteIdToVote;

    address internal s_lolaUSDCoreContractAddress;
    address internal s_proposalManagementCoreContractAddress;
    address internal s_adminManagementCoreContractAddress;
    // address internal s_membershipContractAddress;

    ILolaUSD__Base internal s_lolaUSDContract__Base =
        ILolaUSD__Base(s_lolaUSDCoreContractAddress);
    IProposalManagement__Base internal s_proposalManagementContract__Base =
        IProposalManagement__Base(s_proposalManagementCoreContractAddress);
    IAdminManagement__Base internal s_adminManagementContract__Base =
        IAdminManagement__Base(s_adminManagementCoreContractAddress);
    // IMembership internal membershipContract = IMembership(s_membershipContractAddress);

    Vote[] private s_allVotes;

    function _checkIds(uint256 _proposalId) internal pure {
        if (_proposalId == 0) revert Voting__InvalidIdError();
    }

    function _checkProposalCodeName(
        string memory _proposalCodeName
    ) internal pure {
        if (bytes(_proposalCodeName).length == 0)
            revert Voting__EmptyProposalCodeName();
    }

    function castVote(
        uint256 _proposalId,
        // string calldata _proposalCodeName,
        VoteAction _action
    )
        external
        // onlyDAOMember(modifier) - from => ProposalManagement.sol -> MembershipAuth.sol
        onlyDAOMember(msg.sender)
    {
        _checkIds(_proposalId);
        // _checkProposalCodeName(_proposalCodeName);

        if (
            s_lolaUSDContract__Base.balanceOf(msg.sender) <
            s_minimumVotingBalanceRequirement
        ) {
            revert Voting__InsufficientVotingBalance();
        }

        IProposalManagement__Base.Proposal
            memory proposal = s_proposalManagementContract__Base.getProposalById(
                _proposalId
            );

        if (
            proposal.proposalStatus !=
            IProposalManagement__Base.ProposalStatus.Active
        ) {
            revert Voting__ProposalIsNotActive();
        }

        // prevent duplicate voting
        Vote[] memory proposalVotes = s_proposalIdToProposalVoteHistory[
            _proposalId
        ];

        for (uint256 i = 0; i < proposalVotes.length; i++) {
            if (proposalVotes[i].memberAddress == msg.sender) {
                revert Voting__NoMutipleVoting();
            }
        }

        uint256 voteId = s_allVotes.length > 0
            ? s_allVotes[s_allVotes.length - 1].id + 1
            : 1;
        uint256 nowTs = block.timestamp;

        Vote memory newVote = Vote({
            id: voteId,
            addedAt: block.timestamp,
            proposalId: _proposalId,
            // proposalCodeName: _proposalCodeName,
            memberAddress: msg.sender,
            action: _action
        });

        s_memberAddressToMemberVoteHistory[msg.sender].push(newVote);
        s_proposalIdToProposalVoteHistory[_proposalId].push(newVote);
        s_memberAddressToProposalIdToVote[msg.sender][_proposalId] = newVote;
        s_voteIdToVote[voteId] = newVote;
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

        // this external function will update the proposal to success or failure once the vote is completed
        s_proposalManagementContract__Base.updateDAOProposalStatus__FailOrSuccess(
            _proposalId
        );
    }

    function getMemberVoteOnProposal(
        address _memberAddress,
        uint256 _proposalId
    ) external view returns (Vote memory) {
        // _verifyIsAddress(function) -       _verifyIsAddress(_memberAddress);
        _checkIds(_proposalId);

        return (s_memberAddressToProposalIdToVote[_memberAddress][_proposalId]);
    }

    function getMemberVoteHistory(
        address _memberAddress
    ) external view returns (Vote[] memory) {
        // _verifyIsAddress(function) -       _verifyIsAddress(_memberAddress);

        return s_memberAddressToMemberVoteHistory[_memberAddress];
    }

    function getDAOVoteHistory() external view returns (Vote[] memory) {
        return s_allVotes;
    }

    // this to get all the votes including vote details - but more gas intensive
    // function getDAOVoteHistoryOnProposal(
    // uint256 _proposalId
    //     ) external view returns (Vote[] memory _approvals, Vote[] memory _rejections) {
    //         _checkIds(_proposalId);

    //         Vote[] memory proposalVotes = s_proposalIdToProposalVoteHistory[_proposalId];

    //         uint256 approvalsCount;
    //         uint256 rejectionsCount;

    //         // First loop: count
    //         for (uint256 i = 0; i < proposalVotes.length; i++) {
    //             if (proposalVotes[i].action == VoteAction.Approve) {
    //                 approvalsCount++;
    //             } else {
    //                 rejectionsCount++;
    //             }
    //         }

    //         // Allocate memory arrays with fixed size
    //         _approvals = new Vote[](approvalsCount);
    //         _rejections = new Vote[](rejectionsCount);

    //         // Second loop: assign values
    //         uint256 aIndex;
    //         uint256 rIndex;

    //         for (uint256 i = 0; i < proposalVotes.length; i++) {
    //             if (proposalVotes[i].action == VoteAction.Approve) {
    //                 _approvals[aIndex] = proposalVotes[i];
    //                 aIndex++;
    //             } else {
    //                 _rejections[rIndex] = proposalVotes[i];
    //                 rIndex++;
    //             }
    //         }

    //         return (_approvals, _rejections);
    // }

    function getDAOVoteCountsOnProposal(
        uint256 _proposalId
    ) external view returns (uint256 approvals, uint256 rejections) {
        _checkIds(_proposalId);

        Vote[] memory proposalVotes = s_proposalIdToProposalVoteHistory[
            _proposalId
        ];

        uint256 approvalsCount;
        uint256 rejectionsCount;

        for (uint256 i = 0; i < proposalVotes.length; i++) {
            if (proposalVotes[i].action == VoteAction.Approve) {
                approvals++;
            } else {
                rejections++;
            }
        }

        return (approvalsCount, rejectionsCount);
    }
}
