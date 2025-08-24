// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAdminManagement__Core {
    // ---- Core Admin Checks ----
    function checkIsAdmin(address account) external view returns (bool);

    // ---- Metadata / Utilities ----
    function getContractName() external pure returns (string memory);
    function getContractOwner() external view returns (address);
    function ping() external view returns (string memory, address, uint256);
}
