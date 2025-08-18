// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../Membership.sol";

contract Core__Membership is Membership {
    error MembershipCore__ZeroAddressError();
    
    event Logs(string message, uint256 timestamp, string indexed contractName);

    address private i_owner;

    string private constant CONTRACT_NAME = "Core__Membership"; // set in one place to avoid mispelling elsewhere

    function makeMember() private {
        // Admin(struct) - from AdminManagement.sol
         _verifyIsAddress(msg.sender);

        DAOMember memory newMember = DAOMember(msg.sender, block.timestamp);

        // todo: check if member has up to minimum token hold balance - call the USDL token contract to check

        governanceDAOMembers.push(newMember);

        // isDAOMember - from MembershipAuth.sol
        isDAOMember[msg.sender] = true;

        DAOMemberAddressToProfile[msg.sender] = newMember;

        // DAOMemberAddressToProfile[msg.sender] = DAOMember(msg.sender, block.timestamp);

        emit DAOMembersManagement("DAO member added successfully", msg.sender, block.timestamp);
    }

    constructor(address _adminManagementCoreContractAddress, address _lolaUSDCoreContractAddress) {
        if(_adminManagementCoreContractAddress == address(0) || _lolaUSDCoreContractAddress == address(0)) {
            revert MembershipCore__ZeroAddressError();
        }

        i_owner = msg.sender;
        makeMember();

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
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

      function updateAdminManagementCoreContractAddress(address _newAddress) public {
        if(_newAddress == address(0)) {
            revert MembershipCore__ZeroAddressError();
        }

        s_adminManagementCoreContractAddress = _newAddress;
    }

    function updateLolaUSDCoreContractAddress(address _newAddress) public {
        if(_newAddress == address(0)) {
            revert MembershipCore__ZeroAddressError();
        }

        s_lolaUSDCoreContractAddress = _newAddress;
    }

    function updateMinimumMembershipBalanceRequirement(uint256 _value) public {
        // s_minimumMembershipBalanceRequirement - from Membership.sol
        s_minimumMembershipBalanceRequirement = _value * 10 ** 18;
    }


    function ping() external view returns(string memory, address, uint256) {
        return(CONTRACT_NAME, address(this), block.timestamp);
    }
}