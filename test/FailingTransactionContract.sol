// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

/// @notice This contract is used to test the custom TransactionFailed error in MultiSig contract if the transaction is reverted. It only implements the receive function that reverts on any incoming transaction
contract FailingTransactionContract {
    receive() external payable {
        revert();
    }
}
