#!/bin/bash
#############################################
# Free-Yangmao Deduplication Module
# 去重逻辑模块 - 基于提交SHA判断是否有新内容
#############################################

#=========== 配置 ============
PROCESSED_COMMITS_FILE="${DATA_DIR}/processed-commits.json"

#############################################
# 工具函数
#############################################

# 初始化已处理提交记录文件
init_processed_commits() {
  if [ ! -f "$PROCESSED_COMMITS_FILE" ]; then
    log_info "初始化去重记录文件..."
    cat > "$PROCESSED_COMMITS_FILE" << 'EOF'
{
  "version": "1.0",
  "last_updated": null,
  "processed_shas": {},
  "last_run": {
    "timestamp": null,
    "latest_sha": null,
    "commit_count": 0
  }
}
EOF
    log_debug "已创建: $PROCESSED_COMMITS_FILE"
  fi
}

# 加载已处理提交记录
load_processed_commits() {
  init_processed_commits

  if [ ! -f "$PROCESSED_COMMITS_FILE" ]; then
    log_error "无法初始化去重记录文件"
    return 1
  fi

  # 验证JSON格式
  if ! jq empty "$PROCESSED_COMMITS_FILE" 2>/dev/null; then
    log_warn "去重记录文件格式错误，重新初始化..."
    rm -f "$PROCESSED_COMMITS_FILE"
    init_processed_commits
  fi

  return 0
}

# 获取上次处理的提交SHA
get_last_processed_sha() {
  if [ ! -f "$PROCESSED_COMMITS_FILE" ]; then
    echo ""
    return
  fi

  jq -r '.last_run.latest_sha // ""' "$PROCESSED_COMMITS_FILE"
}

# 检查是否有新内容
# 返回: 0=有新内容, 1=无新内容
check_new_content() {
  local current_commits_file="${DATA_DIR}/recent-commits.txt"

  if [ ! -f "$current_commits_file" ]; then
    log_error "提交文件不存在: $current_commits_file"
    return 1
  fi

  # 获取当前最新提交SHA
  local current_latest_sha=$(head -1 "$current_commits_file" | cut -d'|' -f1)

  if [ -z "$current_latest_sha" ]; then
    log_warn "未找到任何提交"
    return 1
  fi

  # 获取上次处理的SHA
  local last_processed_sha=$(get_last_processed_sha)

  if [ -z "$last_processed_sha" ]; then
    log_info "首次运行，将处理所有提交"
    return 0
  fi

  # 比较SHA
  if [ "$current_latest_sha" = "$last_processed_sha" ]; then
    log_info "当前最新提交与上次相同: $current_latest_sha"

    # 检查是否有新增提交
    local commit_count=$(wc -l < "$current_commits_file" | tr -d ' ')
    local last_commit_count=$(jq -r '.last_run.commit_count // 0' "$PROCESSED_COMMITS_FILE")

    if [ "$commit_count" -le "$last_commit_count" ]; then
      log_info "没有新提交需要处理"
      return 1
    else
      log_info "检测到 $((commit_count - last_commit_count)) 个新提交"
      return 0
    fi
  fi

  log_info "检测到新提交: $current_latest_sha (上次: $last_processed_sha)"
  return 0
}

# 更新已处理提交记录
update_processed_commits() {
  local current_commits_file="${DATA_DIR}/recent-commits.txt"

  if [ ! -f "$current_commits_file" ]; then
    log_error "提交文件不存在: $current_commits_file"
    return 1
  fi

  log_debug "更新去重记录..."

  # 获取当前最新提交SHA
  local current_latest_sha=$(head -1 "$current_commits_file" | cut -d'|' -f1)
  local current_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local commit_count=$(wc -l < "$current_commits_file" | tr -d ' ')

  # 使用临时文件更新
  local temp_file="${TMP_DIR}/processed-commits-temp.json"

  # 读取现有记录并更新
  jq --arg sha "$current_latest_sha" \
     --arg timestamp "$current_timestamp" \
     --argjson count "$commit_count" \
     '
       .last_updated = $timestamp |
       .last_run.timestamp = $timestamp |
       .last_run.latest_sha = $sha |
       .last_run.commit_count = $count |
       if .processed_shas[$sha] == null then
         .processed_shas[$sha] = {
           "first_seen": $timestamp,
           "last_processed": $timestamp,
           "processed_count": 1
         }
       else
         .processed_shas[$sha].last_processed = $timestamp |
         .processed_shas[$sha].processed_count += 1
       end
     ' "$PROCESSED_COMMITS_FILE" > "$temp_file"

  # 替换原文件
  mv "$temp_file" "$PROCESSED_COMMITS_FILE"

  log_debug "去重记录已更新: $current_latest_sha ($commit_count 个提交)"
  return 0
}

# 获取去重统计信息
get_dedup_stats() {
  if [ ! -f "$PROCESSED_COMMITS_FILE" ]; then
    echo "尚未运行"
    return
  fi

  local total_processed=$(jq -r '.processed_shas | length' "$PROCESSED_COMMITS_FILE")
  local last_sha=$(jq -r '.last_run.latest_sha // "无"' "$PROCESSED_COMMITS_FILE")
  local last_update=$(jq -r '.last_updated // "从未"' "$PROCESSED_COMMITS_FILE")

  echo "已处理提交数: $total_processed"
  echo "最新提交SHA: $last_sha"
  echo "最后更新: $last_update"
}

# 显示去重状态
show_dedup_status() {
  log_info "去重状态检查..."

  if [ ! -f "$PROCESSED_COMMITS_FILE" ]; then
    log_info "去重记录文件不存在"
    return 0
  fi

  echo ""
  echo "去重统计:"
  get_dedup_stats | sed 's/^/  /'
  echo ""

  # 显示最近处理的提交
  local recent_shas=$(jq -r '.processed_shas | to_entries | sort_by(.value.last_processed) | reverse | .[0:5] | .[] | "  \(.key): \(.value.last_processed)"' "$PROCESSED_COMMITS_FILE" 2>/dev/null)

  if [ -n "$recent_shas" ]; then
    echo "最近处理的提交:"
    echo "$recent_shas"
  fi

  echo ""
}
