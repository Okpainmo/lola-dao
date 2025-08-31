// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IAdminManagement__Base.sol";
import "./interfaces/IVoting__Base.sol";
import "./interfaces/IMembership__Base.sol";
import "./interfaces/ILolaUSD__Core.sol";

contract Base__ProposalManagement {
    error ProposalManagement__ProposalCodeNameCannotBeEmpty();
    error ProposalManagement__ProposalNotFound();
    error ProposalManagement__ProposalAlreadyExist(Proposal proposal);
    error ProposalManagement__NotDAOMember();
    error ProposalManagement__ProposalAuthorOnly();
    error ProposalManagement__ZeroAddressError();
    error ProposalManagement__AdminAndProposalAuthorOnly();
    error ProposalManagement__InvalidIdError();
    error ProposalManagement__EmptyProposalCodeName();
    error ProposalManagement__AccessDenied_AdminOnly();
    error ProposalManagement__ProposalIsAlreadyActive();
    error ProposalManagement__ProposalIsNotYetSuccessful();
    error ProposalManagement__ProposalIsNotQueued();
    error ProposalManagement__ProposalStillInProgress();
    error ProposalManagement__ProposalTypeIsMintOrBurn();
    error ProposalManagement__CannotUpdateActiveProposal();
    error ProposalManagement__NewCountIsInvalid();

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
        bool exists;
    }

    address internal immutable i_owner;

    /* 
    The ledger Id tracker, is a counter that helps to prevent re-use of ids on previously created entries(proposals). 
    This simply means that an id can only be used once - like in regular off-chain databases. By addding this, even when a 
    proposal is removed for any reason, the tracker can simply continue the count without depending on a check of the length
    of the proposals array, since using that length will permit re-using Ids - which can result in conflicts, e.g. if the previous 
    proposal with the same id as a newly created one already has some DAO votes 
    
    This problem will still re-surface is for any reason a new proposal contract is deployed(as the tracker will reset to 0). 
    The solution to this, will be to migrate over the proposal state on the previous contract, then use the 
    "updateLedgerIdTracker" function to reset the counter.
    */
    uint256 s_ledgerIdTracker = 0;

    Proposal[] internal s_DAOProposalsHistory;
    mapping(string => Proposal) internal s_proposalCodeNameToProposal;
    mapping(uint256 => Proposal) internal s_proposalIdToProposal;
    mapping(address => Proposal[]) internal s_memberToMemberProposals;

    address internal s_adminManagementCoreContractAddress;
    address internal s_votingCoreContractAddress;
    address internal s_membershipCoreContractAddress;
    address internal s_lolaUSDCoreContractAddress;

    IAdminManagement__Base internal s_adminManagementContract__Base =
        IAdminManagement__Base(s_adminManagementCoreContractAddress);
    IVoting__Base internal s_votingContract__base =
        IVoting__Base(s_votingCoreContractAddress);
    IMembership__Base internal s_membershipContract__Base =
        IMembership__Base(s_membershipCoreContractAddress);
        ILolaUSD__Core internal s_lolaUSDContract__Core =
    ILolaUSD__Core(s_lolaUSDCoreContractAddress);

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
            revert ProposalManagement__ProposalAlreadyExist(s_proposalCodeNameToProposal[_proposalCodeName]);
        }

        s_ledgerIdTracker = s_ledgerIdTracker + 1;
        uint256 proposalId = s_ledgerIdTracker;

        Proposal memory newProposal = Proposal({
            id: proposalId,
            proposalCodeName: _proposalCodeName,
            addedBy: msg.sender,
            addedAt: block.timestamp,
            proposalAction: _proposalAction,
            tokenSupplyChange: _tokenSupplyChange,
            proposalMetaDataCID: _proposalMetaDataCID,
            proposalStatus: ProposalStatus.Created,
            exists: true
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
    ) external {
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

        if (
            existingProposal.addedBy != msg.sender
        ) {
            revert ProposalManagement__ProposalAuthorOnly();
        }

        // ✅ Copy into memory so we don't lose the values after delete
        Proposal memory proposalCopy = existingProposal;
            
        delete s_proposalCodeNameToProposal[proposalCopy.proposalCodeName];
        delete s_proposalIdToProposal[proposalCopy.id];

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

        // ✅ Use the memory copy for the event
        emit DAOProposalManagement(
            proposalCopy.id,
            proposalCopy.proposalCodeName,
            proposalCopy.proposalAction,
            proposalCopy.tokenSupplyChange,
            msg.sender,
            block.timestamp,
            proposalCopy.proposalStatus
        );
    }

    function updateDAOProposal(
        string memory _newProposalCodeName,
        ProposalAction _newProposalAction,
        uint256 _newTokenSupplyChange,
        string memory _newProposalMetaDataCID,
        uint256 _proposalId
    )
        external
    {
        if (bytes(_newProposalCodeName).length == 0) {
            revert ProposalManagement__ProposalCodeNameCannotBeEmpty();
        }

        if (
            s_proposalIdToProposal[_proposalId].exists != true
        ) {
            revert ProposalManagement__ProposalNotFound();
        }

        Proposal storage existingProposal = s_proposalIdToProposal[_proposalId];

        if (existingProposal.addedBy != msg.sender) {
            revert ProposalManagement__ProposalAuthorOnly();
        }

        if (
            s_proposalIdToProposal[_proposalId].proposalStatus == ProposalStatus.Active
        ) {
            revert ProposalManagement__CannotUpdateActiveProposal();
        }

        existingProposal.proposalCodeName = _newProposalCodeName;
        existingProposal.proposalAction = _newProposalAction;
        existingProposal.tokenSupplyChange = _newTokenSupplyChange;
        existingProposal.addedAt = block.timestamp;
        existingProposal.proposalMetaDataCID = _newProposalMetaDataCID;

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

        s_proposalCodeNameToProposal[_newProposalCodeName] = existingProposal;
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

    function _handleProposalStatusUpdateFinish(uint256 _proposalId, Proposal memory _existingProposal) private {
        for (uint256 i = 0; i < s_DAOProposalsHistory.length; i++) {
            if (s_DAOProposalsHistory[i].id == _proposalId) {
                s_DAOProposalsHistory[i] = _existingProposal;

                break;
            }
        }

        for (uint256 i = 0; i < s_memberToMemberProposals[
            _existingProposal.addedBy
        ].length; i++) {
            if (s_memberToMemberProposals[
            _existingProposal.addedBy
        ][i].id == _proposalId) {
                s_memberToMemberProposals[
            _existingProposal.addedBy][i] = _existingProposal;

                break;
            }
        }

        s_proposalCodeNameToProposal[
            _existingProposal.proposalCodeName] = _existingProposal;
        s_proposalIdToProposal[_existingProposal.id] = _existingProposal;

        emit DAOProposalManagement(
            _existingProposal.id,
            // "DAO Proposal updated successfully",
            _existingProposal.proposalCodeName,
            _existingProposal.proposalAction,
            _existingProposal.tokenSupplyChange,
            msg.sender,
            block.timestamp,
            _existingProposal.proposalStatus
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
        
        if(!existingProposal.exists) {
            revert ProposalManagement__ProposalNotFound();
        }

        // you only queue a successful proposal
        if (existingProposal.proposalStatus != ProposalStatus.Successful) {
            revert ProposalManagement__ProposalIsNotYetSuccessful();
        }

        existingProposal.proposalStatus = ProposalStatus.Queued;

        _handleProposalStatusUpdateFinish(_proposalId, existingProposal);
    }

    function activateProposal(uint256 _proposalId) public {
        _checkIds(_proposalId);

        _verifyIsAdmin(msg.sender);

        Proposal storage existingProposal = s_proposalIdToProposal[_proposalId];

        if(!existingProposal.exists) {
            revert ProposalManagement__ProposalNotFound();
        }

        if (existingProposal.proposalStatus != ProposalStatus.Created) {
            revert ProposalManagement__ProposalIsAlreadyActive();
        }

        existingProposal.proposalStatus = ProposalStatus.Active;

        _handleProposalStatusUpdateFinish(_proposalId, existingProposal);
    }

    function executeProposal(uint256 _proposalId) external {
        // will be called in the token(stablecoin) contract - after either minting or burning
        _checkIds(_proposalId);

        _verifyIsAdmin(msg.sender);

        Proposal storage existingProposal = s_proposalIdToProposal[_proposalId];

        if(!existingProposal.exists) {
            revert ProposalManagement__ProposalNotFound();
        }

        ( ,address tokenContractAddress, ) = s_lolaUSDContract__Core.ping();

        /* check to prevent manually executing proposals for minting and burning - those will be automatically/
        programatically executed from within the token contract mint or burn functions respectively */
        if (existingProposal.tokenSupplyChange != 0 && msg.sender != tokenContractAddress) {
            revert ProposalManagement__ProposalTypeIsMintOrBurn();
        }

        if (existingProposal.proposalStatus != ProposalStatus.Queued) {
            revert ProposalManagement__ProposalIsNotQueued();
        }

        existingProposal.proposalStatus = ProposalStatus.Executed;

        _handleProposalStatusUpdateFinish(_proposalId, existingProposal);
    }

    function _determineProposalStatus(
        uint256 _totalMembersCount,
        uint256 _positiveVotes,
        uint256 _negativeVotes,
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
    ) external returns(uint256, uint256, uint256, Proposal memory, ProposalStatus) {
        // to be called from the externally deployed "Core__Voting" contract
        _checkIds(_proposalId);
        _verifyIsAdmin(msg.sender);

        Proposal storage existingProposal = s_proposalIdToProposal[_proposalId];

        if(!existingProposal.exists) {
            revert ProposalManagement__ProposalNotFound();
        }

        uint256 totalMembersCount = s_membershipContract__Base.getDAOMembers().length;
        (
            uint256 totalPositiveVotes,
            uint256 totalNegativeVotes
        ) = s_votingContract__base.getDAOVoteCountsOnProposal(_proposalId);
        // uint256 totalProposalVotes = totalNegativeVotes + totalPositiveVotes;

        ProposalStatus status = _determineProposalStatus(
            totalMembersCount,
            totalPositiveVotes,
            totalNegativeVotes,
            existingProposal
        );

        // if(status != ProposalStatus.Failed && status != ProposalStatus.Successful) {
        //     revert ProposalManagement__ProposalStillInProgress();
        // }

        existingProposal.proposalStatus = status;

        /* NB: only the proposal id(which cannot changed or be updated) should be added(linked) to a vote. This will 
       prevent the need to handle the gas-intensive process of having to update all platform votes(in case of 
       a proposal update) - to reflect the update on the(their) parent proposal */

        _handleProposalStatusUpdateFinish(_proposalId, existingProposal);

        return(totalMembersCount,
            totalPositiveVotes,
            totalNegativeVotes,
            existingProposal,
            status);
    }   

    // always update with the old proposals state first before attempting to update this - in case a new contract is deployed
    function updateLedgerIdTracker(uint256 _newCount) public {
        _verifyIsAdmin(msg.sender);

        if(s_DAOProposalsHistory.length != _newCount) {
            revert ProposalManagement__NewCountIsInvalid();
        }

        s_ledgerIdTracker = _newCount;
    }

    function getProposalsLedgerCount() public view returns(uint256) {
        return s_ledgerIdTracker;
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
