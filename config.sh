#!/bin/bash
#############################################
# Free-Yangmao Configuration File
# 可在此文件中自定义所有配置参数
# 环境变量会覆盖这些设置
#############################################

#=========== 时间配置 ============
# 查询最近N天的提交历史（默认90天）
DAYS_AGO="${DAYS_AGO:-90}"

# 计算起始日期
SINCE_DATE=$(date -v-${DAYS_AGO}d +"%Y-%m-%d" 2>/dev/null || date -d "${DAYS_AGO} days ago" +"%Y-%m-%d")

#=========== 过滤配置 ============
# 最多提取的资源数量
MAX_RESOURCES="${MAX_RESOURCES:-15}"

# 包含的关键词（用|分隔）
INCLUDE_KEYWORDS="Add|add|新增"

# 排除的关键词（用|分隔）
EXCLUDE_KEYWORDS="Merge|Update|update|Revise|remove|Remove|Useless|useless|Typo|typo|Fix|fix"

#=========== GitHub API 配置 ============
# GitHub 仓库
GITHUB_REPO="${GITHUB_REPO:-ripienaar/free-for-dev}"

# 每页获取的提交数量
PER_PAGE="${PER_PAGE:-100}"

# API 请求超时时间（秒）
API_TIMEOUT="${API_TIMEOUT:-30}"

#=========== 功能开关 ============
# 是否启用链接验证
ENABLE_LINK_VALIDATION="${ENABLE_LINK_VALIDATION:-true}"

# 是否启用系统通知
ENABLE_NOTIFICATIONS="${ENABLE_NOTIFICATIONS:-true}"

# 是否自动更新本地仓库
ENABLE_GIT_UPDATE="${ENABLE_GIT_UPDATE:-false}"

#=========== 并发配置 ============
# 链接验证并发数
LINK_CHECK_CONCURRENCY="${LINK_CHECK_CONCURRENCY:-5}"

#=========== 日志配置 ============
# 日志级别: DEBUG, INFO, WARN, ERROR
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# 是否输出到终端
ENABLE_TERMINAL_LOG="${ENABLE_TERMINAL_LOG:-true}"

# 是否保存日志文件
ENABLE_FILE_LOG="${ENABLE_FILE_LOG:-true}"

#=========== 路径配置 ============
# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 数据目录
DATA_DIR="${DATA_DIR:-${PROJECT_ROOT}/data}"

# 日志目录
LOG_DIR="${LOG_DIR:-${PROJECT_ROOT}/logs}"

# 临时目录
TMP_DIR="${TMP_DIR:-${PROJECT_ROOT}/tmp}"

# 脚本目录
SCRIPT_DIR="${SCRIPT_DIR:-${PROJECT_ROOT}/scripts}"

#=========== 输出配置 ============
# 输出文档名称
OUTPUT_FILENAME="${OUTPUT_FILENAME:-free-for-dev-最新资源.md}"

# 输出文档路径
OUTPUT_PATH="${OUTPUT_PATH:-${PROJECT_ROOT}/docs}/${OUTPUT_FILENAME}"

#=========== 导出配置变量 ============
export DAYS_AGO SINCE_DATE MAX_RESOURCES
export INCLUDE_KEYWORDS EXCLUDE_KEYWORDS
export GITHUB_REPO PER_PAGE API_TIMEOUT
export ENABLE_LINK_VALIDATION ENABLE_NOTIFICATIONS ENABLE_GIT_UPDATE
export LINK_CHECK_CONCURRENCY
export LOG_LEVEL ENABLE_TERMINAL_LOG ENABLE_FILE_LOG
export PROJECT_ROOT DATA_DIR LOG_DIR TMP_DIR SCRIPT_DIR
export OUTPUT_FILENAME OUTPUT_PATH
