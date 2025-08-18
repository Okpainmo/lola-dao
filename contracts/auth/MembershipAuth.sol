// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MembershipAuth {
    error MembershipAuth__NotDAOMember();

    mapping(address => bool) internal isDAOMember;

    modifier onlyDAOMember(address _address) {
        if(!isDAOMember[_address]) {
            revert MembershipAuth__NotDAOMember();
        }

        _;
    }
}