# Free-Yangmao - 自动化更新工具

> 自动获取和整理 free-for.dev 最新资源的工具

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## ✨ 特性

- 🚀 **一键更新**: 单个命令完成所有操作
- ⏰ **定时执行**: 支持 macOS Launchd 和 Linux Cron
- 🤖 **GitHub Actions**: 云端自动运行，无需本地服务器
- 📝 **详细日志**: 完整的执行日志和错误跟踪
- ⚙️ **灵活配置**: 丰富的配置选项
- 🔔 **系统通知**: 更新完成后发送通知（macOS）

---

## 🚀 快速开始

### 最简单的使用方式

```bash
# 克隆项目
git clone https://github.com/YOUR_USERNAME/free-yangmao.git
cd free-yangmao

# 安装依赖（macOS）
brew install jq curl git

# 或 Ubuntu/Debian
sudo apt-get install jq curl git

# 执行更新
bash update.sh
```

就这样！生成的文档在 `docs/free-for-dev-最新资源.md`

### 查看结果

```bash
# 打开生成的文档（macOS）
open docs/free-for-dev-最新资源.md

# 或 Linux
xdg-open docs/free-for-dev-最新资源.md
```

---

## 📖 详细文档

- **[自动化使用指南](docs/AUTOMATION.md)** - 完整的安装、配置和使用说明
- **[故障排查指南](docs/TROUBLESHOOTING.md)** - 常见问题和解决方案

---

## ⚙️ 配置

编辑 `config.sh` 文件来自定义配置：

```bash
# 查询最近N天的提交历史（默认90天）
DAYS_AGO=90

# 最多提取的资源数量（默认15个）
MAX_RESOURCES=15

# 是否启用链接验证
ENABLE_LINK_VALIDATION=true

# 是否启用系统通知
ENABLE_NOTIFICATIONS=true
```

详见 [配置说明](docs/AUTOMATION.md#配置说明)

---

## 🔄 自动化选项

### 方式1: macOS Launchd（推荐）

```bash
# 复制 plist 文件
cp .launchd/com.user.free-yangmao.update.plist ~/Library/LaunchAgents/

# 加载服务
launchctl load ~/Library/LaunchAgents/com.user.free-yangmao.update.plist

# 每天9:00自动运行
```

### 方式2: Linux Cron

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天上午9点执行）
0 9 * * * cd /path/to/free-yangmao && bash update.sh >> logs/cron.log 2>&1
```

### 方式3: GitHub Actions（云端）

1. Fork 本仓库到你的 GitHub 账号
2. 启用 GitHub Actions
3. 每天9:00（北京时间）自动运行
4. 手动触发：在 Actions 页面点击 "Run workflow"

---

## 📂 项目结构

```
free-yangmao/
├── update.sh                    # 一键更新脚本
├── config.sh                    # 配置文件
├── scripts/                     # 核心脚本
│   ├── run-pipeline.sh         # 主编排脚本
│   ├── get-recent-commits.sh   # 获取提交历史
│   ├── filter-additions.sh     # 过滤新增提交
│   ├── get-resource-details.sh # 获取资源详情
│   ├── extract-services.sh     # 提取服务内容
│   ├── validate-links.sh       # 验证链接
│   └── lib/
│       ├── logger.sh           # 日志库
│       └── utils.sh            # 工具库
├── .launchd/                    # macOS Launchd 配置
├── .github/workflows/           # GitHub Actions 配置
├── docs/                        # 文档和输出
│   ├── AUTOMATION.md           # 详细文档
│   └── TROUBLESHOOTING.md      # 故障排查
├── data/                        # 数据文件（临时）
├── logs/                        # 日志文件
└── tmp/                         # 临时文件
```

---

## 🛠️ 开发

### 运行测试

```bash
# 语法检查
bash -n update.sh
bash -n scripts/*.sh

# 详细模式运行
bash update.sh --verbose

# 查看日志
tail -f logs/update-$(date +%Y-%m-%d).log
```

### 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📝 更新日志

### v1.0.0 (2026-02-02)

- ✨ 初始版本发布
- 🚀 一键更新功能
- ⏰ 定时任务支持（macOS Launchd + Linux Cron）
- 🤖 GitHub Actions 集成
- 📝 完整文档
- 🔔 系统通知支持
- 📊 详细日志记录

---

## 🤝 鸣谢

- [free-for-dev](https://github.com/ripienaar/free-for-dev) - 数据源
- 所有贡献者

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 🔗 相关链接

- [free-for-dev 仓库](https://github.com/ripienaar/free-for-dev)
- [使用文档](docs/AUTOMATION.md)
- [故障排查](docs/TROUBLESHOOTING.md)

---

**Made with ❤️ by the Free-Yangmao team**
