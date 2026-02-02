# Free-Yangmao 快速参考卡

> **最后更新**: 2026-02-02 18:30

---

## 🚀 快速开始

### 立即使用
```bash
# 一键更新
bash update.sh

# 查看结果
open docs/free-for-dev-最新资源.md
```

---

## ⏰ 自动执行

### macOS Launchd
- **执行时间**: 每天上午9:00
- **服务名**: `com.user.free-yangmao.update`
- **日志**: `logs/launchd-out.log`

**管理命令**:
```bash
# 查看状态
launchctl list | grep free-yangmao

# 手动触发
launchctl start com.user.free-yangmao.update

# 停止服务
launchctl unload ~/Library/LaunchAgents/com.user.free-yangmao.update.plist

# 启动服务
launchctl load ~/Library/LaunchAgents/com.user.free-yangmao.update.plist
```

### GitHub Actions
- **仓库**: https://github.com/wenjiaqi8255/free-yangmao
- **执行时间**: 每天上午9:00（北京时间）
- **手动触发**:
  ```bash
  gh workflow run update-resources.yml
  ```

---

## ⚙️ 常用配置

### 查询时间范围
```bash
# 最近30天
DAYS_AGO=30 bash update.sh

# 最近180天
DAYS_AGO=180 bash update.sh
```

### 资源数量
```bash
# 提取20个资源
MAX_RESOURCES=20 bash update.sh
```

### 禁用链接验证
```bash
# 更快执行
ENABLE_LINK_VALIDATION=false bash update.sh
```

### 调试模式
```bash
# 详细日志
bash update.sh --verbose
```

---

## 🆕 新功能（v1.1）

### 历史记录功能
保存每次生成的文档快照，支持查看历史变更。

```bash
# 启用历史记录
ENABLE_HISTORY=true bash update.sh

# 查看历史索引
open docs/history/index.md
```

### 去重功能
基于提交SHA判断是否有新内容，避免重复生成。

```bash
# 启用去重
ENABLE_DEDUP=true bash update.sh
```

### 同时启用（推荐）
```bash
# 启用历史和去重
ENABLE_HISTORY=true ENABLE_DEDUP=true bash update.sh
```

> **详细文档**: [docs/HISTORY_DEDUP.md](docs/HISTORY_DEDUP.md)

---

## 📂 重要文件

### 脚本
- `update.sh` - 一键更新脚本
- `config.sh` - 配置文件
- `scripts/run-pipeline.sh` - 主编排
- `scripts/lib/dedup.sh` - 去重模块 ⭐
- `scripts/lib/history.sh` - 历史管理模块 ⭐

### 文档
- `docs/AUTOMATION.md` - 完整指南
- `docs/TROUBLESHOOTING.md` - 故障排查
- `docs/HISTORY_DEDUP.md` - 历史和去重详解 ⭐

### 日志
- `logs/update-YYYY-MM-DD.log` - 每日执行日志

### 数据
- `data/processed-commits.json` - 去重记录 ⭐
- `docs/history/` - 历史文档目录 ⭐

---

## 🔍 查看结果

### 生成的文档
```bash
# macOS
open docs/free-for-dev-最新资源.md

# Linux
xdg-open docs/free-for-dev-最新资源.md

# 查看历史
open docs/history/index.md
```

### 查看日志
```bash
# 今天的日志
cat logs/update-$(date +%Y-%m-%d).log

# 实时监控
tail -f logs/update-$(date +%Y-%m-%d).log
```

### 查看统计
```bash
# 去重统计
cat data/processed-commits.json | jq '.last_run'

# 历史文档数量
find docs/history -name "*.md" -type f | grep -v index.md | wc -l
```

---

## 🆘 获取帮助

```bash
# 查看帮助
bash update.sh --help

# 详细文档
open docs/AUTOMATION.md

# 故障排查
open docs/TROUBLESHOOTING.md

# 历史和去重功能
open docs/HISTORY_DEDUP.md
```

---

## 🌟 GitHub仓库

**URL**: https://github.com/wenjaqi8255/free-yangmao

**Actions**: https://github.com/wenjaqi8255/free-yangmao/actions

---

**快速参考卡版本**: v1.1 | **最后更新**: 2026-02-02
