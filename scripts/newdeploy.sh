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

cat config-contracts.toml | grep -v '^\[' | grep -v '^#' | grep '=' | sed 's/^\s*\([A-Z0-9_]*\)\s*=\s*\(.*\)$/export \1=\2/' | sed 's/=\s*"/="/' | sed 's/"\s*$/"/; s/\([^"]\)$/"\1"/' > volume/config-contracts.env

source "volume/config.shell.env"
source "volume/config-contracts.env"
export L1_RPC_ENDPOINT=http://l1-devnet.scrollsdk
export L2_RPC_ENDPOINT=http://l2-rpc.scrollsdk

# 函数：捕获并提取合约地址
extract_addresses() {
    local output=$1
    local pattern="([A-Z0-9_]+)=(0x[a-fA-F0-9]{40})"
    
    echo "$output" | grep -E "=" | grep -E "0x[a-fA-F0-9]{40}" | while read -r line; do
        if [[ $line =~ ([A-Z0-9_]+)=(0x[a-fA-F0-9]{40}) ]]; then
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

# ... existing code ...

echo "🔄 运行: NewDeploy.s.sol:NewDeploy --sig run() --legacy"
forge script scripts/foundry/NewDeploy.s.sol:NewDeploy --sig "run()" --legacy 2>&1

#output2=$(forge script scripts/foundry/NewDeploy.s.sol:NewDeploy --sig "run()" --legacy 2>&1)
// ... existing code ...
#output2=$(forge script scripts/foundry/NewDeploy.s.sol:NewDeploy --sig "run()" --legacy 2>&1)
extract_addresses "$output2"
source "$ADDRESSES_FILE"
