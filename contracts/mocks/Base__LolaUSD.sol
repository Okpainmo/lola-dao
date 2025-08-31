// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../interfaces/IAdminManagement__Base.sol";
import "../interfaces/IProposalManagement__Base.sol";

contract Base__LolaUSD {
    error LolaUSD__InsufficientBalance();
    error LolaUSD__OperatorAddressIsZeroAddress();
    error LolaUSD__OwnerAddressIsZeroAddress();
    error LolaUSD__ReceiverAddressIsZeroAddress();
    error LolaUSD__TransferOperationWasUnsuccessful();
    error LolaUSD__ExcessSpendRequestOrUnauthorized();
    error LolaUSD__ExcessAllowanceDecrement();
    error LolaUSD__UnsuccessfulTransferFromOperation();
    error LolaUSD__ZeroAddressError();
    error LolaUSD__AccessDenied_AdminOnly();
    error LolaUSD__ProposalAlreadyExecuted();
    error LolaUSD__InvalidProposalCodeName();
    error LolaUSD__ProposalIsNotMintable();
    error  LolaUSD__ProposalIsNotBurnable();

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

    address internal s_adminManagementCoreContractAddress; // needed to check admin rights and likely more
    address internal s_proposalManagementCoreContractAddress; // needed for interaction with the external proposals management core contract

    IAdminManagement__Base internal s_adminManagementContract__Base =
        IAdminManagement__Base(s_adminManagementCoreContractAddress);
    IProposalManagement__Base internal s_proposalManagementContract__Base =
        IProposalManagement__Base(s_proposalManagementCoreContractAddress);

    string internal s_tokenName;
    string internal s_tokenSymbol;
    uint8 internal s_tokenDecimals;
    uint256 internal s_supply;

    mapping(address => uint256) internal balance;
    mapping(address => mapping(address => uint256)) internal allowedSpend;

    function name() public view returns (string memory) {
        return s_tokenName;
    }

    function symbol() public view returns (string memory) {
        return s_tokenSymbol;
    }

    function decimals() public view returns (uint8) {
        return s_tokenDecimals;
    }

    function totalSupply() public view returns (uint256) {
        return s_supply / (10 ** s_tokenDecimals);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balance[_owner] / (10 ** s_tokenDecimals);
    }

    function approve(address _operator, uint256 _value) public returns (bool) {
        _value = _value * 10 ** s_tokenDecimals;

        if (_operator == address(0)) {
            revert LolaUSD__OperatorAddressIsZeroAddress();
        }

        allowedSpend[msg.sender][_operator] = _value; // user(msg.sender) allows platform/operator, e.g. a DEX, to currently be able to spend '_value' amount from their balance

        emit Approval(msg.sender, _operator, _value);

        return true;
    }

    function allowance(
        address _owner,
        address _operator
    ) public view returns (uint256) {
        return allowedSpend[_owner][_operator] / (10 ** s_tokenDecimals); // check how much a user has allowed an operator to spend
    }

    function increaseAllowance(
        address _operator,
        uint256 _amountToAdd
    ) external returns (bool) {
        _amountToAdd = _amountToAdd * 10 ** s_tokenDecimals;

        if (_operator == address(0)) {
            revert LolaUSD__OperatorAddressIsZeroAddress();
        }

        uint256 newAllowance = allowedSpend[msg.sender][_operator] +
            _amountToAdd;

        allowedSpend[msg.sender][_operator] = newAllowance;

        emit Approval(msg.sender, _operator, newAllowance);

        return true;
    }

    function decreaseAllowance(
        address _operator,
        uint256 _amountToDeduct
    ) external returns (bool) {
        _amountToDeduct = _amountToDeduct * 10 ** s_tokenDecimals;

        if (_operator == address(0)) {
            revert LolaUSD__OperatorAddressIsZeroAddress();
        }

        uint256 currentAllowance = allowedSpend[msg.sender][_operator];

        if (_amountToDeduct > currentAllowance) {
            revert LolaUSD__ExcessAllowanceDecrement();
        }

        uint256 newAllowance = currentAllowance - (_amountToDeduct);

        allowedSpend[msg.sender][_operator] = newAllowance;

        emit Approval(msg.sender, _operator, newAllowance);

        return true;
    }

    function transfer(address _receiver, uint256 _value) public returns (bool) {
        _value = _value * 10 ** s_tokenDecimals;

        if (_receiver == address(0)) {
            revert LolaUSD__ReceiverAddressIsZeroAddress();
        }

        if (_value > balance[msg.sender]) {
            revert LolaUSD__InsufficientBalance();
        }

        balance[msg.sender] -= (_value);
        balance[_receiver] += (_value);

        emit Transfer(msg.sender, _receiver, _value);

        return true;
    }

    function transferFrom(
        address _owner,
        address _receiver,
        uint256 _value
    ) public returns (bool) {
        _value = _value * 10 ** s_tokenDecimals;

        if (_receiver == address(0)) {
            revert LolaUSD__ReceiverAddressIsZeroAddress();
        }

        if (_owner == address(0)) {
            revert LolaUSD__OwnerAddressIsZeroAddress();
        }

        uint256 currentAllowance = allowedSpend[_owner][msg.sender];

        if (currentAllowance < _value) {
            revert LolaUSD__ExcessSpendRequestOrUnauthorized();
        }

        if (balance[_owner] < _value) {
            revert LolaUSD__InsufficientBalance();
        }

        balance[_owner] -= _value;
        balance[_receiver] += _value;

        // standard “infinite approval” behavior: an added if block
        // if (currentAllowance != type(uint256).max) {
        //     allowedSpend[_owner][msg.sender] = currentAllowance - _value;
        //     emit Approval(_owner, msg.sender, allowedSpend[_owner][msg.sender]); // optional but good practice
        // }

        allowedSpend[_owner][msg.sender] = currentAllowance - _value;
        emit Approval(_owner, msg.sender, allowedSpend[_owner][msg.sender]); // optional but good practice
        // allowedSpend[_owner][msg.sender] =  0;

        emit Transfer(_owner, _receiver, _value);

        return true;
    }

    function _normalize(string memory s) internal pure returns (bytes memory) {
    return abi.encodePacked(_toLower(s));
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bStr[i] = bytes1(uint8(bStr[i]) + 32);
            }
        }
        return string(bStr);
    }

    function mint(
        address _to,
        uint256 _proposalId,
        string memory _proposalCodeName
    ) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert LolaUSD__AccessDenied_AdminOnly();
        }

        IProposalManagement__Base.Proposal
            memory proposal = s_proposalManagementContract__Base.getProposalById(
            _proposalId
        );

        if (
            keccak256(_normalize(proposal.proposalCodeName)) !=
            keccak256(_normalize(_proposalCodeName))
        ) {
            revert LolaUSD__InvalidProposalCodeName();
        }

        if (
            proposal.proposalStatus ==
            IProposalManagement__Base.ProposalStatus.Executed
        ) {
            revert LolaUSD__ProposalAlreadyExecuted();
        }

        if (
            proposal.proposalAction != IProposalManagement__Base.ProposalAction.Mint
        ) {
            revert LolaUSD__ProposalIsNotMintable();
        }

        if (_to == address(0)) {
            revert LolaUSD__ReceiverAddressIsZeroAddress();
        }

        uint256 _amount = proposal.tokenSupplyChange * 10 ** s_tokenDecimals;

        s_supply += _amount;

        balance[_to] += _amount;

        emit Transfer(address(0), _to, _amount);

        // updates the status of the proposal in the external proposal-management core contract to "executed"
        s_proposalManagementContract__Base.executeProposal(_proposalId);
    }

    function burn(
        address _from,
        uint256 _proposalId,
        string memory _proposalCodeName
    ) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert LolaUSD__AccessDenied_AdminOnly();
        }

        IProposalManagement__Base.Proposal
            memory proposal = s_proposalManagementContract__Base.getProposalById(
                _proposalId
            );

        if (
            proposal.proposalStatus ==
            IProposalManagement__Base.ProposalStatus.Executed
        ) {
            revert LolaUSD__ProposalAlreadyExecuted();
        }

        if (
            keccak256(_normalize(proposal.proposalCodeName)) !=
            keccak256(_normalize(_proposalCodeName))
        ) {
            revert LolaUSD__InvalidProposalCodeName();
        }

        if (
            proposal.proposalStatus ==
            IProposalManagement__Base.ProposalStatus.Executed
        ) {
            revert LolaUSD__ProposalAlreadyExecuted();
        }

        if (
            proposal.proposalAction != IProposalManagement__Base.ProposalAction.Burn
        ) {
            revert LolaUSD__ProposalIsNotBurnable();
        }

        if (_from == address(0)) {
            revert LolaUSD__OwnerAddressIsZeroAddress();
        }

        uint256 _amount = proposal.tokenSupplyChange * 10 ** s_tokenDecimals;

        if (balance[_from] < _amount) {
            revert LolaUSD__InsufficientBalance();
        }

        if (_from == msg.sender) {
            // if self(master or admin) address, proceed to burn directly
            balance[_from] -= _amount;
            s_supply -= _amount;

            emit Transfer(msg.sender, address(0), _amount);
        } else {
            // if not self address, proceed to burn via allowance
            uint256 currentAllowance = allowedSpend[_from][msg.sender];

            if (currentAllowance < _amount) {
                revert LolaUSD__ExcessSpendRequestOrUnauthorized();
            }

            balance[_from] -= _amount;
            s_supply -= _amount;

            allowedSpend[_from][msg.sender] = currentAllowance - _amount;
            emit Approval(_from, msg.sender, allowedSpend[_from][msg.sender]);

            emit Transfer(_from, address(0), _amount);
        }

        // updates the status of the proposal in the external proposal-management core contract to "executed"
        s_proposalManagementContract__Base.executeProposal(_proposalId);
    }
}

