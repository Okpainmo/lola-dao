// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../Base__ProposalManagement.sol";
import "../interfaces/IAdminManagement__Core.sol";

contract Core__Proposals is Base__ProposalManagement {
    error ProposalsCore__ZeroAddressError();
    error ProposalsCore__AccessDenied_AdminOnly();
    error ProposalsCore__NonMatchingAdminAddress();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    function _verifyIsAddress(address _address) internal override pure {
        if (_address == address(0)) {
            revert ProposalsCore__ZeroAddressError();
        }
    }

    function _verifyIsAdmin(address _address) internal view override  {
         if (!s_adminManagementContract__Base.checkIsAdmin(_address)) {
            revert ProposalsCore__AccessDenied_AdminOnly();
        }
    }

    string private constant CONTRACT_NAME = "Core__Proposals"; // set in one place to avoid mispelling elsewhere

    constructor(
        address _adminManagementCoreContractAddress
        // address _votingCoreContractAddress, 
        // address _membershipCoreContractAddress
    ) {
        _verifyIsAddress(_adminManagementCoreContractAddress);
        // _verifyIsAddress(_votingCoreContractAddress);
        // _verifyIsAddress(_membershipCoreContractAddress);

        // i_owner(variable) - from ProposalManagement.sol -> OnlyOwnerAuth.sol
        i_owner = msg.sender;
        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
        // s_votingCoreContractAddress = _votingCoreContractAddress;
        // s_membershipCoreContractAddress = _membershipCoreContractAddress;

        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
        // s_votingContract__base = IVoting__Base(s_votingCoreContractAddress);
        // s_membershipContract__Base = IMembership__Base(s_membershipCoreContractAddress);


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


    function updateAdminManagementCoreContractAddress(
        address _newAddress
    ) public {        
        _verifyIsAddress(_newAddress);

        _verifyIsAdmin(msg.sender);

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
            revert ProposalsCore__NonMatchingAdminAddress();
        }

        /* also ensure current sender is an admin on that contract - which further verifies that the contract 
        is indeed and 'adminManagement' contract */
        _verifyIsAdmin(msg.sender);

        s_adminManagementCoreContractAddress = _newAddress;
        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
    }

    function updateVotingCoreContractAddress(address _newAddress) public {
        _verifyIsAddress(_newAddress);

        _verifyIsAdmin(msg.sender);

        s_votingCoreContractAddress = _newAddress;
        s_votingContract__base = IVoting__Base(_newAddress);
    }

    function updateMembershipCoreContractAddress(address _newAddress) public {
        _verifyIsAddress(_newAddress);

        _verifyIsAdmin(msg.sender);

        s_membershipCoreContractAddress = _newAddress;
        s_membershipContract__Base = IMembership__Base(_newAddress);
    }

        function getAdminManagementCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_adminManagementCoreContractAddress;
    }

    function getVotingCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_votingCoreContractAddress;
    }

    function getMembershipCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_membershipCoreContractAddress;
    }


    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}