// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../Base__Airdrop.sol";
import "../interfaces/IAdminManagement__Core.sol";

contract Core__Airdrop is Base__Airdrop {
    error AirdropCore__ZeroAddressError();
    error AirdropCore__AccessDenied_AdminOnly();
    error AirdropCore__NonMatchingAdminAddress();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    string private constant CONTRACT_NAME = "Core__Airdrop"; // set in one place to avoid mispelling elsewhere
    address private immutable i_owner;

    function _verifyIsAddress(address _address) private pure {
        if (_address == address(0)) {
            revert AirdropCore__ZeroAddressError();
        }
    } 

    constructor(
        address _adminManagementCoreContractAddress
        // address _lolaUSDCoreContractAddress
    )
    {
        _verifyIsAddress(_adminManagementCoreContractAddress);
        // _verifyIsAddress(_lolaUSDCoreContractAddress);

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress;
        // s_lolaUSDCoreContractAddress = _lolaUSDCoreContractAddress;

        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
        // s_lolaUSDContract__Base = ILolaUSD__Base(_lolaUSDCoreContractAddress);
        // s_lolaUSDContract__Core = ILolaUSD__Core(_lolaUSDCoreContractAddress);

        i_owner = msg.sender;

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
        _verifyIsAddress(_newAddress);

        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert AirdropCore__AccessDenied_AdminOnly();
        }

        s_lolaUSDCoreContractAddress = _newAddress;

        s_lolaUSDContract__Base = ILolaUSD__Base(_newAddress);
        s_lolaUSDContract__Core = ILolaUSD__Core(_newAddress);
    }

    function updateAdminManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert AirdropCore__AccessDenied_AdminOnly();
        }
        
        if (_newAddress == address(0)) {
            revert AirdropCore__ZeroAddressError();
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
            revert AirdropCore__NonMatchingAdminAddress();
        }

        /* also ensure current sender is an admin on that contract - which further verifies that the contract 
        is indeed and 'adminManagement' contract */
        if (!s_adminManagementContractToVerify.checkIsAdmin(msg.sender)) {
            revert AirdropCore__AccessDenied_AdminOnly();
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

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}
