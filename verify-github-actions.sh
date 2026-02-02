#!/bin/bash
#############################################
# GitHub Actions 验证脚本
# 用于测试和验证GitHub Actions配置
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}" && pwd)"

echo "======================================"
echo "GitHub Actions 配置验证"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_pass() {
  echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
  echo -e "${RED}✗${NC} $1"
}

check_info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

# ========================================
# 检查1: Workflow文件
# ========================================
echo "1. 检查GitHub Actions配置文件..."
echo ""

WORKFLOW_FILE=".github/workflows/update-resources.yml"

if [ -f "$WORKFLOW_FILE" ]; then
  check_pass "Workflow文件存在: $WORKFLOW_FILE"
else
  check_fail "Workflow文件不存在: $WORKFLOW_FILE"
  exit 1
fi

# ========================================
# 检查2: Cron表达式
# ========================================
echo ""
echo "2. 验证Cron表达式..."
echo ""

# 检查cron表达式
CRON_EXPR=$(grep "^ *- cron:" "$WORKFLOW_FILE" | head -1 | sed 's/.*cron: *//; s/.*$//')
EXPECTED_CRON="'0 1 */2 * *'"  # 每2天UTC 1点

if [ "$CRON_EXPR" = "$EXPECTED_CRON" ]; then
  check_pass "Cron表达式正确: $CRON_EXPR"
  check_info "  说明: 每2天UTC 1:00执行（北京时间9:00）"
else
  check_fail "Cron表达式不匹配"
  check_info "  当前: $CRON_EXPR"
  check_info "  期望: $EXPECTED_CRON"
fi

# ========================================
# 检查3: 功能配置
# ========================================
echo ""
echo "3. 检查功能配置..."
echo ""

# 检查历史记录配置
if grep -q "ENABLE_HISTORY: *true" "$WORKFLOW_FILE"; then
  check_pass "历史记录已启用"
else
  check_info "历史记录: 通过输入参数控制"
fi

# 检查去重配置
if grep -q "ENABLE_DEDUP: *true" "$WORKFLOW_FILE"; then
  check_pass "去重功能已启用"
else
  check_info "去重功能: 通过输入参数控制"
fi

# 检查链接验证（应该禁用以加快速度）
if grep -q "ENABLE_LINK_VALIDATION: *false" "$WORKFLOW_FILE"; then
  check_pass "链接验证已禁用（优化性能）"
else
  check_info "链接验证状态: 需要检查"
fi

# ========================================
# 检查4: 环境变量
# ========================================
echo ""
echo "4. 检查关键环境变量..."
echo ""

required_vars=(
  "LOG_LEVEL"
  "ENABLE_FILE_LOG"
  "DAYS_AGO"
  "MAX_RESOURCES"
)

for var in "${required_vars[@]}"; do
  if grep -q "$var:" "$WORKFLOW_FILE"; then
    check_pass "环境变量已配置: $var"
  else
    check_fail "环境变量缺失: $var"
  fi
done

# ========================================
# 检查5: 步骤完整性
# ========================================
echo ""
echo "5. 检查Workflow步骤..."
echo ""

required_steps=(
  "Checkout repository"
  "Setup dependencies"
  "Verify dependencies"
  "Make scripts executable"
  "Create necessary directories"
  "Display configuration"
  "Run update pipeline"
  "Check output"
  "Get current date"
  "Generate workflow summary"
  "Commit changes"
  "Upload logs"
  "Upload output"
  "Notify on failure"
)

for step in "${required_steps[@]}"; do
  if grep -q "name: $step" "$WORKFLOW_FILE"; then
    check_pass "步骤存在: $step"
  else
    check_info "步骤缺失: $step"
  fi
done

# ========================================
# 检查6: 安全性
# ========================================
echo ""
echo "6. 安全性检查..."
echo ""

# 检查超时设置
if grep -q "timeout-minutes: 15" "$WORKFLOW_FILE"; then
  check_pass "超时设置正确: 15分钟"
else
  check_fail "缺少超时设置"
fi

# 检查权限
if grep -q "GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN \}\}" "$WORKFLOW_FILE"; then
  check_pass "GitHub Token配置正确"
else
  check_fail "GitHub Token配置错误"
fi

# ========================================
# 检查7: 手动触发配置
# ========================================
echo ""
echo "7. 手动触发配置..."
echo ""

if grep -q "workflow_dispatch:" "$WORKFLOW_FILE"; then
  check_pass "手动触发已配置"

  echo ""
  check_info "可用的输入参数:"
  grep -A 10 "workflow_dispatch:" "$WORKFLOW_FILE" | grep "description:" | sed 's/.*description: //' | head -4
else
  check_fail "手动触发未配置"
fi

# ========================================
# 检查8: 提交配置
# ========================================
echo ""
echo "8. 自动提交配置..."
echo ""

if grep -q "Commit changes" "$WORKFLOW_FILE"; then
  check_pass "自动提交步骤存在"

  # 检查提交逻辑
  if grep -q "git config --local" "$WORKFLOW_FILE"; then
    check_pass "Git配置正确"
  fi

  if grep -q "git push" "$WORKFLOW_FILE"; then
    check_pass "自动推送配置正确"
  fi

  # 检查智能提交消息
  if grep -q "无新内容" "$WORKFLOW_FILE"; then
    check_pass "智能提交消息已配置（去重优化）"
  fi
else
  check_fail "自动提交步骤缺失"
fi

# ========================================
# 检查9: Artifact上传
# ========================================
echo ""
echo "9. Artifact上传配置..."
echo ""

artifacts=(
  "workflow-logs"
  "free-resources"
)

for artifact in "${artifacts[@]}"; do
  if grep -q "name: $artifact" "$WORKFLOW_FILE"; then
    check_pass "Artifact配置存在: $artifact"

    # 检查保留期
    if grep -q "retention-days:" "$WORKFLOW_FILE"; then
      check_pass "配置了保留期（自动清理）"
    fi
  else
    check_info "Artifact缺失: $artifact"
  fi
done

# ========================================
# 检查10: 本地脚本兼容性
# ========================================
echo ""
echo "10. 本地脚本兼容性测试..."
echo ""

# 检查脚本是否可执行
if [ -x "$PROJECT_ROOT/update.sh" ]; then
  check_pass "update.sh 可执行"
else
  check_info "update.sh 不可执行（将尝试在Actions中修复）"
fi

# 检查pipeline脚本
if [ -x "$PROJECT_ROOT/scripts/run-pipeline.sh" ]; then
  check_pass "run-pipeline.sh 可执行"
else
  check_info "run-pipeline.sh 不可执行（将尝试在Actions中修复）"
fi

# 检查库模块
if [ -f "$PROJECT_ROOT/scripts/lib/dedup.sh" ] && [ -f "$PROJECT_ROOT/scripts/lib/history.sh" ]; then
  check_pass "新功能模块存在"

  # 测试加载
  if bash -c "source '$PROJECT_ROOT/config.sh'; source '$PROJECT_ROOT/scripts/lib/dedup.sh'; source '$PROJECT_ROOT/scripts/lib/history.sh'; echo 'OK'" 2>/dev/null | grep -q "OK"; then
    check_pass "新功能模块可正常加载"
  else
    check_fail "新功能模块加载失败"
  fi
else
  check_fail "新功能模块缺失"
fi

# ========================================
# 测试建议
# ========================================
echo ""
echo "======================================"
echo "测试建议"
echo "======================================"
echo ""

echo "🔹 本地测试:"
echo "  1. 模拟GitHub Actions环境:"
echo "     export LOG_LEVEL=INFO"
echo "     export ENABLE_HISTORY=true"
echo "     export ENABLE_DEDUP=true"
echo "     export ENABLE_LINK_VALIDATION=false"
echo "     bash scripts/run-pipeline.sh"
echo ""
echo "  2. 验证输出:"
echo "     - docs/free-for-dev-最新资源.md 是否生成"
echo "     - docs/history/index.md 是否更新"
echo "     - data/processed-commits.json 是否正确"
echo ""

echo "🔹 GitHub Actions测试:"
echo "  1. 手动触发测试:"
echo "     gh workflow run update-resources.yml"
echo ""
echo "  2. 带参数测试:"
echo "     gh workflow run update-resources.yml -f enable_history=true -f enable_dedup=true"
echo ""
echo "  3. 查看运行结果:"
echo "     gh run list --workflow=update-resources.yml"
echo ""

echo "🔹 监控要点:"
echo "  ✓ 每2天UTC 1:00（北京时间9:00）自动运行"
echo "  ✓ 检查Actions标签页的运行历史"
echo "  ✓ 查看artifact下载（日志和输出文件）"
echo "  ✓ 监控提交记录（应该每2天一次）"
echo ""

echo "🔹 优化建议:"
echo "  ✓ 已禁用链接验证（加快执行速度）"
echo "  ✓ 已配置15分钟超时（防止挂起）"
echo "  ✓ 已配置智能提交消息（去重优化）"
echo "  ✓ 已配置artifact自动清理（节省空间）"
echo ""

echo "======================================"