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
    ) {
        _verifyIsAddress(_adminManagementCoreContractAddress);

        // i_owner(variable) - from ProposalManagement.sol
        i_owner = msg.sender;
        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more

        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);

         emit Logs(
            "contract deployed successfully with constructor chores completed",
            block.timestamp,
            CONTRACT_NAME
        );
    }

    function updateRelatedCoreContractAddresses(address _new__AdminManagement, address _new__Membership, address _new__Voting, address _new__LolaUSDCoreContractAddress) public {
        _verifyIsAddress(_new__AdminManagement);
        _verifyIsAddress(_new__Membership);
        _verifyIsAddress(_new__Voting);
        _verifyIsAddress(_new__LolaUSDCoreContractAddress);

        _verifyIsAdmin(msg.sender);

        s_votingCoreContractAddress = _new__Voting;
        s_votingContract__base = IVoting__Base(_new__Voting);

        s_membershipCoreContractAddress = _new__Membership;
        s_membershipContract__Base = IMembership__Base(_new__Membership);

        s_lolaUSDCoreContractAddress = _new__LolaUSDCoreContractAddress;
        s_lolaUSDContract__Core =  ILolaUSD__Core(s_lolaUSDCoreContractAddress);

        // first connect and ping
        IAdminManagement__Core s_adminManagementContractToVerify = IAdminManagement__Core(_new__AdminManagement);
        ( , address contractAddress, ) = s_adminManagementContractToVerify.ping();

        // the fact that it pings without an error is enough - but still do as below to be super-sure
        if(contractAddress != _new__AdminManagement) { 
            revert ProposalsCore__NonMatchingAdminAddress();
        }

        /* also ensure current sender is an admin on that contract - which further verifies that the contract 
        is indeed and 'adminManagement' contract */
        _verifyIsAdmin(msg.sender);

        s_adminManagementCoreContractAddress = _new__AdminManagement;
        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
    }

    function getRelatedCoreContractAddresses()
        public
        view
        returns (address adminManagement, address Voting, address Membership, address lolaUSDToken)
    {
        return (s_adminManagementCoreContractAddress, s_votingCoreContractAddress, s_membershipCoreContractAddress, s_lolaUSDCoreContractAddress);
    }

    function ping() external view returns (string memory contractName, address contractAddress, address contractOwner) {
        return (CONTRACT_NAME, address(this), i_owner);
    }
}