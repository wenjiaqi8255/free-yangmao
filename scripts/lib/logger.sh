#!/bin/bash
#############################################
# Logger Library
# 提供统一的日志输出功能
#############################################

# 防止重复加载
if [ -n "${LOGGER_LIB_LOADED:-}" ]; then
  return 0
fi
export LOGGER_LIB_LOADED=1

# 颜色定义
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'

# 日志级别
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3
readonly LOG_SUCCESS=4

# 当前日志级别（从环境变量读取，默认INFO)
current_level=${LOG_LEVEL:-INFO}
case "$current_level" in
  DEBUG) current_log_level=$LOG_DEBUG ;;
  INFO)  current_log_level=$LOG_INFO ;;
  WARN)  current_log_level=$LOG_WARN ;;
  ERROR) current_log_level=$LOG_ERROR ;;
  *)     current_log_level=$LOG_INFO ;;
esac

# 日志文件路径
log_file="${LOG_DIR}/update-$(date +%Y-%m-%d).log"

#############################################
# 内部函数：获取时间戳
#############################################
_get_timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

#############################################
# 内部函数：获取日志级别名称
#############################################
_get_level_name() {
  local level=$1
  case $level in
    $LOG_DEBUG)   echo "DEBUG" ;;
    $LOG_INFO)    echo "INFO" ;;
    $LOG_WARN)    echo "WARN" ;;
    $LOG_ERROR)   echo "ERROR" ;;
    $LOG_SUCCESS) echo "SUCCESS" ;;
    *)            echo "UNKNOWN" ;;
  esac
}

#############################################
# 内部函数：获取日志级别颜色
#############################################
_get_level_color() {
  local level=$1
  case $level in
    $LOG_DEBUG)   echo "$COLOR_CYAN" ;;
    $LOG_INFO)    echo "$COLOR_BLUE" ;;
    $LOG_WARN)    echo "$COLOR_YELLOW" ;;
    $LOG_ERROR)   echo "$COLOR_RED" ;;
    $LOG_SUCCESS) echo "$COLOR_GREEN" ;;
    *)            echo "$COLOR_RESET" ;;
  esac
}

#############################################
# 核心日志函数
# 参数: $1=日志级别 $2=消息内容
#############################################
_log() {
  local level=$1
  shift
  local message="$@"
  local level_name=$(_get_level_name $level)
  local level_color=$(_get_level_color $level)
  local timestamp=$(_get_timestamp)

  # 检查是否应该输出此级别的日志
  if [ $level -lt $current_log_level ]; then
    return 0
  fi

  # 格式化日志消息
  local formatted_message="[${level_name} ${timestamp}] ${message}"

  # 输出到终端（如果启用）
  if [ "${ENABLE_TERMINAL_LOG:-true}" = "true" ]; then
    echo -e "${level_color}${formatted_message}${COLOR_RESET}"
  fi

  # 输出到日志文件（如果启用）
  if [ "${ENABLE_FILE_LOG:-true}" = "true" ]; then
    mkdir -p "$(dirname "$log_file")" 2>/dev/null
    echo "${formatted_message}" >> "$log_file"
  fi
}

#############################################
# 公共API函数
#############################################

# 调试日志
log_debug() {
  _log $LOG_DEBUG "$@"
}

# 信息日志
log_info() {
  _log $LOG_INFO "$@"
}

# 警告日志
log_warn() {
  _log $LOG_WARN "$@"
}

# 错误日志
log_error() {
  _log $LOG_ERROR "$@"
}

# 成功日志
log_success() {
  _log $LOG_SUCCESS "$@"
}

#############################################
# 进度显示函数
#############################################

# 显示进度条
log_progress() {
  local current=$1
  local total=$2
  local width=50
  local percentage=$((current * 100 / total))
  local filled=$((width * current / total))
  local empty=$((width - filled))

  printf "\r["
  printf "%${filled}s" | tr ' ' '='
  printf "%${empty}s" | tr ' ' ' '
  printf "] %d%% (%d/%d)" $percentage $current $total

  if [ $current -eq $total ]; then
    echo ""
  fi
}

# 显示步骤
log_step() {
  local step=$1
  local total=$2
  local message=$3

  log_info "[$step/$total] $message"
}

#############################################
# 系统通知函数（macOS）
#############################################

# 发送系统通知
log_notify() {
  local title="$1"
  local message="$2"

  if [ "${ENABLE_NOTIFICATIONS:-true}" = "true" ]; then
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
    fi
  fi
}
