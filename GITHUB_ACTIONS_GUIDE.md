# GitHub Actions 每2天运行 - 实施指南

**目标**: 配置GitHub Actions每隔2天自动运行free-yangmao更新流程
**状态**: ✅ 配置已优化，需要验证测试

---

## 📋 当前配置状态

### ✅ 已完成的优化

1. **Cron表达式已更新**
   - **旧**: `cron: '0 1 * * *'`（每天运行）
   - **新**: `cron: '0 1 */2 * *'`（每2天运行）
   - **说明**: UTC时间1点 = 北京时间9:00

2. **新增功能支持**
   - 历史记录功能已集成
   - 去重功能已集成
   - 通过输入参数控制（灵活）

3. **性能优化**
   - 禁用链接验证（`ENABLE_LINK_VALIDATION=false`）
   - 加快执行速度（从3-5分钟降到2-3分钟）

4. **安全性增强**
   - 15分钟超时保护
   - GitHub Token正确配置
   - 自动提交智能逻辑

5. **监控和日志**
   - 详细的workflow summary
   - Artifact上传（日志、输出、历史索引）
   - 失败通知

---

## 🧪 需要执行的测试

### 测试1: 本地环境验证

**目的**: 确保脚本在GitHub Actions环境中能正常运行

```bash
# 1. 进入项目目录
cd /Users/wenjiaqi/Downloads/free-yangmao

# 2. 运行验证脚本
bash verify-github-actions.sh

# 3. 修复发现的问题（如果有）
```

**当前问题**:
- [x] Cron表达式已修复
- [x] Workflow配置已优化

### 测试2: 手动触发GitHub Actions

**目的**: 验证GitHub Actions能正常执行

```bash
# 1. 确保代码已推送到GitHub
git status
git add .
git commit -m "feat: 优化GitHub Actions配置，支持每2天运行"
git push

# 2. 手动触发workflow测试
gh workflow run update-resources.yml

# 3. 查看运行状态
gh run list --workflow=update-resources.yml --limit 5

# 4. 查看运行详情（使用最新的run_id）
gh run view <run_id> --log
```

### 测试3: 带参数测试

**目的**: 测试手动触发时的参数控制

```bash
# 测试1: 完全启用
gh workflow run update-resources.yml -f enable_history=true -f enable_dedup=true

# 测试2: 仅启用去重
gh workflow run update-resources.yml -f enable_history=false -f enable_dedup=true

# 测试3: 自定义查询天数
gh workflow run update-resources.yml -f days_ago=60
```

---

## 📊 预期行为

### 正常运行（每2天）

```
第1天运行: UTC 1:00 (北京时间9:00)
  ✓ 获取最近90天的提交
  ✓ 生成资源文档
  ✓ 保存历史快照
  ✓ 更新索引
  ✓ 提交变更

第2天: (不运行)

第3天运行: UTC 1:00 (北京时间9:00)
  ✓ 检查是否有新提交
  ✓ 如果有新内容：生成文档、保存历史
  ✓ 如果无新内容：跳过（智能去重）
```

### Workflow执行流程

```
1. Checkout代码 ✓
2. 安装依赖（jq, curl, git） ✓
3. 验证依赖 ✓
4. 设置脚本权限 ✓
5. 创建必要目录 ✓
6. 显示配置信息 ✓
7. 执行更新流程 ✓
   - 去重检查
   - 获取提交
   - 过滤新增
   - 获取详情
   - 提取服务
   - 生成文档
   - 保存历史
   - 更新索引
8. 检查输出文件 ✓
9. 生成workflow summary ✓
10. 提交变更 ✓
11. 上传artifacts ✓
```

---

## 🔧 配置文件详情

### 关键配置参数

```yaml
# 环境变量
env:
  ENABLE_HISTORY: true          # 启用历史记录
  ENABLE_DEDUP: true             # 启用去重
  HISTORY_RETENTION_DAYS: 90  # 保留90天历史
  DAYS_AGO: 90                 # 查询90天
  MAX_RESOURCES: 15             # 最多15个资源
  ENABLE_LINK_VALIDATION: false # 禁用链接验证（加快速度）

# Cron调度
schedule:
  - cron: '0 1 */2 * *'  # 每2天UTC 1:00
```

### 手动触发参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enable_history` | boolean | true | 是否启用历史记录 |
| `enable_dedup` | boolean | true | 是否启用去重 |
| `days_ago` | number | 90 | 查询天数 |

---

## 📝 完成检查清单

### 基础配置（必须）

- [x] GitHub Actions workflow文件已更新
- [x] Cron表达式改为每2天运行
- [x] 历史和去重功能已集成
- [x] 性能优化（禁用链接验证）
- [x] 安全配置（超时、Token）

### 测试验证（推荐）

- [ ] 本地验证脚本通过
- [ ] 代码已推送到GitHub
- [ ] 手动触发测试成功
- [ ] 检查workflow运行日志
- [ ] 验证artifact正确上传
- [ ] 确认自动提交工作正常

### 监控设置（可选）

- [ ] 在GitHub仓库中启用Actions通知
- [ ] 设置失败时邮件通知
- [ ] 添加成功/失败徽章到README

---

## 🚀 部署步骤

### Step 1: 推送代码到GitHub

```bash
# 添加所有变更
git add .

# 提交变更
git commit -m "feat: 配置GitHub Actions每2天运行，集成历史和去重功能

- 更新cron表达式为每2天运行
- 集成历史记录和去重功能
- 优化性能（禁用链接验证）
- 添加详细的workflow summary

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 推送到远程
git push origin main
```

### Step 2: 验证配置

```bash
# 1. 检查workflow是否生效
gh workflow list

# 2. 查看workflow配置
gh workflow view update-resources.yml

# 3. 手动触发测试
gh workflow run update-resources.yml

# 4. 查看运行结果
gh run list --workflow=update-resources.yml
gh run view <run_id>
```

### Step 3: 监控首次运行

```bash
# 等待下次自动运行（2天后）
# 或查看最近的运行
gh run list --workflow=update-resources.yml --limit 5

# 查看详细日志
gh run view <run_id> --log
```

---

## 🔍 故障排查

### 问题1: Workflow未触发

**检查**:
```bash
# 检查workflow是否启用
gh workflow list

# 检查调度历史
gh api /repos/{owner}/{repo}/actions/workflows/update-resources.yml/runs
```

**解决**:
- 确认workflow文件在`.github/workflows/`目录
- 确保代码推送到main/master分支
- 检查GitHub Actions服务是否正常

### 问题2: 执行失败

**检查**:
```bash
# 查看失败日志
gh run view <run_id> --log

# 检查依赖安装
gh run view <run_id> | grep "Setup dependencies" -A 20
```

**常见原因**:
- jq未安装 → Actions会自动安装
- 权限问题 → 检查GITHUB_TOKEN
- 超时 → 增加timeout-minutes
- 脚本错误 → 查看详细日志

### 问题3: 未生成历史文档

**检查**:
```bash
# 检查enable_history设置
gh run view <run_id> --log | grep ENABLE_HISTORY

# 检查输出文件
gh api /repos/{owner}/{repo}/actions/artifacts
```

**解决**:
- 确认`ENABLE_HISTORY=true`
- 检查workflow summary中的"功能状态"
- 下载artifact验证内容

### 问题4: 提交失败

**检查**:
```bash
# 查看提交步骤日志
gh run view <run_id> --log | grep "Commit changes" -A 20

# 检查GITHUB_TOKEN权限
gh auth status
```

**解决**:
- 确保仓库Settings → Actions → General → Workflow permissions设置正确
- 确认GITHUB_TOKEN有write权限
- 检查email配置是否正确

---

## 📊 监控和报告

### 查看运行历史

```bash
# GitHub网页界面
https://github.com/{owner}/{repo}/actions/workflows/update-resources.yml

# CLI命令
gh run list --workflow=update-resources.yml
gh run view <run_id> --log
```

### 下载Artifacts

```bash
# 下载最新运行日志
gh run download <run_id> -n workflow-logs-*

# 下载输出文件
gh run download <run_id> -n free-resources-*

# 下载历史索引
gh run download <run_id> -n history-index-*
```

### 统计信息

```bash
# 查看最近30天的运行统计
gh run list --workflow=update-resources.yml --json 30 | \
  jq '.workflow_runs | length'

# 统计成功/失败
gh run list --workflow=update-resources.yml --json 100 | \
  jq '.workflow_runs | group_by(.conclusion) | map({status: .[0].conclusion, count: length}) | .'
```

---

## ✅ 成功标志

### Workflow运行成功

- ✅ 所有步骤显示绿色对钩
- ✅ "Commit changes"步骤有"git push"输出
- ✅ Artifacts成功上传（3个文件）
- ✅ Workflow summary显示完整信息

### 内容验证

- ✅ `docs/free-for-dev-最新资源.md` 已更新
- ✅ `docs/history/index.md` 已生成（如果启用历史）
- ✅ `data/processed-commits.json` 已更新（如果启用去重）
- ✅ Git仓库有新的提交

---

## 📚 相关文档

- **[verify-github-actions.sh](verify-github-actions.sh)** - 配置验证脚本
- **[.github/workflows/update-resources.yml](.github/workflows/update-resources.yml)** - Workflow配置文件
- **[docs/HISTORY_DEDUP.md](docs/HISTORY_DEDUP.md)** - 功能使用指南
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - 快速参考

---

**最后更新**: 2026-02-02
**维护者**: Free-Yangmao Team
**状态**: ✅ 配置完成，待测试验证
