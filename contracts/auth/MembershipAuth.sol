// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MembershipAuth {
    error MembershipAuth__NotDAOMember();

    mapping(address => bool) internal s_isDAOMember;

    modifier onlyDAOMember(address _address) {
        if(!s_isDAOMember[_address]) {
            revert MembershipAuth__NotDAOMember();
        }

        _;
    }
}