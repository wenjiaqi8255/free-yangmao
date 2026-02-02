#!/bin/bash
#############################################
# Free-Yangmao Pipeline Orchestrator
# 主编排脚本 - 统一的执行入口
#############################################

set -euo pipefail

# 加载配置和库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config.sh"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/utils.sh"

#############################################
# 全局变量
#############################################
PIPELINE_START_TIME=$(date +%s)
STEP_TOTAL=6
STEP_CURRENT=0

#############################################
# 信号处理
#############################################
cleanup() {
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    log_error "Pipeline异常退出 (退出码: $exit_code)"
  fi

  time_execution $PIPELINE_START_TIME

  if [ $exit_code -eq 0 ]; then
    log_notify "Free-Yangmao" "✓ 资源更新完成！"
  else
    log_notify "Free-Yangmao" "✗ 资源更新失败"
  fi

  cleanup_tmp
}

trap cleanup EXIT

#############################################
# 步骤函数
#############################################

# 步骤1: 初始化环境
step_init() {
  ((STEP_CURRENT++))
  log_step $STEP_CURRENT $STEP_TOTAL "初始化环境..."

  ensure_environment
  check_dependencies bash curl jq git || exit 1
  check_internet || exit 1

  log_success "环境初始化完成"
}

# 步骤2: 获取提交历史
step_get_commits() {
  ((STEP_CURRENT++))
  log_step $STEP_CURRENT $STEP_TOTAL "获取提交历史..."

  local url="https://api.github.com/repos/${GITHUB_REPO}/commits?per_page=${PER_PAGE}&since=${SINCE_DATE}"
  local output_file="${DATA_DIR}/recent-commits.txt"

  log_info "查询时间范围: ${SINCE_DATE} 至今"

  if ! safe_curl "$url" | \
    jq -r '.[] | "\(.sha[0:7])|\(.commit.author.date)|\(.commit.message | split("\n")[0])"' \
    > "$output_file"; then
    log_error "获取提交历史失败"
    exit 1
  fi

  local commit_count=$(wc -l < "$output_file" | tr -d ' ')
  log_info "获取到 $commit_count 个提交"
  log_success "提交历史获取完成"
}

# 步骤3: 过滤新增提交
step_filter_additions() {
  ((STEP_CURRENT++))
  log_step $STEP_CURRENT $STEP_TOTAL "过滤新增资源提交..."

  local input_file="${DATA_DIR}/recent-commits.txt"
  local output_file="${DATA_DIR}/additions-commits.txt"

  grep -E "$INCLUDE_KEYWORDS" "$input_file" | \
    grep -vE "$EXCLUDE_KEYWORDS" | \
    head -"$MAX_RESOURCES" > "$output_file" || true

  local addition_count=$(wc -l < "$output_file" | tr -d ' ')
  log_info "筛选出 $addition_count 个新增资源提交"
  log_success "提交过滤完成"
}

# 步骤4: 获取资源详情
step_get_details() {
  ((STEP_CURRENT++))
  log_step $STEP_CURRENT $STEP_TOTAL "获取资源详细信息..."

  local output_file="${DATA_DIR}/resource-details.md"

  echo "# 资源详情" > "$output_file"
  echo "" >> "$output_file"
  echo "**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$output_file"
  echo "**查询范围**: 最近 ${DAYS_AGO} 天" >> "$output_file"
  echo "" >> "$output_file"

  local count=0
  local total=$(wc -l < "${DATA_DIR}/additions-commits.txt" | tr -d ' ')

  while IFS='|' read -r sha date message; do
    ((count++))
    log_debug "处理 [$count/$total]: $message"

    {
      echo "## $message"
      echo "**日期**: $date"
      echo "**提交**: $sha"
      echo ""

      # 获取文件变更（带重试）
      if retry_command 3 2 safe_curl "https://api.github.com/repos/${GITHUB_REPO}/commits/$sha"; then
        local files=$(retry_command 3 2 safe_curl "https://api.github.com/repos/${GITHUB_REPO}/commits/$sha" | \
          jq -r '.files[] | select(.status == "added" or .status == "modified") | "\(.filename): \(.status)"' | \
          head -5)

        if [ -n "$files" ]; then
          echo "$files"
        else
          echo "_无文件变更信息_"
        fi
      else
        echo "_获取详情失败_"
      fi

      echo ""
    } >> "$output_file"

  done < "${DATA_DIR}/additions-commits.txt"

  log_success "资源详情获取完成"
}

# 步骤5: 提取服务内容
step_extract_services() {
  ((STEP_CURRENT++))
  log_step $STEP_CURRENT $STEP_TOTAL "提取服务内容..."

  local repo_dir="${TMP_DIR}/free-for-dev-full"
  local output_file="${DATA_DIR}/extracted-services.txt"

  # 克隆或更新仓库
  if [ ! -d "$repo_dir" ]; then
    log_info "克隆仓库..."
    if ! git clone --depth 1 "https://github.com/${GITHUB_REPO}.git" "$repo_dir" 2>/dev/null; then
      log_warn "仓库克隆失败，跳过服务提取"
      return 0
    fi
  else
    log_info "更新仓库..."
    cd "$repo_dir"
    git fetch origin >/dev/null 2>&1 || true
    git reset --hard origin/master >/dev/null 2>&1 || true
    cd "$PROJECT_ROOT"
  fi

  # 提取服务内容
  echo "# 提取的服务内容" > "$output_file"
  echo "" >> "$output_file"
  echo "**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$output_file"
  echo "" >> "$output_file"

  local count=0
  local total=$(wc -l < "${DATA_DIR}/additions-commits.txt" | tr -d ' ')

  cd "$repo_dir"

  while IFS='|' read -r sha date message; do
    ((count++))
    log_debug "提取 [$count/$total]: $message"

    {
      echo "## $message"
      echo "**日期**: $date"
      echo ""

      # 获取README变更
      local content=$(git show "$sha" -- README.md 2>/dev/null | grep -E "^\+.*\* " | head -10 || echo "_无内容_")

      if [ "$content" != "_无内容_" ]; then
        echo "$content" | sed 's/^\+//'
      else
        echo "$content"
      fi

      echo ""
    } >> "${PROJECT_ROOT}/${output_file}"

  done < "${PROJECT_ROOT}/${DATA_DIR}/additions-commits.txt"

  cd "$PROJECT_ROOT"

  log_success "服务内容提取完成"
}

# 步骤6: 生成最终文档
step_generate_document() {
  ((STEP_CURRENT++))
  log_step $STEP_CURRENT $STEP_TOTAL "生成最终文档..."

  local output_file="${OUTPUT_PATH}"
  local details_file="${DATA_DIR}/resource-details.md"
  local services_file="${DATA_DIR}/extracted-services.txt"

  # 生成文档头部
  cat > "$output_file" << EOF
# Free-for-dev 最新资源

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**查询范围**: 最近 ${DAYS_AGO} 天
**数据来源**: [${GITHUB_REPO}](https://github.com/${GITHUB_REPO})

---

EOF

  # 添加资源详情
  if [ -f "$details_file" ]; then
    cat "$details_file" >> "$output_file"
    echo "" >> "$output_file"
  fi

  # 添加提取的服务
  if [ -f "$services_file" ]; then
    cat "$services_file" >> "$output_file"
  fi

  # 添加文档尾部
  cat >> "$output_file" << EOF

---

**说明**: 本文档由 [Free-Yangmao](https://github.com/YOUR_USERNAME/free-yangmao) 自动生成。
EOF

  local output_size=$(wc -c < "$output_file" | tr -d ' ')
  log_info "文档大小: $(format_size $output_size)"
  log_success "文档生成完成: $output_file"
}

# 步骤7: 链接验证（可选）
step_validate_links() {
  if [ "${ENABLE_LINK_VALIDATION:-false}" != "true" ]; then
    log_debug "链接验证已禁用"
    return 0
  fi

  ((STEP_CURRENT++))
  log_step $STEP_CURRENT $STEP_TOTAL "验证文档链接..."

  local report_file="${DATA_DIR}/link-check-report.txt"

  echo "# 链接验证报告" > "$report_file"
  echo "" >> "$report_file"
  echo "生成时间: $(date)" >> "$report_file"
  echo "" >> "$report_file"

  # 提取所有链接
  local links=$(grep -E "http.*\]" "$OUTPUT_PATH" 2>/dev/null | \
    sed 's/.*\](\(.*\)).*/\1/' | \
    sort -u)

  if [ -z "$links" ]; then
    log_debug "未找到需要验证的链接"
    return 0
  fi

  local total_links=$(echo "$links" | wc -l | tr -d ' ')
  local checked=0
  local failed=0

  echo "$links" | while read url; do
    ((checked++))
    log_debug "检查 [$checked/$total_links]: $url"

    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")

    if echo "$response" | grep -E "^(200|301|302|304)" >/dev/null; then
      echo "✓ $url (HTTP $response)" >> "$report_file"
    else
      echo "✗ $url (HTTP $response)" >> "$report_file"
      ((failed++))
    fi
  done

  log_info "链接验证完成: $total_links 个链接"
  log_success "链接验证报告: $report_file"
}

#############################################
# 主执行流程
#############################################
main() {
  log_info "======================================"
  log_info "Free-Yangmao Pipeline 开始执行"
  log_info "======================================"

  step_init
  step_get_commits
  step_filter_additions
  step_get_details
  step_extract_services
  step_generate_document

  if [ "${ENABLE_LINK_VALIDATION:-false}" = "true" ]; then
    STEP_TOTAL=7
    step_validate_links
  fi

  log_info "======================================"
  log_success "Pipeline 执行完成！"
  log_info "======================================"

  return 0
}

# 执行主函数
main "$@"
