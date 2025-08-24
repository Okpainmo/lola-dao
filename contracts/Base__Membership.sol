// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./auth/MembershipAuth.sol";
// import "./auth/AdminAuth.sol";
import "./interfaces/ILolaUSD__Base.sol";
import "./interfaces/IAdminManagement__Base.sol";


contract Base__Membership is MembershipAuth  {
    error Membership__ZeroAddressError();
    error Membership__NotDAOMember();
    error Membership__InsufficientVotingBalance();
    error Membership__AdminAndProposalAuthorOnly();

    event DAOMembersManagement(string message, address memberAddress, uint256 addedAt);

    struct DAOMember {
        address memberAddress;
        uint256 addedAt;
    }

    DAOMember[] internal s_governanceDAOMembers;
    mapping(address => DAOMember) internal s_DAOMemberAddressToProfile;

    uint256 internal s_minimumMembershipBalanceRequirement = 10 * 10 ** 18; // 10 USDL

    address internal s_adminManagementCoreContractAddress;
    address internal s_lolaUSDCoreContractAddress;

    ILolaUSD__Base internal s_lolaUSDContract__Base = ILolaUSD__Base(s_lolaUSDCoreContractAddress);
    IAdminManagement__Base internal s_adminManagementCoreContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);


    function _verifyIsAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert Membership__ZeroAddressError();
        }
    }
    
    function addDAOMember(address _memberAddress) external {
        if(s_lolaUSDContract__Base.balanceOf(msg.sender) < s_minimumMembershipBalanceRequirement) {
            revert Membership__InsufficientVotingBalance();
        }

        _verifyIsAddress(_memberAddress);

        DAOMember memory newMember = DAOMember(_memberAddress, block.timestamp);

        // todo: check if member has up to minimum token hold balance - call the USDL token contract to check

        s_governanceDAOMembers.push(newMember);

        // s_isDAOMember - from MembershipAuth.sol
        s_isDAOMember[_memberAddress] = true;

        s_DAOMemberAddressToProfile[_memberAddress] = newMember;

        // s_DAOMemberAddressToProfile[_memberAddress] = DAOMember(_memberAddress, block.timestamp);

        emit DAOMembersManagement("DAO member added successfully", _memberAddress, block.timestamp);
    }

    function removeDAOMember(address _memberAddress) external { // must reference the externally deployed admin management contract not directly
        _verifyIsAddress(_memberAddress);

        // s_isDAOMember - from MembershipAuth.sol
        if(s_isDAOMember[_memberAddress] != true) {
            revert Membership__NotDAOMember();
        }

        // Remove from DAO members list
        for (uint256 i = 0; i < s_governanceDAOMembers.length; i++) {
            if (s_governanceDAOMembers[i].memberAddress == _memberAddress) {
                s_governanceDAOMembers[i] = s_governanceDAOMembers[s_governanceDAOMembers.length - 1];
                s_governanceDAOMembers.pop();

                break;
            }
        }

        // s_isDAOMember - from MembershipAuth.sol
        s_isDAOMember[_memberAddress] = false;

        // reset the profile data to solidity defaults
        delete s_DAOMemberAddressToProfile[_memberAddress];

        emit DAOMembersManagement("DAO member removed successfully", _memberAddress, block.timestamp);
    }

    function updateDAOMemberProfile(address _memberAddress, address _newAddress) external {
        if (_memberAddress == address(0)) {
            revert Membership__ZeroAddressError();
        }

        // s_isDAOMember - from MembershipAuth.sol
        if (s_isDAOMember[_memberAddress] != true) {
            revert Membership__NotDAOMember();
        }

        DAOMember memory profile =  s_DAOMemberAddressToProfile[_memberAddress];

        // s_isAdmin - from AdminAuth.sol 
        if(profile.memberAddress != msg.sender && !s_adminManagementCoreContract__Base.checkIsAdmin(msg.sender)) {
            revert Membership__AdminAndProposalAuthorOnly();
        }

        profile.memberAddress = _newAddress;

        // todo: copy all member proposals and votes, and attach to the new address

        // Update mapping
        s_DAOMemberAddressToProfile[_memberAddress] = profile;

        // Update array for consistency
        for (uint256 i = 0; i < s_governanceDAOMembers.length; i++) {
            if (s_governanceDAOMembers[i].memberAddress == _memberAddress) {
                s_governanceDAOMembers[i] = profile;

                break;
            }
        }

        emit DAOMembersManagement("DAO member profile updated successfully", _newAddress, block.timestamp);
    }

    function checks_IsDAOMember(address _memberAddress) public view returns(bool) {
        _verifyIsAddress(_memberAddress);

        // s_isDAOMember - from MembershipAuth.sol
        return s_isDAOMember[_memberAddress];
    }

    function getDAOMemberProfile(address _memberAddress) public view returns(DAOMember memory) {
        _verifyIsAddress(_memberAddress);

        // s_isDAOMember - from MembershipAuth.sol
        if(!s_isDAOMember[_memberAddress]) {
            revert Membership__NotDAOMember();
        }

        DAOMember memory member  = s_DAOMemberAddressToProfile[_memberAddress];

        return member;
    }

    function getDAOMembers() public view returns(DAOMember[] memory) {
        return s_governanceDAOMembers;
    }
}