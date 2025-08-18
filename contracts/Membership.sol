// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./auth/MembershipAuth.sol";
// import "./auth/AdminAuth.sol";
import "./interfaces/Interface__LolaUSD.sol";
import "./interfaces/Interface__AdminManagement.sol";


contract Membership is MembershipAuth  {
    error Membership__ZeroAddressError();
    error Membership__NotDAOMember();
    error Membership__InsufficientVotingBalance();
    error Membership__AdminAndProposalAuthorOnly();

    event DAOMembersManagement(string message, address memberAddress, uint256 addedAt);

    struct DAOMember {
        address memberAddress;
        uint256 addedAt;
    }

    DAOMember[] internal governanceDAOMembers;
    mapping(address => DAOMember) internal DAOMemberAddressToProfile;

    uint256 internal s_minimumMembershipBalanceRequirement = 10 * 10 ** 18; // 10 USDL

    address internal s_adminManagementCoreContractAddress;
    address internal s_lolaUSDCoreContractAddress;

    ILolaUSD internal lolaUSDContract = ILolaUSD(s_lolaUSDCoreContractAddress);
    IAdminManagement internal adminMangementContract = IAdminManagement(s_adminManagementCoreContractAddress);


    function _verifyIsAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert Membership__ZeroAddressError();
        }
    }
    
    function addDAOMember(address _memberAddress) external {
        if(lolaUSDContract.balanceOf(msg.sender) < s_minimumMembershipBalanceRequirement) {
            revert Membership__InsufficientVotingBalance();
        }

        _verifyIsAddress(_memberAddress);

        DAOMember memory newMember = DAOMember(_memberAddress, block.timestamp);

        // todo: check if member has up to minimum token hold balance - call the USDL token contract to check

        governanceDAOMembers.push(newMember);

        // isDAOMember - from MembershipAuth.sol
        isDAOMember[_memberAddress] = true;

        DAOMemberAddressToProfile[_memberAddress] = newMember;

        // DAOMemberAddressToProfile[_memberAddress] = DAOMember(_memberAddress, block.timestamp);

        emit DAOMembersManagement("DAO member added successfully", _memberAddress, block.timestamp);
    }

    function removeDAOMember(address _memberAddress) external { // must reference the externally deployed admin management contract not directly
        _verifyIsAddress(_memberAddress);

        // isDAOMember - from MembershipAuth.sol
        if(isDAOMember[_memberAddress] != true) {
            revert Membership__NotDAOMember();
        }

        // Remove from DAO members list
        for (uint256 i = 0; i < governanceDAOMembers.length; i++) {
            if (governanceDAOMembers[i].memberAddress == _memberAddress) {
                governanceDAOMembers[i] = governanceDAOMembers[governanceDAOMembers.length - 1];
                governanceDAOMembers.pop();

                break;
            }
        }

        // isDAOMember - from MembershipAuth.sol
        isDAOMember[_memberAddress] = false;

        // reset the profile data to solidity defaults
        delete DAOMemberAddressToProfile[_memberAddress];

        emit DAOMembersManagement("DAO member removed successfully", _memberAddress, block.timestamp);
    }

    function updateDAOMemberProfile(address _memberAddress, address _newAddress) external {
        if (_memberAddress == address(0)) {
            revert Membership__ZeroAddressError();
        }

        // isDAOMember - from MembershipAuth.sol
        if (isDAOMember[_memberAddress] != true) {
            revert Membership__NotDAOMember();
        }

        DAOMember memory profile =  DAOMemberAddressToProfile[_memberAddress];

        // s_isAdmin - from AdminAuth.sol 
        if(profile.memberAddress != msg.sender && !adminMangementContract.checkIsAdmin(msg.sender)) {
            revert Membership__AdminAndProposalAuthorOnly();
        }

        profile.memberAddress = _newAddress;

        // todo: copy all member proposals and votes, and attach to the new address

        // Update mapping
        DAOMemberAddressToProfile[_memberAddress] = profile;

        // Update array for consistency
        for (uint256 i = 0; i < governanceDAOMembers.length; i++) {
            if (governanceDAOMembers[i].memberAddress == _memberAddress) {
                governanceDAOMembers[i] = profile;

                break;
            }
        }

        emit DAOMembersManagement("DAO member profile updated successfully", _newAddress, block.timestamp);
    }

    function checkIsDAOMember(address _memberAddress) public view returns(bool) {
        _verifyIsAddress(_memberAddress);

        // isDAOMember - from MembershipAuth.sol
        return isDAOMember[_memberAddress];
    }

    function getDAOMemberProfile(address _memberAddress) public view returns(DAOMember memory) {
        _verifyIsAddress(_memberAddress);

        // isDAOMember - from MembershipAuth.sol
        if(!isDAOMember[_memberAddress]) {
            revert Membership__NotDAOMember();
        }

        DAOMember memory member  = DAOMemberAddressToProfile[_memberAddress];

        return member;
    }

    function getDAOMembers() public view returns(DAOMember[] memory) {
        return governanceDAOMembers;
    }
}