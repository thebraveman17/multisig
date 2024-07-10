// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract MultiSig {
    uint8 private immutable i_totalNumberOfOwners;
    uint8 private immutable i_minimumRequiredSigners;
    address[] private s_owners;
    mapping(address owner => bool isOwner) private s_addressIsOwner;

    error MinimumRequiredSignersCantBeZero();
    error InvalidAmountOfSigners();
    error InvalidOwnersLength();
    error OwnerCantBeZeroAddress();
    error DuplicateOwner(address owner);

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
}
