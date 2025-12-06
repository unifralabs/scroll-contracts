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

echo "all configs updated successfully"

gen_config_contracts_toml() {
    config_file="./volume/config.toml"
    gas_token_addr=$(grep -E "^L1_GAS_TOKEN =" "$config_file" | sed 's/ *= */=/' | cut -d'=' -f2-)
    gas_token_enabled=$(grep -E "^ALTERNATIVE_GAS_TOKEN_ENABLED =" "$config_file" | sed 's/ *= */=/' | cut -d'=' -f2-)
    l1_rpc_url=$(grep -E "^L1_RPC_ENDPOINT =" "$config_file" | sed 's/ *= */=/' | cut -d'=' -f2- | sed 's/"//g')

    if [[ "$gas_token_enabled" == "true" && "$gas_token_addr" != "" && "$gas_token_addr" != "0x0000000000000000000000000000000000000000" ]]; then
        echo "gas token enabled and address provided"
        forge script scripts/deterministic/DeployScroll.s.sol:DeployScroll --rpc-url "$l1_rpc_url" --sig "run(string,string)" "none" "write-config" || exit 1
    else
        echo "gas token disabled or address not provided"
        forge script scripts/deterministic/DeployScroll.s.sol:DeployScroll --sig "run(string,string)" "none" "write-config" || exit 1
    fi
}

# format_config_file will add "scrollConfig: |" to the first line and indent the rest
format_config_file() {
    local file="$1"
    local output_file="$2"
    local config_scroll_key="scrollConfig: |"
    
    {
        echo "$config_scroll_key"
        sed 's/^/  /' "$file"
    } > "$output_file"
}

# gen_config_contracts_toml
format_config_file ./volume/config/genesis/config.json ./volume/genesis.yaml
format_config_file ./volume/config/rollup-relayer/config.json ./volume/rollup-config.yaml