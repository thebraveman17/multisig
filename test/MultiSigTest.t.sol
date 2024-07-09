// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployMultiSig} from "../script/DeployMultiSig.s.sol";
import {MultiSig} from "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSig private s_multiSig;
    DeployMultiSig private s_deployer;
    address[] private s_owners;

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

    function _initializeOwnersArray(uint8 totalNumberOfOwners) private {
        for (uint8 i = 1; i <= totalNumberOfOwners;) {
            s_owners.push(address(uint160(i)));

            unchecked {
                ++i;
            }
        }
    }
}
