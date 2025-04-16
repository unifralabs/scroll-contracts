// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.24;
import {MyScript} from "./MyScript.s.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";
import {L2ERC1155Gateway} from "../../src/L2/gateways/L2ERC1155Gateway.sol";
import {L2ERC721Gateway} from "../../src/L2/gateways/L2ERC721Gateway.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2ScrollMessenger} from "../../src/L2/L2ScrollMessenger.sol";
import {L2StandardERC20Gateway} from "../../src/L2/gateways/L2StandardERC20Gateway.sol";
import {L2WETHGateway} from "../../src/L2/gateways/L2WETHGateway.sol";
import {L1GasPriceOracle} from "../../src/L2/predeploys/L1GasPriceOracle.sol";
import {L2MessageQueue} from "../../src/L2/predeploys/L2MessageQueue.sol";
import {L2TxFeeVault} from "../../src/L2/predeploys/L2TxFeeVault.sol";
import {Whitelist} from "../../src/L2/predeploys/Whitelist.sol";
import {ScrollStandardERC20} from "../../src/libraries/token/ScrollStandardERC20.sol";
import {ScrollStandardERC20Factory} from "../../src/libraries/token/ScrollStandardERC20Factory.sol";
import {console} from "forge-std/console.sol";

// solhint-disable max-states-count
// solhint-disable state-visibility
// solhint-disable var-name-mixedcase

contract DeployL2BridgeContracts is MyScript {
    uint256 L2_DEPLOYER_PRIVATE_KEY = vm.envUint("L2_DEPLOYER_PRIVATE_KEY");

    address L2_PROXY_ADMIN_ADDR = vm.envAddress("L2_PROXY_ADMIN_ADDR");

    address L1_TX_FEE_RECIPIENT_ADDR = vm.envAddress("L1_TX_FEE_RECIPIENT_ADDR");
    address L1_WETH_ADDR = vm.envAddress("L1_WETH_ADDR");
    address L2_WETH_ADDR = vm.envAddress("L2_WETH_ADDR");

    L1GasPriceOracle oracle;
    L2MessageQueue queue;
    ProxyAdmin proxyAdmin;
    L2GatewayRouter router;
    ScrollStandardERC20Factory factory;

    address L2_SCROLL_MESSENGER_PROXY_ADDR = vm.envAddress("L2_SCROLL_MESSENGER_PROXY_ADDR");

    address L1_SCROLL_MESSENGER_PROXY_ADDR = vm.envAddress("L1_SCROLL_MESSENGER_PROXY_ADDR");
    address L1_CUSTOM_ERC20_GATEWAY_PROXY_ADDR = vm.envAddress("L1_CUSTOM_ERC20_GATEWAY_PROXY_ADDR");
    address L1_ERC721_GATEWAY_PROXY_ADDR = vm.envAddress("L1_ERC721_GATEWAY_PROXY_ADDR");
    address L1_ERC1155_GATEWAY_PROXY_ADDR = vm.envAddress("L1_ERC1155_GATEWAY_PROXY_ADDR");
    address L1_ETH_GATEWAY_PROXY_ADDR = vm.envAddress("L1_ETH_GATEWAY_PROXY_ADDR");
    address L1_STANDARD_ERC20_GATEWAY_PROXY_ADDR = vm.envAddress("L1_STANDARD_ERC20_GATEWAY_PROXY_ADDR");
    address L1_WETH_GATEWAY_PROXY_ADDR = vm.envAddress("L1_WETH_GATEWAY_PROXY_ADDR");

    // predeploy contracts
    address L1_GAS_PRICE_ORACLE_PREDEPLOY_ADDR = vm.envOr("L1_GAS_PRICE_ORACLE_PREDEPLOY_ADDR", address(0));
    address L2_MESSAGE_QUEUE_PREDEPLOY_ADDR = vm.envOr("L2_MESSAGE_QUEUE_PREDEPLOY_ADDR", address(0));
    address L2_TX_FEE_VAULT_PREDEPLOY_ADDR = vm.envOr("L2_TX_FEE_VAULT_PREDEPLOY_ADDR", address(0));
    address L2_WHITELIST_PREDEPLOY_ADDR = vm.envOr("L2_WHITELIST_PREDEPLOY_ADDR", address(0));

    function run() external {
        proxyAdmin = ProxyAdmin(L2_PROXY_ADMIN_ADDR);

        vm.startBroadcast(L2_DEPLOYER_PRIVATE_KEY);

        // predeploys
        deployL1GasPriceOracle();
        deployL2MessageQueue();
        deployTxFeeVault();
        deployL2Whitelist();

        // upgradable
        deployL2ScrollMessenger();
        deployL2GatewayRouter();
        deployScrollStandardERC20Factory();
        deployL2StandardERC20Gateway();
        deployL2ETHGateway();
        deployL2WETHGateway();
        deployL2CustomERC20Gateway();
        deployL2ERC721Gateway();
        deployL2ERC1155Gateway();

        vm.stopBroadcast();
    }

    function deployL1GasPriceOracle() internal {
        address owner = vm.addr(L2_DEPLOYER_PRIVATE_KEY);
        if (L1_GAS_PRICE_ORACLE_PREDEPLOY_ADDR != address(0)) {
            if (vm.envUint("IS_SIMULATION") == 1) {
                (, , address txOrigin) = vm.readCallers();
                uint64 originNonce = vm.getNonce(txOrigin);
                vm.stopBroadcast();
                L1GasPriceOracle tmp = new L1GasPriceOracle(owner);
                vm.etch(L1_GAS_PRICE_ORACLE_PREDEPLOY_ADDR, address(tmp).code);
                for (uint256 i = 0; i <= 8; i++) {
                    bytes32 val = vm.load(address(tmp), bytes32(i));
                    if (val != bytes32(0)) {
                        vm.store(L1_GAS_PRICE_ORACLE_PREDEPLOY_ADDR, bytes32(i), val);
                    }
                }
                vm.setNonce(txOrigin, originNonce);
                vm.startBroadcast();
                oracle = L1GasPriceOracle(L1_GAS_PRICE_ORACLE_PREDEPLOY_ADDR);

                // log the address of the deployed contract
                logAddress("L1_GAS_PRICE_ORACLE_ADDR", address(L1_GAS_PRICE_ORACLE_PREDEPLOY_ADDR));
                return;
            } else {
                //check if exists
                if (L1GasPriceOracle(L1_GAS_PRICE_ORACLE_PREDEPLOY_ADDR).owner() != owner) {
                    revert("L1GasPriceOracle already exists");
                }
            }
        }

        oracle = new L1GasPriceOracle(owner);

        logAddress("L1_GAS_PRICE_ORACLE_ADDR", address(oracle));
    }

    function deployL2MessageQueue() internal {
        address owner = vm.addr(L2_DEPLOYER_PRIVATE_KEY);
        if (L2_MESSAGE_QUEUE_PREDEPLOY_ADDR != address(0)) {
            if (vm.envUint("IS_SIMULATION") == 1) {
                (, , address txOrigin) = vm.readCallers();
                uint64 originNonce = vm.getNonce(txOrigin);

                vm.stopBroadcast();
                L2MessageQueue tmp = new L2MessageQueue(owner);
                vm.etch(L2_MESSAGE_QUEUE_PREDEPLOY_ADDR, address(tmp).code);
                for (uint256 i = 0; i < 84; i++) {
                    bytes32 val = vm.load(address(tmp), bytes32(i));
                    if (val != bytes32(0)) {
                        vm.store(L2_MESSAGE_QUEUE_PREDEPLOY_ADDR, bytes32(i), val);
                    }
                }
                vm.setNonce(txOrigin, originNonce);
                vm.startBroadcast();

                queue = L2MessageQueue(L2_MESSAGE_QUEUE_PREDEPLOY_ADDR);
                vm.store(L2_MESSAGE_QUEUE_PREDEPLOY_ADDR, bytes32(uint256(0)), bytes32(uint256(uint160(owner))));

                logAddress("L2_MESSAGE_QUEUE_ADDR", address(L2_MESSAGE_QUEUE_PREDEPLOY_ADDR));
                return;
            }
        }

        queue = new L2MessageQueue(owner);

        logAddress("L2_MESSAGE_QUEUE_ADDR", address(queue));
    }

    function deployTxFeeVault() internal {
        address owner = vm.addr(L2_DEPLOYER_PRIVATE_KEY);
        if (L2_TX_FEE_VAULT_PREDEPLOY_ADDR != address(0)) {
            (, , address msgSender) = vm.readCallers();
            uint64 originNonce = vm.getNonce(msgSender);
            vm.stopBroadcast();
            L2TxFeeVault tmp = new L2TxFeeVault(owner, L1_TX_FEE_RECIPIENT_ADDR, 10 ether);
            vm.etch(L2_TX_FEE_VAULT_PREDEPLOY_ADDR, address(tmp).code);
            for (uint256 i = 0; i <= 4; i++) {
                bytes32 val = vm.load(address(tmp), bytes32(i));
                if (val != bytes32(0)) {
                    vm.store(L2_TX_FEE_VAULT_PREDEPLOY_ADDR, bytes32(i), val);
                }
            }

            vm.setNonce(msgSender, originNonce);
            vm.startBroadcast();

            logAddress("L2_TX_FEE_VAULT_ADDR", address(L2_TX_FEE_VAULT_PREDEPLOY_ADDR));
            return;
        }
        L2TxFeeVault feeVault = new L2TxFeeVault(address(owner), L1_TX_FEE_RECIPIENT_ADDR, 10 ether);

        logAddress("L2_TX_FEE_VAULT_ADDR", address(feeVault));
    }

    function deployL2Whitelist() internal {
        address owner = vm.addr(L2_DEPLOYER_PRIVATE_KEY);
        if (L2_WHITELIST_PREDEPLOY_ADDR != address(0)) {
            if (vm.envUint("IS_SIMULATION") == 1) {
                (, , address txOrigin) = vm.readCallers();
                uint64 originNonce = vm.getNonce(txOrigin);
                vm.stopBroadcast();
                Whitelist tmp = new Whitelist(owner);
                vm.etch(L2_WHITELIST_PREDEPLOY_ADDR, address(tmp).code);
                for (uint256 i = 0; i <= 1; i++) {
                    bytes32 val = vm.load(address(tmp), bytes32(i));
                    if (val != bytes32(0)) {
                        vm.store(L2_WHITELIST_PREDEPLOY_ADDR, bytes32(i), val);
                    }
                }
                vm.setNonce(txOrigin, originNonce);
                vm.startBroadcast();

                logAddress("L2_WHITELIST_ADDR", address(L2_WHITELIST_PREDEPLOY_ADDR));
                return;
            } else {}
        }

        Whitelist whitelist = new Whitelist(owner);
        logAddress("L2_WHITELIST_ADDR", address(whitelist));
    }

    function deployL2ScrollMessenger() internal {
        L2ScrollMessenger impl = new L2ScrollMessenger(L1_SCROLL_MESSENGER_PROXY_ADDR, address(queue));

        logAddress("L2_SCROLL_MESSENGER_IMPLEMENTATION_ADDR", address(impl));
    }

    function deployL2GatewayRouter() internal {
        L2GatewayRouter impl = new L2GatewayRouter();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl),
            address(proxyAdmin),
            new bytes(0)
        );

        logAddress("L2_GATEWAY_ROUTER_IMPLEMENTATION_ADDR", address(impl));
        logAddress("L2_GATEWAY_ROUTER_PROXY_ADDR", address(proxy));

        router = L2GatewayRouter(address(proxy));
    }

    function deployScrollStandardERC20Factory() internal {
        ScrollStandardERC20 tokenImpl = new ScrollStandardERC20();
        factory = new ScrollStandardERC20Factory(address(tokenImpl));

        logAddress("L2_SCROLL_STANDARD_ERC20_ADDR", address(tokenImpl));
        logAddress("L2_SCROLL_STANDARD_ERC20_FACTORY_ADDR", address(factory));
    }

    function deployL2StandardERC20Gateway() internal {
        L2StandardERC20Gateway impl = new L2StandardERC20Gateway(
            L1_STANDARD_ERC20_GATEWAY_PROXY_ADDR,
            address(router),
            L2_SCROLL_MESSENGER_PROXY_ADDR,
            address(factory)
        );

        logAddress("L2_STANDARD_ERC20_GATEWAY_IMPLEMENTATION_ADDR", address(impl));
    }

    function deployL2ETHGateway() internal {
        L2ETHGateway impl = new L2ETHGateway(
            L1_ETH_GATEWAY_PROXY_ADDR,
            address(router),
            L2_SCROLL_MESSENGER_PROXY_ADDR
        );

        logAddress("L2_ETH_GATEWAY_IMPLEMENTATION_ADDR", address(impl));
    }

    function deployL2WETHGateway() internal {
        L2WETHGateway impl = new L2WETHGateway(
            L2_WETH_ADDR,
            L1_WETH_ADDR,
            L1_WETH_GATEWAY_PROXY_ADDR,
            address(router),
            L2_SCROLL_MESSENGER_PROXY_ADDR
        );

        logAddress("L2_WETH_GATEWAY_IMPLEMENTATION_ADDR", address(impl));
    }

    function deployL2CustomERC20Gateway() internal {
        L2CustomERC20Gateway impl = new L2CustomERC20Gateway(
            L1_CUSTOM_ERC20_GATEWAY_PROXY_ADDR,
            address(router),
            L2_SCROLL_MESSENGER_PROXY_ADDR
        );

        logAddress("L2_CUSTOM_ERC20_GATEWAY_IMPLEMENTATION_ADDR", address(impl));
    }

    function deployL2ERC721Gateway() internal {
        L2ERC721Gateway impl = new L2ERC721Gateway(L1_ERC721_GATEWAY_PROXY_ADDR, L2_SCROLL_MESSENGER_PROXY_ADDR);

        logAddress("L2_ERC721_GATEWAY_IMPLEMENTATION_ADDR", address(impl));
    }

    function deployL2ERC1155Gateway() internal {
        L2ERC1155Gateway impl = new L2ERC1155Gateway(L1_ERC1155_GATEWAY_PROXY_ADDR, L2_SCROLL_MESSENGER_PROXY_ADDR);
        logAddress("L2_ERC1155_GATEWAY_IMPLEMENTATION_ADDR", address(impl));
    }
}
