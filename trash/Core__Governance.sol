// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// import "../Voting.sol";
// import "../Membership.sol";

// contract Governance is Voting, Membership {

//     constructor() {


//     }

//     function updateMinimumMembershipBalanceRequirement(uint256 _amount) public {
//         // s_minimumMembershipBalanceRequirement - from Membership.sol
//         s_minimumMembershipBalanceRequirement = _amount * 10 ** 18; // 100 USDL
//     }

//     function updateMinimumVotingBalanceRequirement(uint256 _amount) public {
//         // s_minimumVotingBalanceRequirement - from Voting.sol
//         s_minimumMembershipBalanceRequirement = _amount * 10 ** 18; // 100 USDL
//     }
// }