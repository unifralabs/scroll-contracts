#!/bin/bash

LOG_LEVEL="-v"

echo ""
echo "generating config-contracts.toml"
forge script scripts/deterministic/scroll/DeployScroll.s.sol:DeployScroll --sig "run(string,string,string)" "./volume" "none" "write-config" $LOG_LEVEL || exit 1

echo ""
echo "updating genesis.yaml"
forge script scripts/deterministic/scroll/GenerateGenesis.s.sol:GenerateGenesis --sig "run(string)" "./volume" $LOG_LEVEL || exit 1

echo ""
echo "updating rollup-config.yaml"
forge script scripts/deterministic/scroll/GenerateConfigs.s.sol:GenerateRollupConfig --sig "run(string)" "./volume" $LOG_LEVEL || exit 1

echo ""
echo "updating coordinator-config.yaml"
forge script scripts/deterministic/scroll/GenerateConfigs.s.sol:GenerateCoordinatorConfig --sig "run(string)" "./volume" $LOG_LEVEL || exit 1

echo ""
echo "updating chain-monitor-config.yaml"
forge script scripts/deterministic/scroll/GenerateConfigs.s.sol:GenerateChainMonitorConfig --sig "run(string)" "./volume" $LOG_LEVEL || exit 1
echo ""
echo "updating bridge-history-config.yaml"
forge script scripts/deterministic/scroll/GenerateConfigs.s.sol:GenerateBridgeHistoryConfig --sig "run(string)" "./volume" $LOG_LEVEL || exit 1
echo ""
echo "updating balance-checker-config.yaml"
forge script scripts/deterministic/scroll/GenerateConfigs.s.sol:GenerateBalanceCheckerConfig --sig "run(string)" "./volume" $LOG_LEVEL || exit 1