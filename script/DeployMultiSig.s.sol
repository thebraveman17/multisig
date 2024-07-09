// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MultiSig} from "../src/MultiSig.sol";

contract DeployMultiSig is Script {
    MultiSig private s_multiSig;
    uint8 public constant TOTAL_NUMBER_OF_OWNERS = 3;
    uint8 public constant MINIMUM_REQUIRED_SIGNERS = 2;
    address[] public s_owners;

    function run() external returns (MultiSig) {
        for (uint8 i = 1; i <= TOTAL_NUMBER_OF_OWNERS;) {
            s_owners.push(address(uint160(i)));

            unchecked {
                ++i;
            }
        }
        
        s_multiSig = new MultiSig(TOTAL_NUMBER_OF_OWNERS, MINIMUM_REQUIRED_SIGNERS, s_owners);
        return s_multiSig;
    }
}
