#!/bin/bash
set -e

echo "=== SCROLL CONTRACT DEPLOYMENT SCRIPT ==="

# 设置环境变量
export FOUNDRY_EVM_VERSION="cancun"
export FOUNDRY_BYTECODE_HASH="none"
export BATCH_SIZE=100

export NETWORK="sepolia"

# 显示配置信息
echo "配置信息:"
echo "- FOUNDRY_EVM_VERSION: $FOUNDRY_EVM_VERSION"
echo "- FOUNDRY_BYTECODE_HASH: $FOUNDRY_BYTECODE_HASH"
echo "- BATCH_SIZE: $BATCH_SIZE"
echo "- L1_RPC_ENDPOINT: $L1_RPC_ENDPOINT"
echo "- L2_RPC_ENDPOINT: $L2_RPC_ENDPOINT"
echo "- NETWORK: $NETWORK"
echo ""

# 创建地址配置文件
ADDRESSES_FILE="volume/generated_addresses.env"
echo "# Auto-generated contract addresses" > $ADDRESSES_FILE

# 处理配置文件
yq -p=toml -o=props "volume/config.toml" > "volume/config.env"
cat volume/config.env | sed 's/.*\.\([^.]*\) = /\1=/' | grep -v "^$" | sed 's/^/export /' > volume/config.shell.env

cat volume/config-contracts.toml | grep -v '^\[' | grep -v '^#' | grep '=' | sed 's/^\s*\([A-Z0-9_]*\)\s*=\s*\(.*\)$/export \1=\2/' | sed 's/=\s*"/="/' | sed 's/"\s*$/"/; s/\([^"]\)$/"\1"/' > volume/config-contracts.env

source "volume/config.shell.env"
source "volume/config-contracts.env"
export L1_RPC_ENDPOINT=http://l1-devnet.scrollsdk
export L2_RPC_ENDPOINT=http://l2-rpc.scrollsdk

# 函数：捕获并提取合约地址
extract_addresses() {
    local output=$1
    local pattern="([A-Z0-9_]+)=(0x[a-fA-F0-9]{40})"
    
    echo "$output" | grep -E "=" | grep -E "0x[a-fA-F0-9]{40}" | while read -r line; do
        if [[ $line =~ $pattern ]]; then
            local name="${BASH_REMATCH[1]}"
            local address="${BASH_REMATCH[2]}"
            
            # 导出到当前会话
            export "$name"="$address"
            
            # 添加到地址文件
            echo "export $name=\"$address\"" >> $ADDRESSES_FILE
            
            echo "✅ 已导出: $name=$address"
        fi
    done
}

# 运行单个脚本函数
run_script() {
    local script=$1
    local rpc_url=$2
    local broadcast=${3:-false}
    
    echo "🔄 运行: $script (连接: $rpc_url)"
    
    local broadcast_flag=""
    if [ "$broadcast" = "true" ]; then
        broadcast_flag="--broadcast"
    fi
    
    local output
    if output=$(forge script "scripts/foundry/$script" --rpc-url "$rpc_url" --sig "run()" --legacy $broadcast_flag 2>&1); then
        extract_addresses "$output"
        source "$ADDRESSES_FILE"
        echo "✅ 成功执行: $script"
        echo ""
    else
        echo "❌ 错误: $script 执行失败"
        echo "$output"
        exit 1
    fi
}

# 显示捕获的地址
display_captured_addresses() {
    echo "=== 捕获的合约地址 ==="
    if [ -f "$ADDRESSES_FILE" ]; then
        cat "$ADDRESSES_FILE"
    else
        echo "地址文件不存在!"
    fi
    echo ""
}

# 主函数
main() {
    echo "=== 开始执行模拟部署 ==="
    run_script "DeployAll.s.sol:DeployAll" "$L2_RPC_ENDPOINT"

    # run_script "DeployL2ScrollOwner.s.sol:DeployL2ScrollOwner" "$L2_RPC_ENDPOINT"
    # run_script "DeployL1ScrollOwner.s.sol:DeployL1ScrollOwner" "$L1_RPC_ENDPOINT"

    # run_script "DeployFallbackContracts.s.sol:DeployFallbackContracts" "$L1_RPC_ENDPOINT"

    # run_script "DeployL2BridgeProxyPlaceholder.s.sol:DeployL2BridgeProxyPlaceholder" "$L2_RPC_ENDPOINT"
    # run_script "DeployL1BridgeProxyPlaceholder.s.sol:DeployL1BridgeProxyPlaceholder" "$L1_RPC_ENDPOINT"

    # run_script "DeployL2Weth.s.sol:DeployL2Weth" "$L2_RPC_ENDPOINT"
    # run_script "DeployWeth.s.sol:DeployWeth" "$L1_RPC_ENDPOINT"

    # run_script "DeployL2BridgeContracts.s.sol:DeployL2BridgeContracts" "$L2_RPC_ENDPOINT"
    # run_script "DeployL1BridgeContracts.s.sol:DeployL1BridgeContracts" "$L1_RPC_ENDPOINT"
    
    # run_script "DeployLidoGateway.s.sol:DeployLidoGateway" "$L2_RPC_ENDPOINT"
    # run_script "DeployScrollChainCommitmentVerifier.s.sol:DeployScrollChainCommitmentVerifier" "$L2_RPC_ENDPOINT"
    
    # run_script "InitializeL1BridgeContracts.s.sol:InitializeL1BridgeContracts" "$L1_RPC_ENDPOINT"
    # run_script "InitializeL1ScrollOwner.s.sol:InitializeL1ScrollOwner" "$L1_RPC_ENDPOINT"
    # run_script "InitializeL2BridgeContracts.s.sol:InitializeL2BridgeContracts" "$L2_RPC_ENDPOINT"
    # run_script "InitializeL2ScrollOwner.s.sol:InitializeL2ScrollOwner" "$L2_RPC_ENDPOINT"
    
    # 显示所有捕获的地址
    display_captured_addresses
    
    echo "=== 模拟部署完成 ==="
    
    # # 取消注释以执行广播部署
    # echo "=== 开始执行广播部署 ==="
    # 
    # run_script "DeployL2ScrollOwner.s.sol:DeployL2ScrollOwner" "$L2_RPC_ENDPOINT" "true"
    # run_script "DeployL2BridgeProxyPlaceholder.s.sol:DeployL2BridgeProxyPlaceholder" "$L2_RPC_ENDPOINT" "true"
    # 
    # run_script "DeployL1ScrollOwner.s.sol:DeployL1ScrollOwner" "$L1_RPC_ENDPOINT" "true"
    # run_script "DeployL1BridgeProxyPlaceholder.s.sol:DeployL1BridgeProxyPlaceholder" "$L1_RPC_ENDPOINT" "true"
    # run_script "DeployFallbackContracts.s.sol:DeployFallbackContracts" "$L1_RPC_ENDPOINT" "true"
    # run_script "DeployL1BridgeContracts.s.sol:DeployL1BridgeContracts" "$L1_RPC_ENDPOINT" "true"
    # 
    # run_script "DeployWeth.s.sol:DeployWeth" "$L2_RPC_ENDPOINT" "true"
    # run_script "DeployL2BridgeContracts.s.sol:DeployL2BridgeContracts" "$L2_RPC_ENDPOINT" "true"
    # run_script "DeployLidoGateway.s.sol:DeployLidoGateway" "$L2_RPC_ENDPOINT" "true"
    # run_script "DeployScrollChainCommitmentVerifier.s.sol:DeployScrollChainCommitmentVerifier" "$L2_RPC_ENDPOINT" "true"
    # 
    # run_script "InitializeL1BridgeContracts.s.sol:InitializeL1BridgeContracts" "$L1_RPC_ENDPOINT" "true"
    # run_script "InitializeL1ScrollOwner.s.sol:InitializeL1ScrollOwner" "$L1_RPC_ENDPOINT" "true"
    # run_script "InitializeL2BridgeContracts.s.sol:InitializeL2BridgeContracts" "$L2_RPC_ENDPOINT" "true"
    # run_script "InitializeL2ScrollOwner.s.sol:InitializeL2ScrollOwner" "$L2_RPC_ENDPOINT" "true"
    # 
    # echo "=== 广播部署完成 ==="
}

# 执行主函数
main