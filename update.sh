#!/bin/bash
#############################################
# Free-Yangmao One-Click Updater
# 一键更新脚本 - 最简单的执行入口
#############################################

set -euo pipefail

# 颜色定义
readonly COLOR_RESET='\033[0m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[0;33m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#############################################
# 打印带颜色的消息
#############################################
print_info() {
  echo -e "${COLOR_BLUE}ℹ ${1}${COLOR_RESET}"
}

print_success() {
  echo -e "${COLOR_GREEN}✓ ${1}${COLOR_RESET}"
}

print_warning() {
  echo -e "${COLOR_YELLOW}⚠ ${1}${COLOR_RESET}"
}

print_header() {
  echo ""
  echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
  echo -e "${COLOR_BLUE}  ${1}${COLOR_RESET}"
  echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
  echo ""
}

#############################################
# 检查更新
#############################################
check_self_update() {
  if [ -f "${PROJECT_ROOT}/.git/config" ]; then
    cd "$PROJECT_ROOT"
    print_info "检查脚本更新..."

    # 获取本地和远程的commit
    local local_commit=$(git rev-parse HEAD 2>/dev/null || echo "none")
    local remote_commit=$(git ls-remote origin HEAD 2>/dev/null | awk '{print $1}' || echo "none")

    if [ "$local_commit" != "$remote_commit" ] && [ "$remote_commit" != "none" ]; then
      print_warning "发现新版本，建议更新："
      echo "  cd $PROJECT_ROOT"
      echo "  git pull"
      echo ""
    fi
  fi
}

#############################################
# 执行前检查
#############################################
pre_flight_check() {
  print_header "Free-Yangmao 更新检查"

  # 检查配置文件
  if [ ! -f "${PROJECT_ROOT}/config.sh" ]; then
    print_warning "未找到config.sh，使用默认配置"
  fi

  # 检查pipeline脚本
  if [ ! -f "${PROJECT_ROOT}/scripts/run-pipeline.sh" ]; then
    print_warning "未找到pipeline脚本"
    return 1
  fi

  # 检查依赖
  local missing_deps=()

  for cmd in bash curl jq git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -gt 0 ]; then
    print_warning "缺少依赖: ${missing_deps[*]}"
    print_info "请安装后重试"
    return 1
  fi

  print_success "依赖检查通过"
  return 0
}

#############################################
# 执行更新
#############################################
run_update() {
  print_header "开始执行更新"

  local start_time=$(date +%s)

  # 执行pipeline
  if bash "${PROJECT_ROOT}/scripts/run-pipeline.sh"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    print_header "更新完成"

    print_success "所有操作成功完成"
    print_info "执行时间: $duration 秒"

    # 显示输出文件
    local output_file="${PROJECT_ROOT}/docs/free-for-dev-最新资源.md"
    if [ -f "$output_file" ]; then
      echo ""
      print_info "输出文件:"
      echo "  📄 $output_file"
      echo ""

      # 询问是否打开文件
      if [ -n "${DISPLAY:-}" ] || [ "$(uname)" = "Darwin" ]; then
        print_info "是否打开文档? (y/N)"
        read -r -n 1 answer
        echo ""
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
          if command -v open >/dev/null 2>&1; then
            open "$output_file"
          elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$output_file"
          fi
        fi
      fi
    fi
    return 0
  else
    local exit_code=$?
    print_header "更新失败"
    local exit_code=$?
    print_header "更新失败"
    print_warning "Pipeline执行失败 <退出码: ${exit_code}>"
    print_info "请查看日志: ${PROJECT_ROOT}/logs/"
    return 1
  fi
}

#############################################
# 显示帮助
#############################################
show_help() {
  cat << EOF
Free-Yangmao - Free-for-dev 资源自动更新工具

用法:
  bash update.sh [选项]

选项:
  -h, --help     显示此帮助信息
  -v, --verbose  详细输出模式
  -q, --quiet    静默模式
  --no-notify    禁用系统通知
  --check-only   仅检查更新，不执行

配置:
  编辑 config.sh 文件以自定义配置

示例:
  bash update.sh              # 执行更新
  bash update.sh --verbose    # 详细输出
  bash update.sh --check-only # 仅检查

文档:
  docs/AUTOMATION.md          # 详细文档
  docs/TROUBLESHOOTING.md     # 故障排查

项目:
  https://github.com/YOUR_USERNAME/free-yangmao
EOF
}

#############################################
# 处理命令行参数
#############################################
parse_args() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      -v|--verbose)
        export LOG_LEVEL="DEBUG"
        export ENABLE_TERMINAL_LOG="true"
        ;;
      -q|--quiet)
        export LOG_LEVEL="ERROR"
        export ENABLE_TERMINAL_LOG="false"
        export ENABLE_NOTIFICATIONS="false"
        ;;
      --no-notify)
        export ENABLE_NOTIFICATIONS="false"
        ;;
      --check-only)
        check_self_update
        exit 0
        ;;
      *)
        print_warning "未知选项: $1"
        show_help
        exit 1
        ;;
    esac
    shift
  done
}

#############################################
# 主函数
#############################################
main() {
  # 解析参数
  parse_args "$@"

  # 检查脚本更新
  check_self_update

  # 执行前检查
  if ! pre_flight_check; then
    exit 1
  fi

  # 执行更新
  if run_update; then
    exit 0
  else
    exit 1
  fi
}

# 执行主函数
main "$@"
