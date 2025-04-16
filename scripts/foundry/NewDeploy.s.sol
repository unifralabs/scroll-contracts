// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Import all deployment scripts
import {DeployFallbackContracts} from "./DeployFallbackContracts.s.sol";
import {DeployL1BridgeContracts} from "./DeployL1BridgeContracts.s.sol";
import {DeployL1BridgeProxyPlaceholder} from "./DeployL1BridgeProxyPlaceholder.s.sol";
import {DeployL1ScrollOwner} from "./DeployL1ScrollOwner.s.sol";
import {DeployL2BridgeContracts} from "./DeployL2BridgeContracts.s.sol";
import {DeployL2BridgeProxyPlaceholder} from "./DeployL2BridgeProxyPlaceholder.s.sol";
import {DeployL2ScrollOwner} from "./DeployL2ScrollOwner.s.sol";
// import {DeployL2Weth} from "./DeployL2Weth.s.sol";
import {DeployLidoGateway} from "./DeployLidoGateway.s.sol";
import {DeployScrollChainCommitmentVerifier} from "./DeployScrollChainCommitmentVerifier.s.sol";
import {DeployWeth} from "./DeployWeth.s.sol";

// Import all initialization scripts
import {InitializeL1BridgeContracts} from "./InitializeL1BridgeContracts.s.sol";
import {InitializeL1ScrollOwner} from "./InitializeL1ScrollOwner.s.sol";
import {InitializeL2BridgeContracts} from "./InitializeL2BridgeContracts.s.sol";
import {InitializeL2ScrollOwner} from "./InitializeL2ScrollOwner.s.sol";

import {WrappedEther} from "../../src/L2/predeploys/WrappedEther.sol";
import {MyScript} from "./MyScript.s.sol";

contract NewDeploy is MyScript {
    function run() external {
        uint256 l1Fork = vm.createSelectFork("L1");
        uint256 l2Fork = vm.createSelectFork("L2");

        console.log("=== Start Unified Deployment Process ===");

        console.log("== Deploying L2 Scroll Owner ==");
        vm.selectFork(l2Fork);
        new DeployL2ScrollOwner().run();

        console.log("== Deploying L1 Scroll Owner ==");
        vm.selectFork(l1Fork);
        new DeployL1ScrollOwner().run();

        // TODO: don't know if we need this
        // console.log("== Deploying L1 Fallback Contracts ==");
        // vm.selectFork(l1Fork);
        // new DeployFallbackContracts().run();

        console.log("== Deploying L2 Bridge Proxy Placeholders ==");
        vm.selectFork(l2Fork);
        new DeployL2BridgeProxyPlaceholder().run();

        console.log("== Deploying L1 Bridge Proxy Placeholders ==");
        vm.selectFork(l1Fork);
        new DeployL1BridgeProxyPlaceholder().run();

        console.log("== Deploying L1 WETH Contracts ==");
        vm.selectFork(l1Fork);
        new DeployWeth().run();

        console.log("== Deploying L2 WETH Contracts ==");
        vm.selectFork(l2Fork);
        DeployL2WETH();

        console.log("== Deploying L2 Bridge Contracts ==");
        vm.selectFork(l2Fork);
        new DeployL2BridgeContracts().run();

        console.log("== Deploying L1 Bridge Contracts ==");
        vm.selectFork(l1Fork);
        new DeployL1BridgeContracts().run();

        console.log("== Deploying L2 Lido Gateway & Verifier ==");
        vm.selectFork(l2Fork);
        new DeployLidoGateway().run();

        console.log("== Deploying Scroll Chain Commitment Verifier ==");
        vm.selectFork(l1Fork);
        new DeployScrollChainCommitmentVerifier().run();

        console.log("== Initializing Contracts ==");
        vm.selectFork(l1Fork);
        new InitializeL1BridgeContracts().run();
        new InitializeL1ScrollOwner().run();

        console.log("== Initializing L2 Contracts ==");
        vm.selectFork(l2Fork);
        new InitializeL2BridgeContracts().run();
        new InitializeL2ScrollOwner().run();

        console.log("=== Deployment Process Completed ===");
    }

    address L2_WETH_ADDR = vm.envAddress("L2_WETH_ADDR");

    function DeployL2WETH() internal {
        // if L2_WETH_ADDR is not set, deploy a new WETH
        uint256 L2_WETH_DEPLOYER_PRIVATE_KEY = vm.envUint("L2_WETH_DEPLOYER_PRIVATE_KEY");
        if (L2_WETH_ADDR == address(0)) {
            vm.startBroadcast(L2_WETH_DEPLOYER_PRIVATE_KEY);
            WrappedEther weth = new WrappedEther();
            L2_WETH_ADDR = address(weth);
            vm.stopBroadcast();
        } else {
            // if L2_WETH_ADDR is set, simulate the deployment
            bool isSimulation = vm.envBool("IS_SIMULATION");
            if (isSimulation) {
                (, address msgSender, ) = vm.readCallers();
                uint64 originalNonce = vm.getNonce(msgSender);
                vm.stopBroadcast();
                WrappedEther weth = new WrappedEther();
                vm.etch(L2_WETH_ADDR, address(weth).code);

                vm.setNonce(msgSender, originalNonce);
                vm.startBroadcast(msgSender);
            }
        }
        logAddress("L2_WETH_ADDR", L2_WETH_ADDR);
    }
}
