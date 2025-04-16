// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.24;

// solhint-disable no-console

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract MyScript is Script {
    constructor() {}

    function logAddress(string memory name, address addr) internal {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
        vm.setEnv(name, vm.toString(address(addr)));
    }
}
