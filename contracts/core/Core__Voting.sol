// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../Base__Voting.sol";
import "../interfaces/IAdminManagement__Core.sol";

contract Core__Voting is Base__Voting {
    error VotingCore__ZeroAddressError();
    error VotingCore__AccessDenied_AdminOnly();
    error VotingCore__NonMatchingAdminAddress();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    // i_owner(variable) - from => Voting.sol -> ProposalManagement.sol -> OnlyOwnerAuth.sol
    string private constant CONTRACT_NAME = "Core__Voting"; // set in one place to avoid mispelling elsewhere

    constructor(
        address _adminManagementCoreContractAddress,
        address _lolaUSDCoreContractAddress
        // address _proposalManagementCoreContractAddress, 
    ) {
        if(
            _adminManagementCoreContractAddress == address(0)
            // || _proposalManagementCoreContractAddress == address(0) 
            || _lolaUSDCoreContractAddress == address(0) 
            ) {
            revert VotingCore__ZeroAddressError();
        }

        i_owner = msg.sender;
        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress;
        s_lolaUSDCoreContractAddress = _lolaUSDCoreContractAddress; // needed for checking users' balance to ensure requirements are met for voting, and likely more
        // s_proposalManagementCoreContractAddress = _proposalManagementCoreContractAddress; // needed for interactions with the external core proposal management contract

        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
        s_lolaUSDContract__Base = ILolaUSD__Base(s_lolaUSDCoreContractAddress);
        // s_proposalManagementContract__Base = IProposalManagement__Base(_proposalManagementCoreContractAddress);

        s_minimumVotingBalanceRequirement = 10 * 10 ** s_lolaUSDContract__Base.decimals();

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
            revert VotingCore__ZeroAddressError();
        }

        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert VotingCore__AccessDenied_AdminOnly();
        }

        s_lolaUSDCoreContractAddress = _newAddress;
        s_lolaUSDContract__Base = ILolaUSD__Base(_newAddress);
    }

    function updateMembershipCoreContractAddress(address _newAddress) public {
        if(_newAddress == address(0)) {
            revert VotingCore__ZeroAddressError();
        }

        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert VotingCore__AccessDenied_AdminOnly();
        }

        s_membershipContractAddress = _newAddress;
        s_membershipContract__Base = IMembership__Base(s_membershipContractAddress);
    }

     function updateProposalManagementCoreContractAddress(address _newAddress) public {
        if(_newAddress == address(0)) {
            revert VotingCore__ZeroAddressError();
        }

        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert VotingCore__AccessDenied_AdminOnly();
        }

        s_proposalManagementCoreContractAddress = _newAddress;
        s_proposalManagementContract__Base = IProposalManagement__Base(_newAddress);
    }

    function updateAdminManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert VotingCore__AccessDenied_AdminOnly();
        }
        
        if (_newAddress == address(0)) {
            revert VotingCore__ZeroAddressError();
        }

        /* 
        updating the admin management core contract address is a very sensitive process. The old/current contract 
        to switch from can be active and working, but if the 'isAdmin' check is passed(on the old/current contract), 
        and a new address is set which is wrong, it becomes impossible to now connect to the intending admin 
        contract. Hence the next step of admin check below, will keep failing and impossible to pass due to contract 
        immutability. Other chores requiring admin check will also be impossible.
    
        Hence the need to first connect and ping to make sure the new contract works before setting
        */
        // first connect and ping
        IAdminManagement__Core s_adminManagementContractToVerify = IAdminManagement__Core(_newAddress);
        ( , address contractAddress, ) = s_adminManagementContractToVerify.ping();

        // the fact that it pings without an error is enough - but still do as below to be super-sure
        if(contractAddress != _newAddress) { 
            revert VotingCore__NonMatchingAdminAddress();
        }

        /* also ensure current sender is an admin on that contract - which further verifies that the contract 
        is indeed and 'adminManagement' contract */
        if (!s_adminManagementContractToVerify.checkIsAdmin(msg.sender)) {
            revert VotingCore__AccessDenied_AdminOnly();
        }

        s_adminManagementCoreContractAddress = _newAddress;
        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
    }

    function getAdminManagementCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_adminManagementCoreContractAddress;
    }

    function getLolaUSDCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_lolaUSDCoreContractAddress;
    }

    function getProposalManagementCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_proposalManagementCoreContractAddress;
    }

    function getMembershipCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_membershipContractAddress;
    }


    function updateMinimumVotingBalanceRequirement(uint256 _value) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert VotingCore__AccessDenied_AdminOnly();
        }

        // s_minimumVotingBalanceRequirement - from Membership.sol
        s_minimumVotingBalanceRequirement = _value * 10 ** 18;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}