// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBase__Airdrop {
    // =========================
    //          Errors
    // =========================
    error Airdrop__AirdropCampaignEnded();
    error Airdrop__AirdropLimitCannotBeZero();
    error Airdrop__WalletAlreadyReceivedAirdrop();
    error Airdrop__AccessDenied_AdminOnly();

    // =========================
    //          Structs
    // =========================
    struct Airdrop {
        address recipient;
        uint256 deliveredAt;
    }

    // =========================
    //      Core Functions
    // =========================
    function airdrop() external;

    // =========================
    //      View Functions
    // =========================
    function getAirdropCount() external view returns (uint256);

    function getAirdrops() external view returns (Airdrop[] memory);

    function getAirdropLimit() external view returns (uint256);

    // =========================
    //   Admin Update Functions
    // =========================
    function updateAirdropCampaign(
        uint256 _newAirdropLimit,
        uint256 _newAirdropAmount
    ) external;
}
