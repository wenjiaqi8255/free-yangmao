# Free-Yangmao 自动化使用指南

> **最后更新**: 2026-02-02
> **版本**: 1.0

本文档说明如何使用 Free-Yangmao 自动化工作流来获取最新的 free-for-dev 资源。

---

## 📖 目录

- [快速开始](#快速开始)
- [安装指南](#安装指南)
- [配置说明](#配置说明)
- [使用方法](#使用方法)
- [自动化设置](#自动化设置)
- [故障排查](#故障排查)

---

## 🚀 快速开始

### 最简单的方式

```bash
# 1. 进入项目目录
cd free-yangmao

# 2. 执行一键更新
bash update.sh
```

就这么简单！脚本会自动完成所有操作。

### 验证结果

更新完成后，查看生成的文档：

```bash
# 打开生成的文档
open docs/free-for-dev-最新资源.md  # macOS
xdg-open docs/free-for-dev-最新资源.md  # Linux
```

---

## 📦 安装指南

### 系统要求

- **操作系统**: macOS 10.15+, Linux (Ubuntu 20.04+)
- **必需工具**:
  - `bash` 4.0+
  - `curl`
  - `jq` (JSON处理工具)
  - `git`

### 安装依赖

#### macOS

```bash
# 使用 Homebrew 安装
brew install jq curl git

# 验证安装
bash --version
jq --version
curl --version
git --version
```

#### Ubuntu/Debian

```bash
# 使用 apt 安装
sudo apt-get update
sudo apt-get install -y bash curl jq git

# 验证安装
bash --version
jq --version
curl --version
git --version
```

#### 其他Linux发行版

```bash
# CentOS/RHEL
sudo yum install -y bash curl jq git

# Arch Linux
sudo pacman -S bash curl jq git
```

### 项目设置

```bash
# 1. 克隆或下载项目
git clone https://github.com/YOUR_USERNAME/free-yangmao.git
cd free-yangmao

# 2. 确保脚本可执行
chmod +x update.sh
chmod +x scripts/*.sh
chmod +x scripts/lib/*.sh

# 3. 创建必要的目录
mkdir -p data logs tmp docs

# 4. 测试运行
bash update.sh --help
```

---

## ⚙️ 配置说明

### 配置文件位置

主配置文件：`config.sh`

### 基础配置

编辑 `config.sh` 文件来自定义配置：

```bash
# 查询最近N天的提交历史（默认90天）
DAYS_AGO=90

# 最多提取的资源数量（默认15个）
MAX_RESOURCES=15

# 包含的关键词
INCLUDE_KEYWORDS="Add|add|新增"

# 排除的关键词
EXCLUDE_KEYWORDS="Merge|Update|update|Revise|remove|Remove"
```

### 功能开关

```bash
# 是否启用链接验证（默认true）
ENABLE_LINK_VALIDATION=true

# 是否启用系统通知（默认true）
ENABLE_NOTIFICATIONS=true

# 是否自动更新本地仓库（默认false）
ENABLE_GIT_UPDATE=false
```

### 日志配置

```bash
# 日志级别: DEBUG, INFO, WARN, ERROR
LOG_LEVEL=INFO

# 是否输出到终端
ENABLE_TERMINAL_LOG=true

# 是否保存日志文件
ENABLE_FILE_LOG=true
```

### 环境变量

你也可以使用环境变量覆盖配置（优先级更高）：

```bash
# 临时配置
DAYS_AGO=30 bash update.sh

# 或使用 .env 文件
cp .env.example .env
# 编辑 .env 文件
source .env
bash update.sh
```

---

## 💡 使用方法

### 方式1: 一键更新（推荐）

```bash
# 默认模式
bash update.sh

# 详细输出模式
bash update.sh --verbose

# 静默模式
bash update.sh --quiet

# 仅检查更新
bash update.sh --check-only

# 禁用通知
bash update.sh --no-notify
```

### 方式2: 运行完整Pipeline

```bash
# 直接运行主编排脚本
bash scripts/run-pipeline.sh

# 或指定配置
LOG_LEVEL=DEBUG bash scripts/run-pipeline.sh
```

### 方式3: 单独运行各个步骤

```bash
# 步骤1: 获取提交历史
bash scripts/get-recent-commits.sh

# 步骤2: 过滤新增提交
bash scripts/filter-additions.sh

# 步骤3: 获取资源详情
bash scripts/get-resource-details.sh

# 步骤4: 提取服务内容
bash scripts/extract-services.sh

# 步骤5: 验证链接（可选）
bash scripts/validate-links.sh
```

---

## 🔄 自动化设置

### macOS Launchd 定时任务

#### 安装定时任务

```bash
# 1. 复制 plist 文件到 LaunchAgents
cp .launchd/com.user.free-yangmao.update.plist ~/Library/LaunchAgents/

# 2. 修改 plist 文件中的路径（如果需要）
# 编辑 ~/Library/LaunchAgents/com.user.free-yangmao.update.plist
# 将 /Users/wenjiaqi/Downloads/free-yangmao 改为你的实际路径

# 3. 加载服务
launchctl load ~/Library/LaunchAgents/com.user.free-yangmao.update.plist

# 4. 验证服务
launchctl list | grep free-yangmao
```

#### 卸载定时任务

```bash
# 1. 卸载服务
launchctl unload ~/Library/LaunchAgents/com.user.free-yangmao.update.plist

# 2. 删除 plist 文件
rm ~/Library/LaunchAgents/com.user.free-yangmao.update.plist
```

#### 查看任务日志

```bash
# 查看输出日志
tail -f logs/launchd-out.log

# 查看错误日志
tail -f logs/launchd-err.log
```

#### 修改执行时间

编辑 `~/Library/LaunchAgents/com.user.free-yangmao.update.plist`:

```xml
<!-- 修改为每天下午3点 -->
<key>StartCalendarInterval</key>
<dict>
  <key>Hour</key>
  <integer>15</integer>
  <key>Minute</key>
  <integer>0</integer>
</dict>

<!-- 或每周一上午9点 -->
<key>StartCalendarInterval</key>
<dict>
  <key>Weekday</key>
  <integer>1</integer>
  <key>Hour</key>
  <integer>9</integer>
  <key>Minute</key>
  <integer>0</integer>
</dict>
```

修改后重新加载服务：

```bash
launchctl unload ~/Library/LaunchAgents/com.user.free-yangmao.update.plist
launchctl load ~/Library/LaunchAgents/com.user.free-yangmao.update.plist
```

### Linux Cron 定时任务

#### 安装定时任务

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天上午9点执行）
0 9 * * * cd /path/to/free-yangmao && bash update.sh >> logs/cron.log 2>&1
```

#### 查看和管理

```bash
# 查看当前的定时任务
crontab -l

# 删除所有定时任务
crontab -r

# 查看cron日志
tail -f logs/cron.log
```

### GitHub Actions 自动化

#### 推送到 GitHub

```bash
# 1. 创建 GitHub 仓库
gh repo create free-yangmao --public --source=. --remote=origin

# 2. 推送代码
git push -u origin main

# 3. 启用 GitHub Actions
# 访问：https://github.com/YOUR_USERNAME/free-yangmao/actions
```

#### 手动触发工作流

```bash
# 使用 gh 命令行工具
gh workflow run update-resources.yml

# 或访问 GitHub 网页界面手动触发
```

#### 查看工作流运行

```bash
# 列出最近的工作流运行
gh run list --workflow=update-resources.yml

# 查看特定运行的详情
gh run view <run-id>

# 查看运行日志
gh run view <run-id> --log
```

---

## 📊 输出说明

### 生成的文件

运行后会生成以下文件：

```
free-yangmao/
├── docs/
│   └── free-for-dev-最新资源.md  # 主要输出文档
├── data/
│   ├── recent-commits.txt        # 最近提交列表
│   ├── additions-commits.txt     # 筛选后的提交
│   ├── resource-details.md       # 资源详情
│   ├── extracted-services.txt    # 提取的服务
│   └── link-check-report.txt     # 链接验证报告
└── logs/
    └── update-2026-02-02.log     # 当天日志
```

### 输出文档格式

`docs/free-for-dev-最新资源.md` 包含：

- 文档头部（生成时间、查询范围）
- 资源详情（提交信息、日期、变更文件）
- 提取的服务内容（新增资源的实际内容）
- 链接验证报告（如果启用）

---

## 🐛 故障排查

### 常见问题

详见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### 快速诊断

```bash
# 检查依赖
bash update.sh --verbose 2>&1 | grep "缺少依赖"

# 检查网络连接
curl -I https://api.github.com

# 检查日志
cat logs/update-$(date +%Y-%m-%d).log

# 清理并重试
rm -rf tmp/* data/*
bash update.sh
```

### 获取帮助

```bash
# 查看帮助信息
bash update.sh --help

# 查看配置
cat config.sh

# 查看日志
ls -lh logs/
```

---

## 🔧 高级用法

### 自定义过滤规则

编辑 `config.sh`:

```bash
# 只包含特定关键词
INCLUDE_KEYWORDS="Add.*AI|add.*ML|新增.*数据库"

# 排除更多关键词
EXCLUDE_KEYWORDS="Merge|Update|Revise|Typo|Fix|Documentation|docs"
```

### 批量处理

```bash
# 更新多个时间段
for days in 30 60 90; do
  DAYS_AGO=$days bash update.sh
  mv docs/free-for-dev-最新资源.md "docs/free-for-dev-${days}天.md"
done
```

### 集成到其他脚本

```bash
#!/bin/bash
# 你的脚本

# 更新资源
if bash /path/to/free-yangmao/update.sh --quiet; then
  echo "资源更新成功"
else
  echo "资源更新失败"
  exit 1
fi

# 继续你的逻辑...
```

---

## 📈 性能优化

### 加速执行

```bash
# 禁用链接验证（最耗时）
ENABLE_LINK_VALIDATION=false bash update.sh

# 减少资源数量
MAX_RESOURCES=10 bash update.sh

# 缩短查询时间范围
DAYS_AGO=30 bash update.sh
```

### 并发执行

如果需要同时处理多个仓库：

```bash
# 使用后台任务
bash update.sh &
PID1=$!

DAYS_AGO=30 MAX_RESOURCES=5 bash update.sh &
PID2=$!

# 等待所有任务完成
wait $PID1
wait $PID2
```

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发环境

```bash
# 1. Fork 并克隆仓库
git clone https://github.com/YOUR_USERNAME/free-yangmao.git
cd free-yangmao

# 2. 创建功能分支
git checkout -b feature/your-feature

# 3. 修改代码

# 4. 测试
bash update.sh --verbose

# 5. 提交
git add .
git commit -m "Add your feature"

# 6. 推送
git push origin feature/your-feature

# 7. 创建 Pull Request
```

---

## 📝 更新日志

### v1.0 (2026-02-02)

- ✨ 初始版本发布
- 🚀 一键更新功能
- ⏰ 定时任务支持
- 📝 完整文档

---

## 📄 许可证

MIT License

---

## 🔗 相关链接

- [free-for-dev 仓库](https://github.com/ripienaar/free-for-dev)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Launchd 文档](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

---

**有问题？** 查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 或提交 Issue。
