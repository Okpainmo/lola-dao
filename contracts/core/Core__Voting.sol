// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../Voting.sol";

contract Core__Voting is Voting {
    error ProposalAndVotingCore__ZeroAddressError();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    // i_owner(variable) - from => Voting.sol -> ProposalManagement.sol -> OnlyOwnerAuth.sol

    string private constant CONTRACT_NAME = "Core__Voting"; // set in one place to avoid mispelling elsewhere

    constructor(address _lolaUSDCoreContractAddress) {
        if(_lolaUSDCoreContractAddress == address(0)) {
            revert ProposalAndVotingCore__ZeroAddressError();
        }

        i_owner = msg.sender;
        s_lolaUSDCoreContractAddress = _lolaUSDCoreContractAddress; // needed for checking users' balance to ensure requirements are met for voting, and likely more

         emit Logs(
            "contract deployed successfully with constructor chores completed",
            block.timestamp,
            CONTRACT_NAME
        );
    }
    

    function getContractName() public pure returns (string memory) {
        return CONTRACT_NAME;
    }

    function getContractOwner() public view returns (address) {
        return i_owner;
    }

    function updateLolaUSDCoreContractAddress(address _newAddress) public {
         if(_newAddress == address(0)) {
            revert ProposalAndVotingCore__ZeroAddressError();
        }

        s_lolaUSDCoreContractAddress = _newAddress;
    }

    function updateMinimumVotingBalanceRequirement(uint256 _value) public {
        // s_minimumVotingBalanceRequirement - from Membership.sol
        s_minimumVotingBalanceRequirement = _value * 10 ** 18;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}