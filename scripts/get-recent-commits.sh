#!/bin/bash
# 获取原始仓库最近3个月的提交历史

# 加载配置和日志库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config.sh"
source "${SCRIPT_DIR}/lib/logger.sh"

# 设置 GitHub Token (如果有)
# GITHUB_TOKEN="${GITHUB_TOKEN:-}"
API_URL="https://api.github.com/repos/ripienaar/free-for-dev/commits?per_page=100"

# 计算日期范围（3个月前）
SINCE_DATE=$(date -d "90 days ago" +%Y-%m-%d 2>/dev/null || date -v-90d +%Y-%m-%d 2>/dev/null || echo "2024-11-01")

# 构建完整的URL
FULL_URL="${API_URL}&since=${SINCE_DATE}"

log_info "正在获取提交历史..."
log_debug "API URL: $FULL_URL"

# 使用 curl 获取数据，添加认证以提高速率限制
if [ -n "${GITHUB_TOKEN:-}" ]; then
  RESPONSE=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$FULL_URL")
else
  log_warning "未设置 GITHUB_TOKEN，可能遇到速率限制"
  RESPONSE=$(curl -s "$FULL_URL")
fi

# 检查是否遇到速率限制
if echo "$RESPONSE" | jq -e '.message' | grep -q "rate limit"; then
  log_error "GitHub API 速率限制已超出"
  log_error "请设置 GITHUB_TOKEN 环境变量以提高速率限制"
  log_info "获取方法: https://github.com/settings/tokens"
  exit 1
fi

# 检查响应是否有效
if ! echo "$RESPONSE" | jq -e '.[0].sha' >/dev/null 2>&1; then
  log_error "GitHub API 响应格式错误"
  log_debug "响应内容: $(echo "$RESPONSE" | head -c 200)"
  exit 1
fi

# 解析并保存提交信息
echo "$RESPONSE" | jq -r '.[] | "\(.sha[0:7])|\(.commit.author.date)|\(.commit.message | split("\n")[0])"' \
  > "${DATA_DIR}/recent-commits.txt"

if [ $? -ne 0 ]; then
  log_error "解析提交数据失败"
  exit 1
fi

# 统计提交数量
COMMIT_COUNT=$(wc -l < "${DATA_DIR}/recent-commits.txt" | tr -d ' ')
log_success "成功获取 ${COMMIT_COUNT} 个提交"
