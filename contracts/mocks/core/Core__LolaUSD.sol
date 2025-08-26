// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Base__LolaUSD.sol";
import "../../interfaces/IAdminManagement__Core.sol";

contract Core__LolaUSD is Base__LolaUSD {
    error LolaUSDCore__ZeroAddressError();
    error LolaUSDCore__AccessDenied_AdminOnly();
    error LolaUSDCore__LogoNameCannotBeEmpty();
    error LolaUSDCore__SpendApprovalFailedForAirdropContract();
    error LolaUSDCore__NonMatchingAdminAddress();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    string private constant CONTRACT_NAME = "Core__LolaUSD"; // set in one place to avoid mispelling elsewhere
    address private i_owner;
    string private s_tokenImageCID;
    string private s_tokenMetadataCID;
    // address internal s_airdropCoreContractAddress; // only needed for transferFrom approval - no contract initialization

    // IBase__Airdrop internal airdropContract__Base = IBase__Airdrop(s_airdropCoreContractAddress);
    uint256 internal s_airdropLimit;
    uint256 internal s_airdropAmount;

    constructor(
        string memory _tokenName,
        string memory _tokenLogoCID,
        string memory _tokenMetadataCID,
        string memory _tokenSymbol,
        uint8 _decimals,
        uint256 _supply,
        address _adminManagementCoreContractAddress,
        address _proposalManagementCoreContractAddress
    ) {
        s_tokenName = _tokenName;
        s_tokenSymbol = _tokenSymbol;
        s_tokenDecimals = _decimals;
        i_owner = msg.sender;
        s_supply = _supply * 10 ** s_tokenDecimals;

        s_tokenMetadataCID = _tokenMetadataCID;
        s_tokenImageCID = _tokenLogoCID;

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
        s_proposalManagementCoreContractAddress = _proposalManagementCoreContractAddress;

        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
        s_proposalManagementContract__Base = IProposalManagement__Base(s_proposalManagementCoreContractAddress);

        balance[msg.sender] = s_supply; 
        emit Transfer(address(0), msg.sender, s_supply);

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

    function getAdminManagementCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_adminManagementCoreContractAddress;
    }

    function getProposalManagementCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_proposalManagementCoreContractAddress;
    }

    // function getAirdropCoreContractAddress()
    //     public
    //     view
    //     returns (address)
    // {
    //     return s_airdropCoreContractAddress;
    // }

    function updateAdminManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }
        
        if (_newAddress == address(0)) {
            revert LolaUSDCore__ZeroAddressError();
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
        IAdminManagement__Core s_adminManagementContract__BaseToVerify = IAdminManagement__Core(_newAddress);
        ( , address contractAddress, ) = s_adminManagementContract__BaseToVerify.ping();

        // the fact that it pings without an error is enough - but still do as below to be super-sure
        if(contractAddress != _newAddress) { 
            revert LolaUSDCore__NonMatchingAdminAddress();
        }

        /* also ensure current sender is an admin on that contract - which further verifies that the contract 
        is indeed and 'adminManagement' contract */
        if (!s_adminManagementContract__BaseToVerify.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        s_adminManagementCoreContractAddress = _newAddress;
        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
    }
    
    // // not needed
    // function updateAirdropCoreContractAddress( 
    //     address _newAddress
    // ) public {
    //     if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
    //         revert LolaUSDCore__AccessDenied_AdminOnly();
    //     }

    //     if (_newAddress == address(0)) {
    //         revert LolaUSDCore__ZeroAddressError();
    //     }

    //     s_airdropCoreContractAddress = _newAddress;
    // }

    function updateProposalManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (_newAddress == address(0)) {
            revert LolaUSDCore__ZeroAddressError();
        }

        s_proposalManagementCoreContractAddress = _newAddress;
        s_proposalManagementContract__Base = IProposalManagement__Base(s_proposalManagementCoreContractAddress);
    }

    function getTokenLogo() public view returns (string memory) {
        return s_tokenImageCID;
    }

    function getTokenMetadata() public view returns (string memory) {
        return s_tokenMetadataCID;
    }

    function updateTokenLogo(string memory _newLogoCID) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (bytes(_newLogoCID).length < 1)
            revert LolaUSDCore__LogoNameCannotBeEmpty();

        s_tokenImageCID = _newLogoCID;
    }

    function updateTokenMetaData(string memory _newMetaDataCID) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (bytes(_newMetaDataCID).length < 1)
            revert LolaUSDCore__LogoNameCannotBeEmpty();

        s_tokenMetadataCID = _newMetaDataCID;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}


