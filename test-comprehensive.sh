#!/bin/bash
#############################################
# Comprehensive Test for History and Deduplication
# 全面测试历史记录和去重功能
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}" && pwd)"

echo "======================================"
echo "Free-Yangmao 功能测试"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# 测试辅助函数
test_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  ((TESTS_FAILED++))
}

test_info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# 清理函数
cleanup() {
  echo ""
  echo "======================================"
  echo "测试清理..."
  echo "======================================"
  
  # 备份测试结果
  if [ -d "${PROJECT_ROOT}/docs/history" ]; then
    echo "历史文档目录存在: ✓"
  fi
  
  if [ -f "${PROJECT_ROOT}/data/processed-commits.json" ]; then
    echo "去重记录文件存在: ✓"
  fi
}

trap cleanup EXIT

#############################################
# 测试1: 检查新模块存在
#############################################
echo "测试1: 检查新增模块文件..."
echo ""

modules=(
  "scripts/lib/dedup.sh"
  "scripts/lib/history.sh"
)

for module in "${modules[@]}"; do
  if [ -f "${PROJECT_ROOT}/${module}" ]; then
    test_pass "模块存在: ${module}"
  else
    test_fail "模块缺失: ${module}"
  fi
done

#############################################
# 测试2: 检查配置参数
#############################################
echo ""
echo "测试2: 检查配置参数..."
echo ""

# Source config to check variables
source "${PROJECT_ROOT}/config.sh"

required_vars=(
  "ENABLE_HISTORY"
  "HISTORY_RETENTION_DAYS"
  "AUTO_UPDATE_INDEX"
  "HISTORY_DIR"
  "ENABLE_DEDUP"
  "DEDUP_MODE"
  "NOTIFY_NO_NEW_CONTENT"
)

for var in "${required_vars[@]}"; do
  if [ -n "${!var:-}" ]; then
    test_pass "配置变量存在: ${var}=${!var}"
  else
    test_fail "配置变量缺失: ${var}"
  fi
done

#############################################
# 测试3: 检查默认值（向后兼容）
#############################################
echo ""
echo "测试3: 检查默认值（向后兼容）..."
echo ""

if [ "${ENABLE_HISTORY:-false}" = "false" ]; then
  test_pass "ENABLE_HISTORY 默认为 false（向后兼容）"
else
  test_fail "ENABLE_HISTORY 默认值错误"
fi

if [ "${ENABLE_DEDUP:-false}" = "false" ]; then
  test_pass "ENABLE_DEDUP 默认为 false（向后兼容）"
else
  test_fail "ENABLE_DEDUP 默认值错误"
fi

#############################################
# 测试4: 检查文档文件
#############################################
echo ""
echo "测试4: 检查文档文件..."
echo ""

docs=(
  "docs/HISTORY_DEDUP.md"
  "HISTORY_DEDUP_IMPLEMENTATION.md"
)

for doc in "${docs[@]}"; do
  if [ -f "${PROJECT_ROOT}/${doc}" ]; then
    test_pass "文档存在: ${doc}"
  else
    test_fail "文档缺失: ${doc}"
  fi
done

#############################################
# 测试5: 测试历史目录结构
#############################################
echo ""
echo "测试5: 测试历史目录结构..."
echo ""

if [ -d "${PROJECT_ROOT}/docs/history" ]; then
  test_pass "历史目录存在: docs/history"
  
  # 检查.gitkeep
  if [ -f "${PROJECT_ROOT}/docs/history/.gitkeep" ]; then
    test_pass "历史目录 .gitkeep 存在"
  fi
  
  # 检查是否有年份子目录
  year_dirs=$(find "${PROJECT_ROOT}/docs/history" -type d -name "20*" 2>/dev/null | wc -l)
  if [ "$year_dirs" -gt 0 ]; then
    test_pass "年份子目录存在 (${year_dirs} 个)"
  fi
else
  test_fail "历史目录不存在"
fi

#############################################
# 测试6: 检查历史索引
#############################################
echo ""
echo "测试6: 检查历史索引..."
echo ""

INDEX_FILE="${PROJECT_ROOT}/docs/history/index.md"

if [ -f "$INDEX_FILE" ]; then
  test_pass "历史索引文件存在"
  
  # 检查索引内容
  if grep -q "统计信息" "$INDEX_FILE"; then
    test_pass "索引包含统计信息"
  fi
  
  if grep -q "历史文档列表" "$INDEX_FILE"; then
    test_pass "索引包含文档列表"
  fi
else
  test_info "历史索引文件不存在（可能尚未运行）"
fi

#############################################
# 测试7: 检查去重记录文件
#############################################
echo ""
echo "测试7: 检查去重记录文件..."
echo ""

DEDUP_FILE="${PROJECT_ROOT}/data/processed-commits.json"

if [ -f "$DEDUP_FILE" ]; then
  test_pass "去重记录文件存在"
  
  # 检查是否为有效JSON
  if jq empty "$DEDUP_FILE" 2>/dev/null; then
    test_pass "去重记录是有效JSON"
    
    # 检查必需字段
    if jq -e '.version' "$DEDUP_FILE" >/dev/null 2>&1; then
      test_pass "去重记录包含 version 字段"
    fi
    
    if jq -e '.last_run' "$DEDUP_FILE" >/dev/null 2>&1; then
      test_pass "去重记录包含 last_run 字段"
    fi
  else
    test_fail "去重记录不是有效JSON"
  fi
else
  test_info "去重记录文件不存在（可能尚未运行）"
fi

#############################################
# 测试8: 检查测试脚本
#############################################
echo ""
echo "测试8: 检查测试脚本..."
echo ""

if [ -f "${PROJECT_ROOT}/test-history-dedup.sh" ]; then
  test_pass "测试脚本存在"
  
  # 检查是否可执行
  if [ -x "${PROJECT_ROOT}/test-history-dedup.sh" ]; then
    test_pass "测试脚本可执行"
  else
    test_fail "测试脚本不可执行"
  fi
else
  test_fail "测试脚本不存在"
fi

#############################################
# 测试9: 模块功能测试
#############################################
echo ""
echo "测试9: 模块功能测试..."
echo ""

# 测试dedup模块加载
test_info "测试 dedup.sh 模块加载..."
if bash -c "source '${PROJECT_ROOT}/config.sh'; source '${PROJECT_ROOT}/scripts/lib/logger.sh'; source '${PROJECT_ROOT}/scripts/lib/dedup.sh'; echo 'loaded'" 2>/dev/null | grep -q "loaded"; then
  test_pass "dedup.sh 模块可以正常加载"
else
  test_fail "dedup.sh 模块加载失败"
fi

# 测试history模块加载
test_info "测试 history.sh 模块加载..."
if bash -c "source '${PROJECT_ROOT}/config.sh'; source '${PROJECT_ROOT}/scripts/lib/logger.sh'; source '${PROJECT_ROOT}/scripts/lib/history.sh'; echo 'loaded'" 2>/dev/null | grep -q "loaded"; then
  test_pass "history.sh 模块可以正常加载"
else
  test_fail "history.sh 模块加载失败"
fi

#############################################
# 测试10: 检查quick reference更新
#############################################
echo ""
echo "测试10: 检查 QUICK_REFERENCE.md 更新..."
echo ""

if grep -q "历史记录功能" "${PROJECT_ROOT}/QUICK_REFERENCE.md"; then
  test_pass "QUICK_REFERENCE.md 包含历史记录介绍"
fi

if grep -q "去重功能" "${PROJECT_ROOT}/QUICK_REFERENCE.md"; then
  test_pass "QUICK_REFERENCE.md 包含去重功能介绍"
fi

if grep -q "HISTORY_DEDUP" "${PROJECT_ROOT}/QUICK_REFERENCE.md"; then
  test_pass "QUICK_REFERENCE.md 包含新功能文档链接"
fi

#############################################
# 测试11: 文件内容验证
#############################################
echo ""
echo "测试11: 文件内容验证..."
echo ""

# 检查dedup.sh关键函数
DEDUP_FILE="${PROJECT_ROOT}/scripts/lib/dedup.sh"
required_functions=(
  "init_processed_commits"
  "load_processed_commits"
  "check_new_content"
  "update_processed_commits"
)

for func in "${required_functions[@]}"; do
  if grep -q "^${func}()" "$DEDUP_FILE"; then
    test_pass "dedup.sh 包含函数: ${func}"
  else
    test_fail "dedup.sh 缺失函数: ${func}"
  fi
done

# 检查history.sh关键函数
HISTORY_FILE="${PROJECT_ROOT}/scripts/lib/history.sh"
history_functions=(
  "init_history_dir"
  "generate_history_document"
  "update_history_index"
  "cleanup_old_history"
)

for func in "${history_functions[@]}"; do
  if grep -q "^${func}()" "$HISTORY_FILE"; then
    test_pass "history.sh 包含函数: ${func}"
  else
    test_fail "history.sh 缺失函数: ${func}"
  fi
done

#############################################
# 测试总结
#############################################
echo ""
echo "======================================"
echo "测试总结"
echo "======================================"
echo ""
echo -e "${GREEN}通过测试: ${TESTS_PASSED}${NC}"
echo -e "${RED}失败测试: ${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ 所有测试通过！${NC}"
  exit 0
else
  echo -e "${RED}✗ 有 ${TESTS_FAILED} 个测试失败${NC}"
  exit 1
fi
