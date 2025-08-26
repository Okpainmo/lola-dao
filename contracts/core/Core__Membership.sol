// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../Base__Membership.sol";
import "../interfaces/IAdminManagement__Core.sol";

contract Core__Membership is Base__Membership {
    error MembershipCore__ZeroAddressError();
    error MembershipCore__AccessDenied_AdminOnly();
    error MembershipCore__NonMatchingAdminAddress(); 
    
    event Logs(string message, uint256 timestamp, string indexed contractName);

    address private i_owner;

    string private constant CONTRACT_NAME = "Core__Membership"; // set in one place to avoid mispelling elsewhere

    function makeAdminMember() private {
        // Admin(struct) - from AdminManagement.sol
         _verifyIsAddress(msg.sender);

        DAOMember memory newMember = DAOMember(msg.sender, block.timestamp);

        // todo: check if member has up to minimum token hold balance - call the USDL token contract to check

        s_governanceDAOMembers.push(newMember);

        // s_isDAOMember - from MembershipAuth.sol
        s_isDAOMember[msg.sender] = true;

        s_DAOMemberAddressToProfile[msg.sender] = newMember;

        // s_DAOMemberAddressToProfile[msg.sender] = DAOMember(msg.sender, block.timestamp);

        emit DAOMembersManagement("DAO member added successfully", msg.sender, block.timestamp);
    }

    constructor(
        address _adminManagementCoreContractAddress,
        address _lolaUSDCoreContractAddress
    ) {
        if(
            _adminManagementCoreContractAddress == address(0) 
            || _lolaUSDCoreContractAddress == address(0)
        ) {
            revert MembershipCore__ZeroAddressError();
        }

        i_owner = msg.sender;
        makeAdminMember();

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
        s_lolaUSDCoreContractAddress = _lolaUSDCoreContractAddress; // needed for checking users' balance to ensure requirements are met for voting, and likely more

        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
        s_lolaUSDContract__Base = ILolaUSD__Base(_lolaUSDCoreContractAddress);

        s_minimumMembershipBalanceRequirement = 10 * 10 ** s_lolaUSDContract__Base.decimals();
        
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
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert MembershipCore__AccessDenied_AdminOnly();
        }
        
        if (_newAddress == address(0)) {
            revert MembershipCore__ZeroAddressError();
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
            revert MembershipCore__NonMatchingAdminAddress();
        }

        /* also ensure current sender is an admin on that contract - which further verifies that the contract 
        is indeed and 'adminManagement' contract */
        if (!s_adminManagementContractToVerify.checkIsAdmin(msg.sender)) {
            revert MembershipCore__AccessDenied_AdminOnly();
        }

        s_adminManagementCoreContractAddress = _newAddress;
        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
    }

    function updateLolaUSDCoreContractAddress(address _newAddress) public {
        if(_newAddress == address(0)) {
            revert MembershipCore__ZeroAddressError();
        }

        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert MembershipCore__AccessDenied_AdminOnly();
        }

        s_lolaUSDCoreContractAddress = _newAddress;
        
        s_lolaUSDContract__Base = ILolaUSD__Base(_newAddress);
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

    function updateMinimumMembershipBalanceRequirement(uint256 _value) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert MembershipCore__AccessDenied_AdminOnly();
        }
        // s_minimumMembershipBalanceRequirement - from Membership.sol
        s_minimumMembershipBalanceRequirement = _value * 10 ** 18;
    }


    function ping() external view returns(string memory, address, uint256) {
        return(CONTRACT_NAME, address(this), block.timestamp);
    }
}