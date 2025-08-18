// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILolaUSD {
    // Events
    event Transfer(
        address indexed _owner,
        address indexed _receiver,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _operator,
        uint256 _value
    );

    // Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(
        address _owner,
        address _operator
    ) external view returns (uint256);

    // Mutative functions
    function approve(address _operator, uint256 _value) external returns (bool);

    function increaseAllowance(
        address _operator,
        uint256 _addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address _operator,
        uint256 _subtractedValue
    ) external returns (bool);

    function transfer(
        address _receiver,
        uint256 _value
    ) external returns (bool);

    function transferFrom(
        address _owner,
        address _receiver,
        uint256 _value
    ) external returns (bool);

    // Supply modification
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}
