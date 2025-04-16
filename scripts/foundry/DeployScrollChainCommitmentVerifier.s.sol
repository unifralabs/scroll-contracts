// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.24;

import {MyScript} from "./MyScript.s.sol";
import {ScrollChainCommitmentVerifier} from "../../src/L1/rollup/ScrollChainCommitmentVerifier.sol";

contract DeployScrollChainCommitmentVerifier is MyScript {
    uint256 L1_DEPLOYER_PRIVATE_KEY = vm.envUint("L1_DEPLOYER_PRIVATE_KEY");

    address L1_SCROLL_CHAIN_PROXY_ADDR = vm.envAddress("L1_SCROLL_CHAIN_PROXY_ADDR");

    address POSEIDON_UNIT2_ADDR = vm.envAddress("POSEIDON_UNIT2_ADDR");

    function run() external {
        vm.startBroadcast(L1_DEPLOYER_PRIVATE_KEY);

        deployScrollChainCommitmentVerifier();

        vm.stopBroadcast();
    }

    function deployScrollChainCommitmentVerifier() internal {
        ScrollChainCommitmentVerifier verifier = new ScrollChainCommitmentVerifier(
            POSEIDON_UNIT2_ADDR,
            L1_SCROLL_CHAIN_PROXY_ADDR
        );

        logAddress("L1_SCROLL_CHAIN_COMMITMENT_VERIFIER", address(verifier));
    }
}
