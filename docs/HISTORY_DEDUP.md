# 历史记录和去重功能使用指南

**版本**: 1.0
**更新日期**: 2026-02-02

---

## 📋 功能概述

### 历史记录功能
- 每次生成文档时自动保存历史快照
- 文档按时间戳命名：`YYYY-MM-DD.md`
- 自动生成和维护历史索引
- 支持自动清理过期文档（默认90天）

### 去重功能
- 基于GitHub提交SHA判断是否有新内容
- 无新内容时跳过文档生成
- 记录所有已处理的提交
- 提供详细的去重统计信息

---

## 🚀 快速开始

### 启用历史记录

```bash
# 方法1: 环境变量
ENABLE_HISTORY=true bash scripts/run-pipeline.sh

# 方法2: 修改 config.sh
# 在 config.sh 中设置：
ENABLE_HISTORY=true
HISTORY_RETENTION_DAYS=90  # 保留天数（0=永久）

# 然后正常运行
bash scripts/run-pipeline.sh
```

### 启用去重功能

```bash
# 方法1: 环境变量
ENABLE_DEDUP=true bash scripts/run-pipeline.sh

# 方法2: 修改 config.sh
# 在 config.sh 中设置：
ENABLE_DEDUP=true
DEDUP_MODE=strict           # 或 loose
NOTIFY_NO_NEW_CONTENT=true  # 无新内容时通知

# 然后正常运行
bash scripts/run-pipeline.sh
```

### 同时启用两者（推荐）

```bash
# 环境变量方式
ENABLE_HISTORY=true ENABLE_DEDUP=true bash scripts/run-pipeline.sh

# 或修改 config.sh
ENABLE_HISTORY=true
ENABLE_DEDUP=true
```

---

## 📁 文件结构

启用功能后，会生成以下文件结构：

```
free-yangmao/
├── docs/
│   ├── free-for-dev-最新资源.md          # 始终是最新文档
│   └── history/                          # 历史记录目录
│       ├── index.md                      # 历史索引（自动生成）
│       ├── 2026/
│       │   ├── 2026-02-02.md            # 历史文档
│       │   ├── 2026-02-01.md
│       │   └── ...
│       └── latest.md                     # 符号链接到最新文档
├── data/
│   ├── recent-commits.txt                 # 现有文件
│   ├── additions-commits.txt              # 现有文件
│   ├── processed-commits.json             # 新增：已处理提交记录
│   └── last-run-state.json                # 可选：运行状态
└── scripts/
    ├── lib/
    │   ├── dedup.sh                       # 新增：去重模块
    │   └── history.sh                     # 新增：历史管理模块
    └── run-pipeline.sh                    # 修改：集成新功能
```

---

## 🔧 配置参数

### 历史记录配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_HISTORY` | `false` | 是否启用历史记录 |
| `HISTORY_RETENTION_DAYS` | `90` | 历史保留天数（0=永久） |
| `AUTO_UPDATE_INDEX` | `true` | 自动维护历史索引 |
| `HISTORY_DIR` | `docs/history` | 历史文档目录 |

### 去重配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_DEDUP` | `false` | 是否启用去重 |
| `DEDUP_MODE` | `strict` | 去重模式：strict（严格）/ loose（宽松） |
| `NOTIFY_NO_NEW_CONTENT` | `true` | 无新内容时是否通知 |

---

## 📊 使用场景

### 场景1: 完全启用（推荐）

```bash
# config.sh
ENABLE_HISTORY=true
ENABLE_DEDUP=true
HISTORY_RETENTION_DAYS=90
```

**效果**:
- ✅ 有新内容时生成历史文档
- ✅ 无新内容时跳过并通知
- ✅ 自动维护索引
- ✅ 90天后自动清理旧文档

### 场景2: 仅去重

```bash
# config.sh
ENABLE_HISTORY=false
ENABLE_DEDUP=true
```

**效果**:
- ✅ 有新内容时覆盖最新文档
- ✅ 无新内容时跳过并通知
- ❌ 不保留历史记录

### 场景3: 仅历史

```bash
# config.sh
ENABLE_HISTORY=true
ENABLE_DEDUP=false
```

**效果**:
- ✅ 每次都生成历史文档
- ❌ 不进行去重检查
- ✅ 保留完整历史

### 场景4: 向后兼容（默认）

```bash
# 不设置任何参数，使用默认值
ENABLE_HISTORY=false
ENABLE_DEDUP=false
```

**效果**:
- ✅ 与原版行为完全一致
- ✅ 每次覆盖最新文档
- ❌ 不保留历史
- ❌ 不去重

---

## 🔍 去重记录数据结构

`data/processed-commits.json`:

```json
{
  "version": "1.0",
  "last_updated": "2026-02-02T18:30:00Z",
  "processed_shas": {
    "faa2a82": {
      "first_seen": "2026-02-02T12:48:00Z",
      "last_processed": "2026-02-02T18:30:00Z",
      "processed_count": 1
    }
  },
  "last_run": {
    "timestamp": "2026-02-02T18:30:00Z",
    "latest_sha": "faa2a82",
    "commit_count": 15
  }
}
```

---

## 📖 历史索引示例

`docs/history/index.md`:

```markdown
# Free-for-dev 历史记录索引

**最后更新**: 2026-02-02 18:30:00

---

## 📊 统计信息

**总文档数**: 42

### 按年份统计
- **2026**: 5 个文档
- **2025**: 37 个文档

## 📚 历史文档列表

### 2026
- [2026-02-02](2026/2026-02-02.md) - Free-for.dev 资源快照
- [2026-02-01](2026/2026-02-01.md) - Free-for.dev 资源快照
...
```

---

## ⚙️ 运行示例

### 示例1: 首次运行（启用去重和历史）

```bash
$ ENABLE_HISTORY=true ENABLE_DEDUP=true bash scripts/run-pipeline.sh

======================================
Free-Yangmao Pipeline 开始执行
======================================
[INFO] 去重功能: 已启用
[INFO] 历史记录: 已启用 (保留 90 天)
...
[INFO] 去重记录文件不存在
[INFO] 首次运行，将处理所有提交
[SUCCESS] 历史文档已生成: docs/history/2026/2026-02-02.md
[SUCCESS] 历史索引已更新: docs/history/index.md
======================================
Pipeline 执行完成！
======================================
```

### 示例2: 第二次运行（无新内容）

```bash
$ ENABLE_HISTORY=true ENABLE_DEDUP=true bash scripts/run-pipeline.sh

[INFO] 当前最新提交与上次相同: faa2a82
[INFO] 没有新提交需要处理
[INFO] 跳过文档生成
======================================
Pipeline 执行完成（跳过生成）
======================================
```

### 示例3: 有新内容时

```bash
$ ENABLE_HISTORY=true ENABLE_DEDUP=true bash scripts/run-pipeline.sh

[INFO] 检测到新提交: abc1234 (上次: faa2a82)
[SUCCESS] 检测到新内容，继续处理
...
[SUCCESS] 历史文档已生成: docs/history/2026/2026-02-03.md
[SUCCESS] 历史索引已更新
```

---

## 🛠️ 高级用法

### 查看去重统计

```bash
# 查看 processed-commits.json
cat data/processed-commits.json | jq '.'

# 或使用函数（需要在脚本中调用）
show_dedup_status
```

### 查看历史统计

```bash
# 查看历史目录
ls -lh docs/history/

# 查看历史索引
cat docs/history/index.md

# 统计历史文档数量
find docs/history -name "*.md" -type f | grep -v index.md | wc -l
```

### 手动清理历史

```bash
# 删除所有2025年的历史
rm -rf docs/history/2025/

# 删除特定日期的历史
rm docs/history/2026/2026-01-*.md

# 只保留最近30天
find docs/history -name "*.md" -type f -mtime +30 -delete
```

### 重新生成索引

```bash
# 手动触发索引更新
ENABLE_HISTORY=true bash -c '
  source scripts/run-pipeline.sh
  update_history_index
'
```

---

## 🧪 测试

项目提供了测试脚本：

```bash
# 运行测试
bash test-history-dedup.sh
```

测试内容：
1. 仅启用历史记录
2. 仅启用去重
3. 同时启用两者

---

## ⚠️ 注意事项

### 向后兼容性
- 默认情况下，两个功能都**禁用**
- 禁用时的行为与原版完全一致
- 可以独立启用任一功能

### 性能影响
- 历史记录：<1秒（文档复制）
- 去重检查：<1秒（JSON读写）
- 索引更新：<1秒（<100个文档）
- 总体影响：可忽略不计

### 存储空间
- 每个历史文档约100KB
- 保留90天约9MB
- 永久保留会持续增长

### 依赖要求
- **jq**: JSON处理（必需）
- **bash 4.0+**: 关联数组支持（必需）
- **find, sort, grep**: 标准Unix工具（必需）

---

## 🐛 故障排查

### 问题1: 历史文档未生成

**检查**:
```bash
# 检查功能是否启用
echo $ENABLE_HISTORY

# 检查历史目录权限
ls -ld docs/history

# 检查日志
cat logs/update-*.log | grep history
```

### 问题2: 去重不工作

**检查**:
```bash
# 检查 processed-commits.json
cat data/processed-commits.json

# 检查功能是否启用
echo $ENABLE_DEDUP

# 查看去重记录
jq '.' data/processed-commits.json
```

### 问题3: 索引未更新

**检查**:
```bash
# 检查配置
echo $AUTO_UPDATE_INDEX

# 手动更新索引
source scripts/lib/history.sh
update_history_index
```

---

## 📚 相关文档

- [AUTOMATION.md](AUTOMATION.md) - 自动化完整指南
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 快速参考
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排查

---

## 🚀 未来计划

### 短期（1-2周）
- [ ] 添加历史统计可视化
- [ ] 支持历史文档搜索
- [ ] 添加diff功能

### 中期（1-2月）
- [ ] Web界面展示历史
- [ ] 导出为其他格式（PDF、HTML）
- [ ] 历史趋势分析

### 长期（3-6月）
- [ ] AI摘要历史变更
- [ ] 智能推荐配置
- [ ] 多仓库历史聚合

---

**最后更新**: 2026-02-02
**维护者**: Free-Yangmao Team
