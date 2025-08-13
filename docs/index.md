# Solidity API

## Lock

This contract locks Ether until a specified unlock time, allowing withdrawal only after the time has passed.

_The contract sets the owner at deployment and enforces time-based withdrawal conditions._

### unlockTime

```solidity
uint256 unlockTime
```

The timestamp after which funds can be withdrawn.

### owner

```solidity
address payable owner
```

The address that owns the locked funds.

### Withdrawal

```solidity
event Withdrawal(uint256 amount, uint256 when)
```

Emitted when a withdrawal occurs.

#### Parameters

| Name   | Type    | Description                                 |
| ------ | ------- | ------------------------------------------- |
| amount | uint256 | The amount of Ether withdrawn.              |
| when   | uint256 | The timestamp when the withdrawal occurred. |

### constructor

```solidity
constructor(uint256 _unlockTime) public payable
```

Deploys the contract, setting the unlock time and owner.

_Requires the unlock time to be in the future._

#### Parameters

| Name         | Type    | Description                                        |
| ------------ | ------- | -------------------------------------------------- |
| \_unlockTime | uint256 | The timestamp after which withdrawals are allowed. |

### withdraw

```solidity
function withdraw() public
```

Withdraws all funds from the contract if the unlock time has passed and caller is the owner.

_Emits a {Withdrawal} event and transfers the full balance to the owner._
