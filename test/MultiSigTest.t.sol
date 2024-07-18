// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployMultiSig} from "../script/DeployMultiSig.s.sol";
import {MultiSig} from "../src/MultiSig.sol";
import {FailingTransactionContract} from "./FailingTransactionContract.sol";

contract MultiSigTest is Test {
    MultiSig private s_multiSig;
    DeployMultiSig private s_deployer;
    address[] private s_owners;
    address private immutable i_receiver = makeAddr("receiver");
    uint256 private constant VALUE = 1e18;
    bytes private constant CALLDATA = "0x00";
    string private constant DESCRIPTION = "Description";

    modifier transactionCreated() {
        vm.prank(_getOwner(0));
        s_multiSig.createTransaction(i_receiver, VALUE, CALLDATA, DESCRIPTION);
        _;
    }

    modifier transactionExecuted() {
        vm.deal(address(s_multiSig), VALUE);
        vm.prank(_getOwner(0));
        s_multiSig.createTransaction(i_receiver, VALUE, CALLDATA, DESCRIPTION);
        vm.startPrank(_getOwner(1));
        s_multiSig.approveTransaction(0);
        s_multiSig.executeTransaction(0);
        vm.stopPrank();
        _;
    }

    function setUp() external {
        s_deployer = new DeployMultiSig();
        s_multiSig = s_deployer.run();
    }

    function testDeploymentFailsIfMinimumRequiredSignersIsZero() external {
        uint8 totalNumberOfOwners = 3;
        uint8 minimumRequiredSigners = 0;

        _initializeOwnersArray(totalNumberOfOwners);

        vm.expectRevert(MultiSig.MinimumRequiredSignersCantBeZero.selector);
        s_multiSig = new MultiSig(totalNumberOfOwners, minimumRequiredSigners, s_owners);
    }

    function testDeploymentFailsWhenTotalNumberOfOwnersIsLessThanMinimumRequiredSigners() external {
        uint8 totalNumberOfOwners = 2;
        uint8 minimumRequiredSigners = 3;

        _initializeOwnersArray(totalNumberOfOwners);

        vm.expectRevert(MultiSig.InvalidAmountOfSigners.selector);
        s_multiSig = new MultiSig(totalNumberOfOwners, minimumRequiredSigners, s_owners);
    }

    function testDeploymentFailsWhenTotalNumberOfOwnersIsNotEqualToOwnersLength() external {
        uint8 totalNumberOfOwners = 3;
        uint8 minimumRequiredSigners = 2;

        _initializeOwnersArray(totalNumberOfOwners - 1);

        vm.expectRevert(MultiSig.InvalidOwnersLength.selector);
        s_multiSig = new MultiSig(totalNumberOfOwners, minimumRequiredSigners, s_owners);
    }

    function testDeploymentFailsIfAtLeastOneOwnerIsZeroAddress() external {
        uint8 totalNumberOfOwners = 3;
        uint8 minimumRequiredSigners = 2;

        for (uint8 i = 1; i <= totalNumberOfOwners;) {
            s_owners.push(address(0));

            unchecked {
                ++i;
            }
        }

        vm.expectRevert(MultiSig.OwnerCantBeZeroAddress.selector);
        s_multiSig = new MultiSig(totalNumberOfOwners, minimumRequiredSigners, s_owners);
    }

    function testDeploymentFailsIfThereIsDuplicateOwner() external {
        uint8 totalNumberOfOwners = 3;
        uint8 minimumRequiredSigners = 2;

        for (uint8 i = 1; i <= totalNumberOfOwners;) {
            s_owners.push(address(1));

            unchecked {
                ++i;
            }
        }

        vm.expectRevert(abi.encodeWithSelector(MultiSig.DuplicateOwner.selector, address(1)));
        s_multiSig = new MultiSig(totalNumberOfOwners, minimumRequiredSigners, s_owners);
    }

    function testTotalNumberOfOwnersIsCorrect() external view {
        uint8 expectedTotalNumberOfOwners = s_deployer.TOTAL_NUMBER_OF_OWNERS();
        uint8 actualTotalNumberOfOwners = s_multiSig.getTotalNumberOfOwners();
        assertEq(expectedTotalNumberOfOwners, actualTotalNumberOfOwners);
    }

    function testMinimumRequiredSignersIsCorrect() external view {
        uint8 expectedMinimumRequiredSigners = s_deployer.MINIMUM_REQUIRED_SIGNERS();
        uint8 actualMinimumRequiredSigners = s_multiSig.getMinimumRequiredSigners();
        assertEq(expectedMinimumRequiredSigners, actualMinimumRequiredSigners);
    }

    function testOwnersAreCorrect() external view {
        uint8 numberOfOwners = s_deployer.TOTAL_NUMBER_OF_OWNERS();
        for (uint8 i = 0; i < numberOfOwners;) {
            address expectedOwner = s_deployer.s_owners(i);
            address actualOwner = s_multiSig.getOwners()[i];

            assertEq(expectedOwner, actualOwner);
            unchecked {
                ++i;
            }
        }
    }

    function testCreateTransactionFailsIfSenderIsNotOwner() external {
        vm.expectRevert(MultiSig.NotOwner.selector);
        s_multiSig.createTransaction(i_receiver, VALUE, CALLDATA, DESCRIPTION);
    }

    function testCreateTransactionFailsIfReceiverIsZeroAddress() external {
        vm.prank(address(1));
        vm.expectRevert(MultiSig.ReceiverIsZeroAddress.selector);
        s_multiSig.createTransaction(address(0), VALUE, CALLDATA, DESCRIPTION);
    }

    function testCreateTransactionStateIsUpdatedCorrectlyAndEventIsEmitted() external {
        vm.startPrank(address(1));
        vm.expectEmit(true, true, false, true);
        emit MultiSig.TransactionCreated(0, address(1), i_receiver, VALUE, CALLDATA, DESCRIPTION);
        s_multiSig.createTransaction(i_receiver, VALUE, CALLDATA, DESCRIPTION);
        (address actualReceiver, uint256 actualValue, bytes memory actualCalldata, uint8 transactionStatus) =
            s_multiSig.getTransaction(0);
        assertEq(i_receiver, actualReceiver);
        assertEq(VALUE, actualValue);
        assertEq(CALLDATA, actualCalldata);
        assertEq(0, transactionStatus);
        vm.stopPrank();
    }

    function testApproveTransactionFailsIfSenderIsNotOwner() external {
        vm.expectRevert(MultiSig.NotOwner.selector);
        s_multiSig.approveTransaction(0);
    }

    function testApproveTransactionFailsIfTransactionDoesntExist() external {
        vm.prank(_getOwner(0));
        vm.expectRevert(MultiSig.TransactionDoesntExist.selector);
        s_multiSig.approveTransaction(0);
    }

    function testApproveTransactionFailsIfTransactionIsAlreadyExecuted() external transactionExecuted {
        vm.prank(_getOwner(2));
        vm.expectRevert(MultiSig.TransactionAlreadyExecuted.selector);
        s_multiSig.approveTransaction(0);
    }

    function testApproveTransactionFailsIfTransactionIsAlreadyApproved() external {
        vm.startPrank(_getOwner(1));
        s_multiSig.createTransaction(i_receiver, VALUE, CALLDATA, DESCRIPTION);
        vm.expectRevert(MultiSig.TransactionAlreadyApproved.selector);
        s_multiSig.approveTransaction(0);
        vm.stopPrank();
    }

    function testApproveTransactionStateUpdatesAndEvents() external transactionCreated {
        address owner = _getOwner(1);
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit MultiSig.TransactionApproved(0, owner);
        s_multiSig.approveTransaction(0);
        bool actualApprovalStatus = s_multiSig.getApprovalStatus(0, owner);
        assertEq(actualApprovalStatus, true);
    }

    function testRevokeApprovalFailsIfSenderIsNotOwner() external transactionCreated {
        vm.expectRevert(MultiSig.NotOwner.selector);
        s_multiSig.revokeApproval(0);
    }

    function testRevokeApprovalFailsIfTransactionDoesntExist() external {
        vm.prank(_getOwner(0));
        vm.expectRevert(MultiSig.TransactionDoesntExist.selector);
        s_multiSig.revokeApproval(0);
    }

    function testRevokeApprovalFailsIfTransactionIsntApproved() external transactionCreated {
        vm.prank(_getOwner(1));
        vm.expectRevert(MultiSig.TransactionNotApproved.selector);
        s_multiSig.revokeApproval(0);
    }

    function testRevokeApprovalStateIsUpdatedCorrectlyAndEventIsEmitted() external transactionCreated {
        vm.startPrank(_getOwner(0));
        vm.expectEmit(true, false, false, true);
        emit MultiSig.ApprovalRevoked(0, _getOwner(0));
        s_multiSig.revokeApproval(0);
        vm.stopPrank();
        bool actualApprovalStatus = s_multiSig.getApprovalStatus(0, _getOwner(0));
        assertEq(actualApprovalStatus, false);
    }

    function testExecuteTransactionFailsIfSenderIsNotOwner() external {
        vm.expectRevert(MultiSig.NotOwner.selector);
        s_multiSig.executeTransaction(0);
    }

    function testExecuteTransactionFailsIfTransactionDoesntExist() external {
        vm.prank(_getOwner(0));
        vm.expectRevert(MultiSig.TransactionDoesntExist.selector);
        s_multiSig.executeTransaction(0);
    }

    function testExecuteTransactionFailsIfThereArentEnoughApprovals() external transactionCreated {
        vm.prank(_getOwner(0));
        vm.expectRevert(abi.encodeWithSelector(MultiSig.NotEnoughApprovals.selector, 1));
        s_multiSig.executeTransaction(0);
    }

    function testExecuteTransactionFailsIfSendFails() external {
        FailingTransactionContract failingTransactionContract = new FailingTransactionContract();
        vm.prank(_getOwner(0));
        s_multiSig.createTransaction(address(failingTransactionContract), VALUE, CALLDATA, DESCRIPTION);
        vm.startPrank(_getOwner(1));
        s_multiSig.approveTransaction(0);
        vm.expectRevert(MultiSig.TransactionFailed.selector);
        s_multiSig.executeTransaction(0);
        vm.stopPrank();
    }

    function testExecuteFailsIfTransactionIsAlreadyExecuted() external transactionExecuted {
        vm.prank(_getOwner(0));
        vm.expectRevert(MultiSig.TransactionAlreadyExecuted.selector);
        s_multiSig.executeTransaction(0);
    }

    function testExecuteTransactionUpdatesStateCorrectlyAndEmitsEvent() external transactionCreated {
        vm.deal(address(s_multiSig), VALUE);
        vm.startPrank(_getOwner(1));
        s_multiSig.approveTransaction(0);
        vm.expectEmit(true, true, false, true);
        emit MultiSig.TransactionExecuted(0, _getOwner(1), i_receiver, VALUE, CALLDATA, DESCRIPTION);
        s_multiSig.executeTransaction(0);
        (,,, uint8 actualTransactionStatus) = s_multiSig.getTransaction(0);
        assertEq(actualTransactionStatus, 1);
        vm.stopPrank();
    }

    function testGetApprovalStatusFailsIfAddressIsNotOwner() external transactionCreated {
        vm.expectRevert(MultiSig.AddressIsNotOwner.selector);
        s_multiSig.getApprovalStatus(0, address(55));
    }

    function _initializeOwnersArray(uint8 totalNumberOfOwners) private {
        for (uint8 i = 1; i <= totalNumberOfOwners;) {
            s_owners.push(address(uint160(i)));

            unchecked {
                ++i;
            }
        }
    }

    function _getOwner(uint256 index) private view returns (address) {
        return s_multiSig.getOwners()[index];
    }
}
