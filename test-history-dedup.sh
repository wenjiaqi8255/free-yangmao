#!/bin/bash
#############################################
# Test script for history and deduplication features
# 测试历史记录和去重功能
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}" && pwd)"

echo "======================================"
echo "测试历史记录和去重功能"
echo "======================================"
echo ""

# 测试1: 仅启用历史记录
echo "测试1: 启用历史记录..."
ENABLE_HISTORY=true bash "${PROJECT_ROOT}/scripts/run-pipeline.sh"

echo ""
echo "检查生成的文件:"
echo "- 历史文档: $(ls -1 "${PROJECT_ROOT}/docs/history"/202*/*.md 2>/dev/null | head -1 || echo "无")"
echo "- 历史索引: ${PROJECT_ROOT}/docs/history/index.md"
echo ""

# 测试2: 启用去重
echo "测试2: 启用去重功能（应该跳过生成）..."
ENABLE_DEDUP=true ENABLE_HISTORY=false bash "${PROJECT_ROOT}/scripts/run-pipeline.sh"

echo ""
echo "检查去重记录:"
cat "${PROJECT_ROOT}/data/processed-commits.json" 2>/dev/null | jq '.last_run' || echo "无去重记录"
echo ""

# 测试3: 同时启用两者
echo "测试3: 同时启用历史和去重..."
ENABLE_HISTORY=true ENABLE_DEDUP=true bash "${PROJECT_ROOT}/scripts/run-pipeline.sh"

echo ""
echo "======================================"
echo "测试完成！"
echo "======================================"
echo ""
echo "生成的文件:"
echo "1. 历史文档目录: ${PROJECT_ROOT}/docs/history/"
echo "2. 去重记录: ${PROJECT_ROOT}/data/processed-commits.json"
echo "3. 历史索引: ${PROJECT_ROOT}/docs/history/index.md"
echo ""
echo "查看历史统计:"
echo "  bash ${PROJECT_ROOT}/scripts/lib/history.sh (需要修改以支持独立运行)"
echo ""
