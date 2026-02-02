#!/bin/bash
#############################################
# Utils Library
# 提供常用工具函数
#############################################

# 防止重复加载
if [ -n "${UTILS_LIB_LOADED:-}" ]; then
  return 0
fi
export UTILS_LIB_LOADED=1

# 加载logger库
source "${SCRIPT_DIR}/lib/logger.sh"

#############################################
# 依赖检查
# 参数: $1=命令名称
# 返回: 0=存在 1=不存在
#############################################
check_dependency() {
  local cmd=$1

  if command -v "$cmd" >/dev/null 2>&1; then
    log_debug "依赖检查: $cmd ✓"
    return 0
  else
    log_error "缺少依赖: $cmd"
    return 1
  fi
}

#############################################
# 批量依赖检查
# 参数: 多个命令名称
# 返回: 0=全部存在 1=至少一个不存在
#############################################
check_dependencies() {
  local all_exist=true

  for cmd in "$@"; do
    if ! check_dependency "$cmd"; then
      all_exist=false
    fi
  done

  if [ "$all_exist" = "false" ]; then
    log_error "请安装缺失的依赖后重试"
    return 1
  fi

  log_success "所有依赖检查通过"
  return 0
}

#############################################
# 网络连接检查
#############################################
check_internet() {
  log_debug "检查网络连接..."

  if ! check_dependency "curl"; then
    return 1
  fi

  if curl -s --connect-timeout 5 https://api.github.com >/dev/null 2>&1; then
    log_debug "网络连接正常 ✓"
    return 0
  else
    log_error "无法连接到 GitHub API，请检查网络"
    return 1
  fi
}

#############################################
# 重试执行命令
# 参数: $1=最大重试次数 $2=重试间隔(秒) $3+=命令
# 返回: 0=成功 1=失败
#############################################
retry_command() {
  local max_attempts=$1
  local wait_time=$2
  shift 2

  local attempt=1
  local cmd=("$@")

  log_debug "重试命令: ${cmd[*]} (最多${max_attempts}次)"

  while [ $attempt -le $max_attempts ]; do
    if "${cmd[@]}"; then
      log_debug "命令执行成功 (第${attempt}次尝试)"
      return 0
    else
      if [ $attempt -lt $max_attempts ]; then
        log_warn "命令执行失败，${wait_time}秒后重试 (尝试 $attempt/$max_attempts)..."
        sleep $wait_time
      fi
      ((attempt++))
    fi
  done

  log_error "命令执行失败，已达最大重试次数"
  return 1
}

#############################################
# 安全的curl请求
# 参数: $1=URL $2+=额外的curl参数
# 返回: curl的退出码
#############################################
safe_curl() {
  local url=$1
  shift

  local timeout="${API_TIMEOUT:-30}"
  local tmp_file
  local http_code

  log_debug "请求: $url"

  # 创建临时文件
  tmp_file="${TMP_DIR}/curl_response_$$_$.tmp"

  # 执行curl请求
  http_code=$(curl -s \
    --connect-timeout 10 \
    --max-time $timeout \
    -w "%{http_code}" \
    -o "$tmp_file" \
    "$url" \
    "$@" 2>/dev/null)

  # 读取并清理
  if [ -f "$tmp_file" ]; then
    cat "$tmp_file"
    rm -f "$tmp_file"
  fi

  # 检查HTTP状态码
  case "$http_code" in
    200|201|202|204)
      return 0
      ;;
    403|429)
      log_warn "API限流 (HTTP $http_code)，可能需要稍后重试"
      return 2
      ;;
    404)
      log_error "资源未找到 (HTTP 404)"
      return 3
      ;;
    5*)
      log_error "服务器错误 (HTTP $http_code)"
      return 4
      ;;
    *)
      log_error "请求失败 (HTTP $http_code)"
      return 5
      ;;
  esac
}

#############################################
# 创建目录（如果不存在）
# 参数: 多个目录路径
#############################################
ensure_dirs() {
  for dir in "$@"; do
    if [ ! -d "$dir" ]; then
      log_debug "创建目录: $dir"
      mkdir -p "$dir"
    fi
  done
}

#############################################
# 清理临时文件
#############################################
cleanup_tmp() {
  log_debug "清理临时文件..."

  if [ -d "$TMP_DIR" ]; then
    # 清理超过7天的临时文件
    find "$TMP_DIR" -type f -mtime +7 -delete 2>/dev/null
  fi
}

#############################################
# 文件大小格式化
# 参数: $1=字节数
# 输出: 格式化后的大小（如：1.5M, 500K）
#############################################
format_size() {
  local bytes=$1
  local units=('B' 'K' 'M' 'G' 'T')
  local unit=0

  while [ $bytes -gt 1024 ] && [ $unit -lt ${#units[@]} ]; do
    bytes=$((bytes / 1024))
    ((unit++))
  done

  echo "${bytes}${units[$unit]}"
}

#############################################
# 时间格式化
# 参数: $1=秒数
# 输出: 格式化后的时间（如：1m30s, 45s）
#############################################
format_duration() {
  local seconds=$1

  if [ $seconds -ge 3600 ]; then
    printf "%dh%dm%ds" $((seconds / 3600)) $((seconds % 3600 / 60)) $((seconds % 60))
  elif [ $seconds -ge 60 ]; then
    printf "%dm%ds" $((seconds / 60)) $((seconds % 60))
  else
    printf "%ds" $seconds
  fi
}

#############################################
# 计算脚本执行时间
#############################################
time_execution() {
  local start_time=$1
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  log_info "执行时间: $(format_duration $duration)"
}

#############################################
# 生成唯一的临时文件名
# 参数: $1=前缀（可选）
# 输出: 临时文件路径
#############################################
mktemp_file() {
  local prefix="${1:-tmp}"
  local timestamp=$(date +%s)
  local random=$((RANDOM % 10000))

  echo "${TMP_DIR}/${prefix}_${timestamp}_${random}.tmp"
}

#############################################
# 确保必要的目录存在
#############################################
ensure_environment() {
  ensure_dirs "$DATA_DIR" "$LOG_DIR" "$TMP_DIR" "$SCRIPT_DIR/lib"

  # 创建.gitkeep文件
  touch "${LOG_DIR}/.gitkeep" 2>/dev/null

  log_debug "环境目录已准备就绪"
}
