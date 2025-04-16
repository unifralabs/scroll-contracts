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
            bool isSimulation = vm.envBool("IS_SIMULATION");
            if (isSimulation) {
                (, address msgSender, ) = vm.readCallers();
                uint64 originalNonce = vm.getNonce(msgSender);
                vm.stopBroadcast();
                WrappedEther weth = new WrappedEther();
                vm.etch(L1_WETH_ADDR, address(weth).code);

                vm.setNonce(msgSender, originalNonce);
                vm.startBroadcast(msgSender);
            }
        }
        logAddress("L1_WETH_ADDR", L1_WETH_ADDR);
    }
}
