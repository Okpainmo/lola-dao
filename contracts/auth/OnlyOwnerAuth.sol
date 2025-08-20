// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OnlyOwnerAuth {
    error OnlyOwnerAuth__OwnerOnly();

    address internal immutable i_owner;

    modifier onlyOwner(address _address) {
        if(_address != i_owner) {
            revert OnlyOwnerAuth__OwnerOnly();
        }

        _;
    }
}