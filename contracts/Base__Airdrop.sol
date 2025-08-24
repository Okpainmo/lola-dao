// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./interfaces/IAdminManagement__Base.sol";
import "./interfaces/ILolaUSD__Base.sol";
import "./interfaces/ILolaUSD__Core.sol";

contract Base__Airdrop {
    error Airdrop__AirdropCampaignEnded();
    // error Airdrop__AirdropFailed();
    error Airdrop__AirdropLimitCannotBeZero();
    error Airdrop__WalletAlreadyReceivedAirdrop();
    error Airdrop__AccessDenied_AdminOnly();
    error Airdrop__SpendApprovalFailedForAirdropContract();
    // error Airdrop__ZeroAddressError();

    event AirdropCampaignUpdated(
        uint256 timestamp,
        uint256 currentAirdropCount,
        uint256 initialAirdropLimit,
        uint256 initialAirdropAmount,
        uint256 newAirdropLimit,
        uint256 newAirdropAmount,
        string contractName,
        address updatedBy
    );

    event AirdropCampaignEnabled(
        uint256 timestamp,
        uint256 currentAirdropCount,
        uint256 currentAirdropLimit,
        uint256 currentAirdropAmount,
        string contractName,
        address indexed enabledBy
    );

    
    event AirdropCampaignDisabled(
        uint256 timestamp,
        uint256 currentAirdropCount,
        uint256 currentAirdropLimit,
        uint256 currentAirdropAmount,
        string contractName,
        address indexed enabledBy
    );

    event AirdropDelivered(Airdrop airdrop);

    bool private s_isAirdropCampaignActive = false; // airdop is disabled by default
    uint256 private s_airdropAmount; // 10 USDL
    uint256 private s_airdropLimit;
    mapping(address => bool) private s_hasReceivedAirdrop;

    address internal s_adminManagementCoreContractAddress;
    address internal s_lolaUSDCoreContractAddress;

    string private constant CONTRACT_NAME = "Base__Airdrop"; // set in one place to avoid mispelling elsewhere

    IAdminManagement__Base internal s_adminManagementCoreContract__Base =
        IAdminManagement__Base(s_adminManagementCoreContractAddress);

    // separate interfaces naming for clarity(during development), but same address since the core funtion inherits/contains and exposes everything
    ILolaUSD__Base internal s_lolaUSDContract__Base =
        ILolaUSD__Base(s_lolaUSDCoreContractAddress);
    ILolaUSD__Core internal s_lolaUSDContract__Core =
        ILolaUSD__Core(s_lolaUSDCoreContractAddress);

    struct Airdrop {
        address recipient;
        uint256 deliveredAt;
    }

    Airdrop[] private s_airdrops;

    function airdrop() public {
        if (s_hasReceivedAirdrop[msg.sender]) {
            revert Airdrop__WalletAlreadyReceivedAirdrop();
        }

        if (s_airdrops.length >= s_airdropLimit) {
            revert Airdrop__AirdropCampaignEnded();
        }

        // check allowance
        uint256 airdropContractAllowance = s_lolaUSDContract__Base.allowance(
            s_lolaUSDContract__Core.getContractOwner(),
            address(this)
        );

        if (s_airdropAmount > (airdropContractAllowance * 10 ** 18)) { // allowance as well as other number outputs are sent out in exact units not in eth arithmentic form
            revert Airdrop__AirdropCampaignEnded();
        }

        // re-entrancy guard – mark/set this early
        s_hasReceivedAirdrop[msg.sender] = true;

        // address tokenOwnerAddress = s_lolaUSDContract__Core.getContractOwner();

        // if (tokenOwnerAddress == address(0)) {
        //     revert Airdrop__ZeroAddressError();
        // }

        // bool success = s_lolaUSDContract__Base.transferFrom(tokenOwnerAddress, msg.sender, s_airdropAmount);

        //  if (!success) {
        //     revert("TransferFrom call failed");
        // }

        // ✅ Manual low-level call wrapper for ERC20 transferFrom
        (bool success, bytes memory returnData) = address(s_lolaUSDContract__Base)
        .call(
            abi.encodeWithSelector(
                s_lolaUSDContract__Base.transferFrom.selector,
                s_lolaUSDContract__Core.getContractOwner(),
                msg.sender,
                s_airdropAmount
            )
        );

        if (!success) {
            revert("TransferFrom call failed");
        }

        // Some ERC20s don’t return anything, some return bool
        if (returnData.length > 0) {
            // check returned value is true
            require(
                abi.decode(returnData, (bool)),
                "process failed"
            );
        }

        // Record the airdrop
        Airdrop memory newAirdrop = Airdrop({
            recipient: msg.sender,
            deliveredAt: block.timestamp
        });

        s_airdrops.push(newAirdrop);

        emit AirdropDelivered(newAirdrop);
    }

    function getAirdropCount() public view returns (uint256) {
        return s_airdrops.length;
    }

    function getAirdrops() public view returns (Airdrop[] memory) {
        return s_airdrops;
    }

    function getAirdropLimit() public view returns (uint256) {
        return s_airdropLimit;
    }

    function updateAirdropCampaign(
        uint256 _newAirdropLimit,
        uint256 _newAirdropAmount
    ) public {
        _newAirdropAmount =
            _newAirdropAmount *
            10 ** s_lolaUSDContract__Base.decimals();

        if (!s_adminManagementCoreContract__Base.checkIsAdmin(msg.sender)) {
            revert Airdrop__AccessDenied_AdminOnly();
        }

        if (_newAirdropLimit == 0) {
            revert Airdrop__AirdropLimitCannotBeZero();
        }

        uint256 initialLimit = s_airdropLimit;
        uint256 initialAmount = s_airdropAmount;

        s_airdropLimit = _newAirdropLimit;
        s_airdropAmount = _newAirdropAmount;

        /* to approve airdrop contract [adddress] to spend new airdrop allocation is not possible from here, 
        since we need the master admin's(airdrop contract owner's) address as msg.sender on the approve function. 
        It's not possible because msg.sender from here will be the same airdrop contract address. It will simply 
        be approving itself to spend for itself 
        
        Solution is to call both contracts separately but on the same end-point/process. 

        I.e: 
        
        1. after updating airdrop campaign in this(updateAirdropCampaign) function,
        2. proceed to ensure the caller is the master admin(token owner), then call approve on the token contract
        to have them approve the new airdrop spending that was just set here.

        all on the same end-point/process.
        */

        // bool success = s_lolaUSDContract__Base.approve( // not valid/useful if default airdrop amount is 0
        //     address(this),
        //     s_airdropLimit * s_airdropAmount
        // );

        // if (!success) {
        //     revert Airdrop__SpendApprovalFailedForAirdropContract();
        // }

        emit AirdropCampaignUpdated(
            block.timestamp,
            s_airdrops.length,
            initialLimit,
            initialAmount,
            _newAirdropLimit,
            _newAirdropAmount,
            CONTRACT_NAME,
            msg.sender
        );
    }

    function enableAirdrops () public {
        if (!s_adminManagementCoreContract__Base.checkIsAdmin(msg.sender)) {
            revert Airdrop__AccessDenied_AdminOnly();
        }

        s_isAirdropCampaignActive = true;

        emit AirdropCampaignEnabled (
            block.timestamp,
            s_airdrops.length,
            s_airdropLimit,
            s_airdropAmount,
            CONTRACT_NAME,
            msg.sender
        );
    }

     function disableAirdrops () public {
        if (!s_adminManagementCoreContract__Base.checkIsAdmin(msg.sender)) {
            revert Airdrop__AccessDenied_AdminOnly();
        }

        s_isAirdropCampaignActive = false;

        emit AirdropCampaignDisabled (
            block.timestamp,
            s_airdrops.length,
            s_airdropLimit,
            s_airdropAmount,
            CONTRACT_NAME,
            msg.sender
        );
    }
}
