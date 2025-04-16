pragma solidity =0.8.24;

// solhint-disable no-console

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
// -rw-rw-r-- 1 qxr qxr   963 Apr 10 04:53 DeployFallbackContracts.s.sol
// -rw-rw-r-- 1 qxr qxr 10830 Apr 16 00:40 DeployL1BridgeContracts.s.sol
// -rw-rw-r-- 1 qxr qxr  5045 Apr 10 04:53 DeployL1BridgeProxyPlaceholder.s.sol
// -rw-rw-r-- 1 qxr qxr  2369 Apr 10 04:53 DeployL1ScrollOwner.s.sol
// -rw-rw-r-- 1 qxr qxr  8892 Apr 10 04:53 DeployL2BridgeContracts.s.sol
// -rw-rw-r-- 1 qxr qxr  3815 Apr 10 04:53 DeployL2BridgeProxyPlaceholder.s.sol
// -rw-rw-r-- 1 qxr qxr  2369 Apr 10 04:53 DeployL2ScrollOwner.s.sol
// -rw-rw-r-- 1 qxr qxr  2534 Apr 10 04:53 DeployLidoGateway.s.sol
// -rw-rw-r-- 1 qxr qxr  1204 Apr 10 04:53 DeployScrollChainCommitmentVerifier.s.sol
// -rw-rw-r-- 1 qxr qxr  1085 Apr 10 04:53 DeployWeth.s.sol
// -rw-rw-r-- 1 qxr qxr 12757 Apr 13 04:29 InitializeL1BridgeContracts.s.sol
// -rw-rw-r-- 1 qxr qxr 15149 Apr 10 04:53 InitializeL1ScrollOwner.s.sol
// -rw-rw-r-- 1 qxr qxr  8620 Apr 10 04:53 InitializeL2BridgeContracts.s.sol
// -rw-rw-r-- 1 qxr qxr 11132 Apr 10 04:53 InitializeL2ScrollOwner.s.sol
// SPDX-License-Identifier: UNLICENSED

import {DeployFallbackContracts} from "./DeployFallbackContracts.s.sol";
import {DeployL1BridgeContracts} from "./DeployL1BridgeContracts.s.sol";
import {DeployL1BridgeProxyPlaceholder} from "./DeployL1BridgeProxyPlaceholder.s.sol";
import {DeployL1ScrollOwner} from "./DeployL1ScrollOwner.s.sol";
import {DeployL2BridgeContracts} from "./DeployL2BridgeContracts.s.sol";
import {DeployL2BridgeProxyPlaceholder} from "./DeployL2BridgeProxyPlaceholder.s.sol";
import {DeployL2ScrollOwner} from "./DeployL2ScrollOwner.s.sol";
import {DeployLidoGateway} from "./DeployLidoGateway.s.sol";
import {DeployScrollChainCommitmentVerifier} from "./DeployScrollChainCommitmentVerifier.s.sol";
import {DeployWeth} from "./DeployWeth.s.sol";
import {InitializeL1BridgeContracts} from "./InitializeL1BridgeContracts.s.sol";
import {InitializeL1ScrollOwner} from "./InitializeL1ScrollOwner.s.sol";
import {InitializeL2BridgeContracts} from "./InitializeL2BridgeContracts.s.sol";
import {InitializeL2ScrollOwner} from "./InitializeL2ScrollOwner.s.sol";

contract DeployAll is Script {
    function run() public {
        new DeployL1ScrollOwner();
        new DeployL2ScrollOwner();

        new DeployFallbackContracts();
        new DeployL1BridgeProxyPlaceholder();
        new DeployL2BridgeProxyPlaceholder();

        new DeployL1BridgeContracts();
        new DeployL2BridgeContracts();

        new DeployLidoGateway();
        new DeployScrollChainCommitmentVerifier();
        new DeployWeth();
        new InitializeL1BridgeContracts();
        new InitializeL1ScrollOwner();
        new InitializeL2BridgeContracts();
        new InitializeL2ScrollOwner();
    }
}
