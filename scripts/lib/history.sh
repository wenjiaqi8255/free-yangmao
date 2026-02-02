#!/bin/bash
#############################################
# Free-Yangmao History Management Module
# 历史记录管理模块 - 生成和维护历史文档
#############################################

#=========== 配置 ============
HISTORY_DIR="${HISTORY_DIR:-${PROJECT_ROOT}/docs/history}"
HISTORY_INDEX_FILE="${HISTORY_DIR}/index.md"

#############################################
# 工具函数
#############################################

# 初始化历史目录
init_history_dir() {
  if [ ! -d "$HISTORY_DIR" ]; then
    log_info "创建历史目录: $HISTORY_DIR"
    mkdir -p "$HISTORY_DIR"
  fi

  # 创建年份子目录
  local current_year=$(date +%Y)
  if [ ! -d "${HISTORY_DIR}/${current_year}" ]; then
    mkdir -p "${HISTORY_DIR}/${current_year}"
  fi
}

# 生成历史文档文件名
get_history_filename() {
  local timestamp="${1:-$(date +%s)}"
  date -r "$timestamp" +%Y-%m-%d 2>/dev/null || date -d "@$timestamp" +%Y-%m-%d 2>/dev/null
}

# 生成历史文档路径
get_history_path() {
  local timestamp="${1:-$(date +%s)}"
  local filename=$(get_history_filename "$timestamp")
  local year=$(echo "$filename" | cut -d'-' -f1)
  echo "${HISTORY_DIR}/${year}/${filename}.md"
}

# 生成历史文档
generate_history_document() {
  local source_file="${1:-${OUTPUT_PATH}}"
  local timestamp="${2:-$(date +%s)}"

  if [ ! -f "$source_file" ]; then
    log_error "源文档不存在: $source_file"
    return 1
  fi

  init_history_dir

  local history_path=$(get_history_path "$timestamp")
  local history_dir=$(dirname "$history_path")

  # 创建目录
  mkdir -p "$history_dir"

  # 复制文档到历史目录
  log_info "生成历史文档: $history_path"
  cp "$source_file" "$history_path"

  # 添加历史元数据到文档顶部
  local temp_file="${TMP_DIR}/history-temp.md"
  local generation_time=$(date -r "$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)

  {
    echo "---"
    echo "历史记录: Free-for-dev 资源快照"
    echo "生成时间: $generation_time"
    echo "文档版本: $(get_history_filename "$timestamp")"
    echo "---"
    echo ""
    cat "$history_path"
  } > "$temp_file"

  mv "$temp_file" "$history_path"

  log_success "历史文档已生成: $history_path"
  return 0
}

# 更新历史索引
update_history_index() {
  init_history_dir

  log_info "更新历史索引..."

  local current_year=$(date +%Y)

  # 生成索引头部
  cat > "$HISTORY_INDEX_FILE" << EOF
# Free-for-dev 历史记录索引

**最后更新**: $(date '+%Y-%m-%d %H:%M:%S')
**历史目录**: \`docs/history/\`

---

## 📊 统计信息

EOF

  # 统计历史文档数量
  local total_docs=$(find "$HISTORY_DIR" -name "*.md" -type f 2>/dev/null | grep -v index.md | wc -l | tr -d ' ')

  echo "**总文档数**: $total_docs" >> "$HISTORY_INDEX_FILE"
  echo "" >> "$HISTORY_INDEX_FILE"

  # 按年份统计
  echo "### 按年份统计" >> "$HISTORY_INDEX_FILE"
  echo "" >> "$HISTORY_INDEX_FILE"

  for year_dir in "$HISTORY_DIR"/*; do
    if [ -d "$year_dir" ]; then
      local year=$(basename "$year_dir")
      local year_count=$(find "$year_dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
      echo "- **$year**: $year_count 个文档" >> "$HISTORY_INDEX_FILE"
    fi
  done

  echo "" >> "$HISTORY_INDEX_FILE"

  # 生成文档列表
  echo "## 📚 历史文档列表" >> "$HISTORY_INDEX_FILE"
  echo "" >> "$HISTORY_INDEX_FILE"

  # 按年份和日期排序显示
  for year_dir in $(ls -d "$HISTORY_DIR"/*/ 2>/dev/null | sort -r); do
    if [ -d "$year_dir" ]; then
      local year=$(basename "$year_dir")
      echo "### $year" >> "$HISTORY_INDEX_FILE"
      echo "" >> "$HISTORY_INDEX_FILE"

      for doc in $(find "$year_dir" -name "*.md" -type f 2>/dev/null | sort -r); do
        local doc_name=$(basename "$doc" .md)
        local doc_path=$(echo "$doc" | sed "s|${PROJECT_ROOT}/||")
        local relative_path=$(echo "$doc" | sed "s|${PROJECT_ROOT}/||")

        # 获取文档大小
        local doc_size=$(wc -c < "$doc" | tr -d ' ')
        local doc_size_mb=$(echo "scale=2; $doc_size / 1024 / 1024" | bc)

        # 获取第一行标题
        local title=$(head -5 "$doc" | grep -E "^#" | head -1 | sed 's/^# //; s/\*\*//g; s/\*\*//g' || echo "$doc_name")

        echo "- [$doc_name]($relative_path) - $title (${doc_size_mb}MB)" >> "$HISTORY_INDEX_FILE"
      done

      echo "" >> "$HISTORY_INDEX_FILE"
    fi
  done

  # 添加索引尾部
  cat >> "$HISTORY_INDEX_FILE" << 'EOF'

---

## 🔍 使用说明

每个历史文档都包含对应时间点的 Free-for.dev 资源快照。

### 查看历史
- 点击上面的文档链接查看具体内容
- 文档按年份组织在 `docs/history/YYYY/` 目录下
- 文档命名格式: `YYYY-MM-DD.md`

### 清理历史
默认保留最近 90 天的历史文档。可通过配置 `HISTORY_RETENTION_DAYS` 调整。

### 最新文档
当前最新文档: [`free-for-dev-最新资源.md`](../free-for-dev-最新资源.md)
EOF

  log_success "历史索引已更新: $HISTORY_INDEX_FILE"
  return 0
}

# 清理过期历史文档
cleanup_old_history() {
  local retention_days="${1:-${HISTORY_RETENTION_DAYS:-90}}"

  if [ "$retention_days" -le 0 ]; then
    log_info "历史保留天数为 0，不清理历史文档"
    return 0
  fi

  log_info "清理 ${retention_days} 天前的历史文档..."

  local cutoff_time=$(date -v-${retention_days}d +%s 2>/dev/null || date -d "${retention_days} days ago" +%s)
  local deleted_count=0

  # 查找并删除过期文档
  while IFS= read -r -d '' doc; do
    local doc_time=$(stat -f %m "$doc" 2>/dev/null || stat -c %Y "$doc" 2>/dev/null)

    if [ -n "$doc_time" ] && [ "$doc_time" -lt "$cutoff_time" ]; then
      log_debug "删除过期文档: $doc"
      rm -f "$doc"
      ((deleted_count++))
    fi
  done < <(find "$HISTORY_DIR" -name "*.md" -type f -not -name "index.md" -print0 2>/dev/null)

  if [ $deleted_count -gt 0 ]; then
    log_info "已删除 $deleted_count 个过期历史文档"
  else
    log_debug "没有需要清理的过期文档"
  fi

  # 清理空目录
  find "$HISTORY_DIR" -type d -empty -delete 2>/dev/null || true

  return 0
}

# 维护最新文档符号链接
maintain_latest_link() {
  local latest_link="${HISTORY_DIR}/latest.md"

  if [ -L "$latest_link" ]; then
    rm -f "$latest_link"
  fi

  local current_doc="${OUTPUT_PATH}"

  if [ ! -f "$current_doc" ]; then
    log_warn "当前文档不存在，无法创建符号链接"
    return 1
  fi

  # 创建相对路径符号链接
  local relative_path=$(python3 -c "import os; print(os.path.relpath('$current_doc', '$HISTORY_DIR'))" 2>/dev/null)

  if [ -n "$relative_path" ]; then
    ln -s "$relative_path" "$latest_link"
    log_debug "已更新最新文档符号链接: $latest_link -> $relative_path"
  else
    log_debug "无法创建符号链接（需要Python3）"
  fi

  return 0
}

# 显示历史统计
show_history_stats() {
  log_info "历史记录统计..."

  if [ ! -d "$HISTORY_DIR" ]; then
    echo "历史目录不存在"
    return 0
  fi

  echo ""
  echo "历史存储位置: $HISTORY_DIR"
  echo ""

  # 总文档数
  local total_docs=$(find "$HISTORY_DIR" -name "*.md" -type f 2>/dev/null | grep -v index.md | wc -l | tr -d ' ')
  echo "总文档数: $total_docs"
  echo ""

  # 总大小
  local total_size=$(find "$HISTORY_DIR" -name "*.md" -type f 2>/dev/null | grep -v index.md | xargs wc -c 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
  local total_size_mb=$(echo "scale=2; $total_size / 1024 / 1024" | bc)
  echo "总大小: ${total_size_mb}MB"
  echo ""

  # 最新和最旧文档
  local latest_doc=$(find "$HISTORY_DIR" -name "*.md" -type f 2>/dev/null | grep -v index.md | xargs ls -t 2>/dev/null | head -1)
  local oldest_doc=$(find "$HISTORY_DIR" -name "*.md" -type f 2>/dev/null | grep -v index.md | xargs ls -t 2>/dev/null | tail -1)

  if [ -n "$latest_doc" ]; then
    local latest_name=$(basename "$latest_doc" .md)
    echo "最新文档: $latest_name"
  fi

  if [ -n "$oldest_doc" ]; then
    local oldest_name=$(basename "$oldest_doc" .md)
    echo "最旧文档: $oldest_name"
  fi

  echo ""
}
