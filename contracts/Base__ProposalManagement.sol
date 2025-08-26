// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./auth/MembershipAuth.sol";
// import "./auth/AdminAuth.sol";
import "./auth/OnlyOwnerAuth.sol";
// import "./interfaces/Interface__LolaUSD.sol";
import "./interfaces/IAdminManagement__Base.sol";
import "./interfaces/IVoting__Base.sol";
import "./interfaces/IMembership__Base.sol";

contract Base__ProposalManagement is MembershipAuth, OnlyOwnerAuth {
    error ProposalManagement__ProposalCodeNameCannotBeEmpty();
    error ProposalManagement__ProposalNotFound();
    error ProposalManagement__ProposalAlreadyExist(string proposalCodeName);
    error ProposalManagement__NotDAOMember();
    error ProposalManagement__ZeroAddressError();
    error ProposalManagement__AdminAndProposalAuthorOnly();
    error ProposalManagement__InvalidIdError();
    error ProposalManagement__EmptyProposalCodeName();
    error ProposalManagement__AccessDenied_AdminOnly();
    // error ProposalManagement__ProcessCannotBeManual();
    // error ProposalManagement__VotingInProgress();
    // error ProposalManagement__VotingEndedProposalFailed();
    error ProposalManagement__ProposalIsAlreadyActive();
    // error ProposalManagement__InactiveProposal();
    error ProposalManagement__ProposalCannotBeQueued();
    error ProposalManagement__ProposalIsNotQueued();

    enum ProposalAction {
        Mint,
        Burn,
        Other
    }
    enum ProposalStatus {
        Created, // proposal is created
        Active, // admin views proposal, ensures it passes all standards, then activate it for voting to commence
        Successful, // proposal passes criteria for execution
        Failed, // proposal fails to pass criteria for execution
        Queued, // proposal is queued for execution
        Executed // proposal is executed
    }

    event DAOProposalManagement(
        uint256 id,
        // string message,
        string indexed proposalCodeName,
        ProposalAction indexed proposalAction,
        uint256 tokenSupplyChange,
        address indexed addedBy,
        uint256 timestamp,
        ProposalStatus proposalStatus
    );

    struct Proposal {
        uint256 id;
        ProposalStatus proposalStatus;
        string proposalCodeName;
        address addedBy;
        uint256 addedAt;
        ProposalAction proposalAction;
        uint256 tokenSupplyChange;
        string proposalMetaDataCID;
    }

    Proposal[] internal s_DAOProposalsHistory;
    mapping(string => Proposal) internal s_proposalCodeNameToProposal;
    mapping(uint256 => Proposal) internal s_proposalIdToProposal;
    mapping(address => Proposal[]) internal s_memberToMemberProposals;

    address internal s_adminManagementCoreContractAddress;
    address internal s_votingCoreContractAddress;
    address internal s_membershipCoreContractAddress;
    // address internal s_lolaUSDCoreContractAddress;

    // ILolaUSD internal lolaUSDContract = ILolaUSD(s_lolaUSDCoreContractAddress);
    IAdminManagement__Base internal s_adminManagementContract__Base =
        IAdminManagement__Base(s_adminManagementCoreContractAddress);
    IVoting__Base internal s_votingContract__base =
        IVoting__Base(s_votingCoreContractAddress);
    IMembership__Base internal s_membershipContract__Base =
        IMembership__Base(s_membershipCoreContractAddress);

    function _verifyIsAddress(address _address) internal pure virtual {
        if (_address == address(0)) {
            revert ProposalManagement__ZeroAddressError();
        }
    }

    function _verifyIsAdmin(address _address) internal view virtual {
        if (!s_adminManagementContract__Base.checkIsAdmin(_address)) {
            revert ProposalManagement__AccessDenied_AdminOnly();
        }
    }

    function _checkIds(uint256 _proposalId) internal pure virtual {
        if (_proposalId == 0) revert ProposalManagement__InvalidIdError();
    }

    function _checkProposalCodeName(
        string memory _proposalCodeName
    ) internal pure virtual {
        if (bytes(_proposalCodeName).length == 0)
            revert ProposalManagement__EmptyProposalCodeName();
    }

    function createDAOProposal(
        string memory _proposalCodeName,
        ProposalAction _proposalAction,
        uint256 _tokenSupplyChange,
        string memory _proposalMetaDataCID
    ) external {
        bool isMember = s_membershipContract__Base.checkIsDAOMember(msg.sender);

        if(!isMember) {
            revert ProposalManagement__NotDAOMember();
        }

        if (bytes(_proposalCodeName).length == 0) {
            revert ProposalManagement__ProposalCodeNameCannotBeEmpty();
        }

        // prevent duplicate Proposal names
        if (
            bytes(
                s_proposalCodeNameToProposal[_proposalCodeName].proposalCodeName
            ).length != 0
        ) {
            revert ProposalManagement__ProposalAlreadyExist(_proposalCodeName);
        }

        uint256 proposalId = s_DAOProposalsHistory.length > 0
            ? s_DAOProposalsHistory[s_DAOProposalsHistory.length - 1].id + 1
            : 1;

        Proposal memory newProposal = Proposal({
            id: proposalId,
            proposalCodeName: _proposalCodeName,
            addedBy: msg.sender,
            addedAt: block.timestamp,
            proposalAction: _proposalAction,
            tokenSupplyChange: _tokenSupplyChange,
            proposalMetaDataCID: _proposalMetaDataCID,
            proposalStatus: ProposalStatus.Created
        });

        s_DAOProposalsHistory.push(newProposal);
        s_proposalCodeNameToProposal[_proposalCodeName] = newProposal;
        s_proposalIdToProposal[proposalId] = newProposal;
        s_memberToMemberProposals[msg.sender].push(newProposal);

        emit DAOProposalManagement(
            proposalId,
            // "DAO Proposal created successfully",
            _proposalCodeName,
            _proposalAction,
            _tokenSupplyChange,
            msg.sender,
            block.timestamp,
            ProposalStatus.Created
        );
    }

    function removeDAOProposal(
        string memory _proposalCodeName
    ) external onlyDAOMember(msg.sender) {
        if (bytes(_proposalCodeName).length == 0) {
            revert ProposalManagement__ProposalCodeNameCannotBeEmpty();
        }

        if (
            bytes(
                s_proposalCodeNameToProposal[_proposalCodeName].proposalCodeName
            ).length == 0
        ) {
            revert ProposalManagement__ProposalNotFound();
        }

        // Proposal the mapping entry - only an Proposal you added
        Proposal storage existingProposal = s_proposalCodeNameToProposal[
            _proposalCodeName
        ];

        // s_isAdmin(variable) - from => Voting.sol -> AdminAuth.sol
        if (
            existingProposal.addedBy != msg.sender &&
            !s_adminManagementContract__Base.checkIsAdmin(msg.sender)
        ) {
            revert ProposalManagement__AdminAndProposalAuthorOnly();
        }

        // Remove from s_DAOProposalsHistory array
        for (uint256 i = 0; i < s_DAOProposalsHistory.length; i++) {
            if (
                keccak256(bytes(s_DAOProposalsHistory[i].proposalCodeName)) ==
                keccak256(bytes(_proposalCodeName))
            ) {
                s_DAOProposalsHistory[i] = s_DAOProposalsHistory[
                    s_DAOProposalsHistory.length - 1
                ];
                s_DAOProposalsHistory.pop();

                break;
            }
        }

        // Remove from member proposals history array
        Proposal[] storage memberProposals = s_memberToMemberProposals[
            existingProposal.addedBy
        ];

        for (uint256 i = 0; i < memberProposals.length; i++) {
            if (
                keccak256(bytes(memberProposals[i].proposalCodeName)) ==
                keccak256(bytes(_proposalCodeName))
            ) {
                memberProposals[i] = memberProposals[
                    memberProposals.length - 1
                ];
                memberProposals.pop();

                break;
            }
        }

        emit DAOProposalManagement(
            existingProposal.id,
            // "DAO Proposal removed successfully",
            existingProposal.proposalCodeName,
            existingProposal.proposalAction,
            existingProposal.tokenSupplyChange,
            msg.sender,
            block.timestamp,
            existingProposal.proposalStatus
        );

        delete s_proposalCodeNameToProposal[_proposalCodeName];
        delete s_proposalIdToProposal[existingProposal.id];
    }

    function updateDAOProposal(
        string memory _proposalCodeName,
        ProposalAction _proposalAction,
        uint256 _tokenSupplyChange,
        string memory _proposalMetaDataCID,
        uint256 _proposalId
    )
        external
        // ProposalStatus _proposalStatus // only admin should be able to update proposal status - see dedicated function below

        // onlyDAOMember(modifier) - from => Voting.sol -> MembershipAuth.sol
        // onlyOwner(modifier) - from => Voting.sol -> OnlyOwnerAuth.sol
        onlyDAOMember(msg.sender)
        onlyOwner(msg.sender)
    {
        if (bytes(_proposalCodeName).length == 0) {
            revert ProposalManagement__ProposalCodeNameCannotBeEmpty();
        }

        if (
            bytes(
                s_proposalCodeNameToProposal[_proposalCodeName].proposalCodeName
            ).length == 0
        ) {
            revert ProposalManagement__ProposalNotFound();
        }

        Proposal storage existingProposal = s_proposalCodeNameToProposal[
            _proposalCodeName
        ];

        existingProposal.proposalAction = _proposalAction;
        existingProposal.tokenSupplyChange = _tokenSupplyChange;
        existingProposal.addedAt = block.timestamp;
        existingProposal.proposalMetaDataCID = _proposalMetaDataCID;
        // existingProposal.proposalStatus = _proposalStatus;

        // also update the s_DAOProposalsHistory array
        for (uint256 i = 0; i < s_DAOProposalsHistory.length; i++) {
            if (s_DAOProposalsHistory[i].id == _proposalId) {
                s_DAOProposalsHistory[i] = existingProposal;

                break;
            }
        }

        // Remove from member proposals history array
        Proposal[] storage memberProposals = s_memberToMemberProposals[
            existingProposal.addedBy
        ];

        for (uint256 i = 0; i < memberProposals.length; i++) {
            if (memberProposals[i].id == _proposalId) {
                memberProposals[i] = existingProposal;

                break;
            }
        }

        s_proposalCodeNameToProposal[_proposalCodeName] = existingProposal;
        s_proposalIdToProposal[existingProposal.id] = existingProposal;

        /* NB: only the proposal id(which cannot changed or be updated) should be added(linked) to a vote. This will 
       prevent the need to handle the gas-intensive process of having to update all platform votes(in case of 
       a proposal update) - to reflect the update on the(their) parent proposal */

        emit DAOProposalManagement(
            existingProposal.id,
            // "DAO Proposal updated successfully",
            existingProposal.proposalCodeName,
            existingProposal.proposalAction,
            existingProposal.tokenSupplyChange,
            msg.sender,
            block.timestamp,
            existingProposal.proposalStatus
        );
    }

    /* 
        The 3 proposal status update tasks below, were split(instead of using one function), due to the different permutations
        /combinations that were possible. and conflicts that could arise. Besides, that makes things easier to read and understand
    */
    function queueProposal(uint256 _proposalId) public {
        _checkIds(_proposalId);

        _verifyIsAdmin(msg.sender);

        Proposal storage existingProposal = s_proposalIdToProposal[_proposalId];

        // you only queue a successful proposal
        if (existingProposal.proposalStatus != ProposalStatus.Successful) {
            revert ProposalManagement__ProposalCannotBeQueued();
        }

        existingProposal.proposalStatus = ProposalStatus.Queued;

        // also update the s_DAOProposalsHistory array
        for (uint256 i = 0; i < s_DAOProposalsHistory.length; i++) {
            if (s_DAOProposalsHistory[i].id == _proposalId) {
                s_DAOProposalsHistory[i] = existingProposal;

                break;
            }
        }

        // Remove from member proposals history array
        Proposal[] storage memberProposals = s_memberToMemberProposals[
            existingProposal.addedBy
        ];

        for (uint256 i = 0; i < memberProposals.length; i++) {
            if (memberProposals[i].id == _proposalId) {
                memberProposals[i] = existingProposal;

                break;
            }
        }

        s_proposalCodeNameToProposal[
            existingProposal.proposalCodeName
        ] = existingProposal;
        s_proposalIdToProposal[existingProposal.id] = existingProposal;

        emit DAOProposalManagement(
            existingProposal.id,
            // "DAO Proposal updated successfully",
            existingProposal.proposalCodeName,
            existingProposal.proposalAction,
            existingProposal.tokenSupplyChange,
            msg.sender,
            block.timestamp,
            existingProposal.proposalStatus
        );
    }

    function activateProposal(uint256 _proposalId) public {
        _checkIds(_proposalId);

        _verifyIsAdmin(msg.sender);

        Proposal storage existingProposal = s_proposalIdToProposal[_proposalId];

        if (existingProposal.proposalStatus != ProposalStatus.Created) {
            revert ProposalManagement__ProposalIsAlreadyActive();
        }

        existingProposal.proposalStatus = ProposalStatus.Queued;

        // also update the s_DAOProposalsHistory array
        for (uint256 i = 0; i < s_DAOProposalsHistory.length; i++) {
            if (s_DAOProposalsHistory[i].id == _proposalId) {
                s_DAOProposalsHistory[i] = existingProposal;

                break;
            }
        }

        // Remove from member proposals history array
        Proposal[] storage memberProposals = s_memberToMemberProposals[
            existingProposal.addedBy
        ];

        for (uint256 i = 0; i < memberProposals.length; i++) {
            if (memberProposals[i].id == _proposalId) {
                memberProposals[i] = existingProposal;

                break;
            }
        }

        s_proposalCodeNameToProposal[
            existingProposal.proposalCodeName
        ] = existingProposal;
        s_proposalIdToProposal[existingProposal.id] = existingProposal;

        emit DAOProposalManagement(
            existingProposal.id,
            // "DAO Proposal updated successfully",
            existingProposal.proposalCodeName,
            existingProposal.proposalAction,
            existingProposal.tokenSupplyChange,
            msg.sender,
            block.timestamp,
            existingProposal.proposalStatus
        );
    }

    function executeProposal(uint256 _proposalId) external {
        // will be called in the token(stablecoin) contract - after either minting or burning
        _checkIds(_proposalId);

        _verifyIsAdmin(msg.sender);

        Proposal storage existingProposal = s_proposalIdToProposal[_proposalId];

        if (existingProposal.proposalStatus != ProposalStatus.Queued) {
            revert ProposalManagement__ProposalIsNotQueued();
        }

        existingProposal.proposalStatus = ProposalStatus.Queued;

        // also update the s_DAOProposalsHistory array
        for (uint256 i = 0; i < s_DAOProposalsHistory.length; i++) {
            if (s_DAOProposalsHistory[i].id == _proposalId) {
                s_DAOProposalsHistory[i] = existingProposal;

                break;
            }
        }

        // Remove from member proposals history array
        Proposal[] storage memberProposals = s_memberToMemberProposals[
            existingProposal.addedBy
        ];

        for (uint256 i = 0; i < memberProposals.length; i++) {
            if (memberProposals[i].id == _proposalId) {
                memberProposals[i] = existingProposal;

                break;
            }
        }

        s_proposalCodeNameToProposal[
            existingProposal.proposalCodeName
        ] = existingProposal;
        s_proposalIdToProposal[existingProposal.id] = existingProposal;

        emit DAOProposalManagement(
            existingProposal.id,
            // "DAO Proposal updated successfully",
            existingProposal.proposalCodeName,
            existingProposal.proposalAction,
            existingProposal.tokenSupplyChange,
            msg.sender,
            block.timestamp,
            existingProposal.proposalStatus
        );
    }

    function determineProposalStatus(
        uint256 _totalMembersCount,
        uint256 _negativeVotes,
        uint256 _positiveVotes,
        Proposal memory _proposal
    ) private pure returns (ProposalStatus) {
        if (
            _totalMembersCount == (_negativeVotes + _positiveVotes) &&
            _negativeVotes > _positiveVotes
        ) {
            return ProposalStatus.Failed;
        }

        if (
            _totalMembersCount == (_negativeVotes + _positiveVotes) &&
            _negativeVotes < _positiveVotes
        ) {
            return ProposalStatus.Successful;
        }

        return _proposal.proposalStatus;
    }

    function updateDAOProposalStatus__FailOrSuccess(
        uint256 _proposalId
    ) external {
        // to be called from the externally deployed "Core__Voting" contract
        _checkIds(_proposalId);
        _verifyIsAdmin(msg.sender);

        Proposal storage existingProposal = s_proposalIdToProposal[_proposalId];

        uint256 totalMembersCount = s_membershipContract__Base.getDAOMembers().length;
        (
            uint256 totalPositiveVotes,
            uint256 totalNegativeVotes
        ) = s_votingContract__base.getDAOVoteCountsOnProposal(_proposalId);
        // uint256 totalProposalVotes = totalNegativeVotes + totalPositiveVotes;

        ProposalStatus status = determineProposalStatus(
            totalMembersCount,
            totalPositiveVotes,
            totalNegativeVotes,
            existingProposal
        );

        existingProposal.proposalStatus = status;

        // also update the s_DAOProposalsHistory array
        for (uint256 i = 0; i < s_DAOProposalsHistory.length; i++) {
            if (s_DAOProposalsHistory[i].id == _proposalId) {
                s_DAOProposalsHistory[i] = existingProposal;

                break;
            }
        }

        // Remove from member proposals history array
        Proposal[] storage memberProposals = s_memberToMemberProposals[
            existingProposal.addedBy
        ];

        for (uint256 i = 0; i < memberProposals.length; i++) {
            if (memberProposals[i].id == _proposalId) {
                memberProposals[i] = existingProposal;

                break;
            }
        }

        s_proposalCodeNameToProposal[
            existingProposal.proposalCodeName
        ] = existingProposal;
        s_proposalIdToProposal[existingProposal.id] = existingProposal;

        /* NB: only the proposal id(which cannot changed or be updated) should be added(linked) to a vote. This will 
       prevent the need to handle the gas-intensive process of having to update all platform votes(in case of 
       a proposal update) - to reflect the update on the(their) parent proposal */

        emit DAOProposalManagement(
            existingProposal.id,
            // "DAO Proposal updated successfully",
            existingProposal.proposalCodeName,
            existingProposal.proposalAction,
            existingProposal.tokenSupplyChange,
            msg.sender,
            block.timestamp,
            existingProposal.proposalStatus
        );
    }

    function getProposalById(
        uint256 _proposalId
    ) public view returns (Proposal memory) {
        _checkIds(_proposalId);

        return s_proposalIdToProposal[_proposalId];
    }

    function getAllDAOProposals() public view returns (Proposal[] memory) {
        return s_DAOProposalsHistory;
    }

    function getMemberProposals(
        address _memberAddress
    ) public view returns (Proposal[] memory) {
        // _verifyIsAddress(function) - from Voting.sol
        _verifyIsAddress(_memberAddress);

        return s_memberToMemberProposals[_memberAddress];
    }
}
