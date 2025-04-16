#!/bin/bash
set -e

echo "=== SCROLL CONTRACT DEPLOYMENT SCRIPT ==="

# 设置环境变量
export FOUNDRY_EVM_VERSION="cancun"
export FOUNDRY_BYTECODE_HASH="none"

export L1_RPC_ENDPOINT=http://l1-devnet.scrollsdk
export L2_RPC_ENDPOINT=http://l2-rpc.scrollsdk
export BATCH_SIZE=100

# 显示配置信息
echo "配置信息:"
echo "- BATCH_SIZE: $BATCH_SIZE"
echo "- L1_RPC_ENDPOINT: $L1_RPC_ENDPOINT"
echo "- L2_RPC_ENDPOINT: $L2_RPC_ENDPOINT"
echo "- NETWORK: $NETWORK"
echo ""

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
cp -f .env.example .env
forege_cmd="forge script scripts/foundry/NewDeploy.s.sol:NewDeploy --sig run() --legacy -- --env-file ./.env"
echo "🔄 运行: $forege_cmd"
$forege_cmd 2>&1

#output2=$(forge script scripts/foundry/NewDeploy.s.sol:NewDeploy --sig "run()" --legacy 2>&1)
// ... existing code ...
#output2=$(forge script scripts/foundry/NewDeploy.s.sol:NewDeploy --sig "run()" --legacy 2>&1)
extract_addresses "$output2"
source "$ADDRESSES_FILE"
