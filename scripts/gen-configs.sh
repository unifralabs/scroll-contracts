#!/bin/bash
export FOUNDRY_EVM_VERSION="cancun"
export FOUNDRY_BYTECODE_HASH="none"

# the deployment of the L1GasTokenGateway implementation necessitates fetching the gas token decimal
# in this case it requires the context of layer 1
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

forge script scripts/foundry/DeployAll.s.sol:DeployAll || exit 1


# echo ""
# echo "generating rollup-config.yaml"
# forge script scripts/deterministic/GenerateConfigs.s.sol:GenerateRollupConfig || exit 1
# format_config_file "./volume/rollup-config.yaml"
