// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract MultiSig {
    enum TransactionStatus {
        PendingApprovals,
        Executed
    }

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        TransactionStatus transactionStatus;
    }

    Transaction[] private s_transactions;
    uint8 private immutable i_totalNumberOfOwners;
    uint8 private immutable i_minimumRequiredSigners;
    address[] private s_owners;
    mapping(address owner => bool isOwner) private s_addressIsOwner;
    mapping(uint64 transactionID => mapping(address owner => bool isApproved)) private s_transactionIsApproved;

    event TransactionCreated(
        uint64 transactionID, address indexed owner, address indexed to, uint256 value, bytes data
    );
    event TransactionApproved(uint64 transactionID, address indexed owner);

    error MinimumRequiredSignersCantBeZero();
    error InvalidAmountOfSigners();
    error InvalidOwnersLength();
    error OwnerCantBeZeroAddress();
    error DuplicateOwner(address owner);
    error NotOwner();
    error ReceiverIsZeroAddress();
    error TransactionDoesntExist();
    error TransactionAlreadyApproved();
    error TransactionAlreadyExecuted();

    modifier onlyOwner(address addr) {
        if (!s_addressIsOwner[addr]) {
            revert NotOwner();
        }
        _;
    }

    modifier transactionExists(uint64 transactionID) {
        if (transactionID >= s_transactions.length) {
            revert TransactionDoesntExist();
        }
        _;
    }

    modifier notExecuted(uint64 transactionID) {
        if (s_transactions[transactionID].transactionStatus == TransactionStatus.Executed) {
            revert TransactionAlreadyExecuted();
        }
        _;
    }

    modifier notApproved(uint64 transactionID) {
        if (s_transactionIsApproved[transactionID][msg.sender]) {
            revert TransactionAlreadyApproved();
        }
        _;
    }

    /// @param totalNumberOfOwners This is the total number of owners
    /// @param minimumRequiredSigners This is the minimum number of signers
    /// @param owners This is the list of owners
    constructor(uint8 totalNumberOfOwners, uint8 minimumRequiredSigners, address[] memory owners) {
        if (minimumRequiredSigners == 0) {
            revert MinimumRequiredSignersCantBeZero();
        }

        if (totalNumberOfOwners < minimumRequiredSigners) {
            revert InvalidAmountOfSigners();
        }

        if (totalNumberOfOwners != owners.length) {
            revert InvalidOwnersLength();
        }

        i_totalNumberOfOwners = totalNumberOfOwners;
        i_minimumRequiredSigners = minimumRequiredSigners;

        for (uint8 i = 0; i < totalNumberOfOwners;) {
            address owner = owners[i];
            if (owner == address(0)) {
                revert OwnerCantBeZeroAddress();
            }

            if (s_addressIsOwner[owner]) {
                revert DuplicateOwner(owner);
            }

            s_addressIsOwner[owner] = true;
            s_owners.push(owner);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice This function creates a new transaction
    /// @param to The address of the receiver
    /// @param value The value to send
    /// @param data The calldata
    function createTransaction(address to, uint256 value, bytes memory data) external onlyOwner(msg.sender) {
        if (to == address(0)) {
            revert ReceiverIsZeroAddress();
        }

        uint64 transactionID = uint64(s_transactions.length);
        s_transactions.push(Transaction(to, value, data, TransactionStatus.PendingApprovals));
        s_transactionIsApproved[transactionID][msg.sender] = true;
        emit TransactionCreated(transactionID, msg.sender, to, value, data);
    }

    /// @notice This function approves a transaction with the given ID
    /// @param transactionID The ID of the transaction
    function approveTransaction(uint64 transactionID)
        external
        onlyOwner(msg.sender)
        transactionExists(transactionID)
        notExecuted(transactionID)
        notApproved(transactionID)
    {
        s_transactionIsApproved[transactionID][msg.sender] = true;

        emit TransactionApproved(transactionID, msg.sender);
    }

    /// @notice This function returns the total number of owners
    function getTotalNumberOfOwners() external view returns (uint8) {
        return i_totalNumberOfOwners;
    }

    /// @notice This function returns the minimum number of signers
    function getMinimumRequiredSigners() external view returns (uint8) {
        return i_minimumRequiredSigners;
    }

    /// @notice This function returns the list of owners
    function getOwners() external view returns (address[] memory) {
        return s_owners;
    }

    /// @notice This function returns the approval status for the given transactionID and owner
    function getApprovalStatus(uint64 transactionID, address owner)
        external
        view
        onlyOwner(owner)
        transactionExists(transactionID)
        returns (bool)
    {
        return s_transactionIsApproved[transactionID][owner];
    }

    /// @notice This function returns the transaction with the given ID
    function getTransaction(uint64 transactionID) external view returns (address, uint256, bytes memory, uint8) {
        return (
            s_transactions[transactionID].to,
            s_transactions[transactionID].value,
            s_transactions[transactionID].data,
            uint8(s_transactions[transactionID].transactionStatus)
        );
    }
}
