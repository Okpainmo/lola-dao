// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILolaUSD__Core {
    // =========================
    //          Errors
    // =========================
    error LolaUSDCore__ZeroAddressError();
    error LolaUSDCore__AccessDenied_AdminOnly();
    error LolaUSDCore__LogoNameCannotBeEmpty();

    // =========================
    //          Events
    // =========================
    event Logs(string message, uint256 timestamp, string indexed contractName);

    // =========================
    //      View Functions
    // =========================
    function getContractName() external pure returns (string memory);
    function getContractOwner() external view returns (address);
    function getAdminManagementCoreContractAddress() external view returns (address);
    function getProposalManagementCoreContractAddress() external view returns (address);
    function getTokenLogo() external view returns (string memory);
    function getTokenMetadata() external view returns (string memory);

    // =========================
    //   Admin Update Functions
    // =========================
    function updateAdminManagementCoreContractAddress(address _newAddress) external;
    function updateProposalManagementCoreContractAddress(address _newAddress) external;
    function updateTokenLogo(string memory _newLogoCID) external;
    function updateTokenMetaData(string memory _newMetaDataCID) external;

    // =========================
    //         Utility
    // =========================
    function ping() external view returns (string memory, address, uint256);
}
