// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.24;

import {MyScript} from "./MyScript.s.sol";

import {WrappedEther} from "../../src/L2/predeploys/WrappedEther.sol";

contract DeployWeth is MyScript {
    address L1_WETH_ADDR = vm.envAddress("L1_WETH_ADDR");
    address L2_WETH_ADDR = vm.envAddress("L2_WETH_ADDR");

    function run() external {
        // deploy weth only if we're running a private L1 network
        if (L1_WETH_ADDR == address(0)) {
            uint256 L1_WETH_DEPLOYER_PRIVATE_KEY = vm.envUint("L1_WETH_DEPLOYER_PRIVATE_KEY");
            vm.startBroadcast(L1_WETH_DEPLOYER_PRIVATE_KEY);
            WrappedEther weth = new WrappedEther();
            L1_WETH_ADDR = address(weth);
            vm.stopBroadcast();
        } else {
            uint256 isSimulation = vm.envUint("IS_SIMULATION");
            if (isSimulation == 1) {
                (, , address txOrigin) = vm.readCallers();
                uint64 originalNonce = vm.getNonce(txOrigin);
                WrappedEther weth = new WrappedEther();
                vm.etch(L1_WETH_ADDR, address(weth).code);
                for (uint256 i = 0; i <= 8; i++) {
                    bytes32 val = vm.load(address(weth), bytes32(i));
                    if (val != bytes32(0)) {
                        vm.store(L1_WETH_ADDR, bytes32(i), val);
                    }
                }
                vm.setNonce(txOrigin, originalNonce);
            }
        }
        logAddress("L1_WETH_ADDR", L1_WETH_ADDR);
    }
}
