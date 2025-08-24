// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "./interfaces/Interface__AdminManagement.sol";

interface IProposalManagement__Base {
    // ------------------------
    // Errors
    // ------------------------
    error ProposalManagement__ProposalCodeNameCannotBeEmpty();
    error ProposalManagement__ProposalNotFound();
    error ProposalManagement__ProposalAlreadyExist(string proposalCodeName);
    error ProposalManagement__NotDAOMember();
    error ProposalManagement__ZeroAddressError();
    error ProposalManagement__AdminAndProposalAuthorOnly();
    error ProposalManagement__InvalidIdError();
    error ProposalManagement__EmptyProposalCodeName();
    error ProposalManagement__AccessDenied_AdminOnly();

    // ------------------------
    // Enums
    // ------------------------
    enum ProposalAction {
        Mint,
        Burn,
        Other
    }
    enum ProposalStatus {
        Created,
        Active,
        Successful,
        Failed,
        Queued,
        Executed
    }

    // ------------------------
    // Structs
    // ------------------------
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

    // ------------------------
    // Events
    // ------------------------
    event DAOProposalManagement(
        uint256 id,
        string indexed proposalCodeName,
        ProposalAction indexed proposalAction,
        uint256 tokenSupplyChange,
        address indexed addedBy,
        uint256 timestamp,
        ProposalStatus proposalStatus
    );

    // ------------------------
    // Functions
    // ------------------------
    function createDAOProposal(
        string memory _proposalCodeName,
        ProposalAction _proposalAction,
        uint256 _tokenSupplyChange,
        string memory _proposalMetaDataCID,
        ProposalStatus _proposalStatus
    ) external;

    function removeDAOProposal(string memory _proposalCodeName) external;

    function updateDAOProposal(
        string memory _proposalCodeName,
        ProposalAction _proposalAction,
        uint256 _tokenSupplyChange,
        string memory _proposalMetaDataCID,
        uint256 _proposalId
    ) external;

    function updateDAOProposalStatus__FailOrSuccess(
        uint256 _proposalId
    ) external;

    function getAllDAOProposals() external view returns (Proposal[] memory);

    function getProposalById(
        uint256 _proposalId
    ) external view returns (Proposal memory);

    function getMemberProposals(
        address _memberAddress
    ) external view returns (Proposal[] memory);

    function executeProposal(uint256 _proposalId) external;
}
