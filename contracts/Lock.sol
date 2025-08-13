// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @title Lock
 * @author @Okpainmo(Github)
 * @notice This contract locks Ether until a specified unlock time, allowing withdrawal only after the time has passed.
 * @dev The contract sets the owner at deployment and enforces time-based withdrawal conditions.
 */
contract Lock {
    /// @notice The timestamp after which funds can be withdrawn.
    uint public unlockTime;

    /// @notice The address that owns the locked funds.
    address payable public owner;

    /**
     * @notice Emitted when a withdrawal occurs.
     * @param amount The amount of Ether withdrawn.
     * @param when The timestamp when the withdrawal occurred.
     */
    event Withdrawal(uint amount, uint when);

    /**
     * @notice Deploys the contract, setting the unlock time and owner.
     * @dev Requires the unlock time to be in the future.
     * @param _unlockTime The timestamp after which withdrawals are allowed.
     */
    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    /**
     * @notice Withdraws all funds from the contract if the unlock time has passed and caller is the owner.
     * @dev Emits a {Withdrawal} event and transfers the full balance to the owner.
     */
    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}
