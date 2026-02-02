# Git 提交建议

## 推荐的提交命令

```bash
# 查看变更
git status
git diff --stat

# 添加所有新文件
git add .env.example .github/ .launchd/ config.sh docs/ scripts/ update.sh *.md

# 或添加特定文件
git add config.sh
git add update.sh
git add scripts/run-pipeline.sh
git add scripts/lib/logger.sh
git add scripts/lib/utils.sh
git add .launchd/com.user.free-yangmao.update.plist
git add .github/workflows/update-resources.yml
git add .env.example
git add docs/AUTOMATION.md docs/TROUBLESHOOTING.md
git add AUTOMATION_README.md IMPLEMENTATION_SUMMARY.md
git add .gitignore

# 提交
git commit -m "feat: 完成 Free-Yangmao 自动化工作流实施

- ✨ 添加一键更新功能 (update.sh)
- ⚙️ 添加配置管理系统 (config.sh)
- 📝 实现模块化脚本架构
  - scripts/run-pipeline.sh - 主编排脚本
  - scripts/lib/logger.sh - 日志库
  - scripts/lib/utils.sh - 工具函数库
- ⏰ 支持 macOS Launchd 定时任务
- 🤖 添加 GitHub Actions 工作流配置
- 📚 编写完整文档
  - docs/AUTOMATION.md - 使用指南
  - docs/TROUBLESHOOTING.md - 故障排查
  - AUTOMATION_README.md - 项目介绍
  - IMPLEMENTATION_SUMMARY.md - 实施报告
- 🔧 更新 .gitignore 配置
- 📦 添加环境配置模板 (.env.example)

主要功能:
- 一键执行: bash update.sh
- 定时任务: 支持 macOS Launchd 和 Linux Cron
- 云端自动化: GitHub Actions 集成
- 详细日志: 结构化日志记录
- 错误处理: 完善的重试和恢复机制
- 灵活配置: 丰富的配置选项

详见: IMPLEMENTATION_SUMMARY.md"

# 推送到远程（如需要）
git push
```

## 提交信息说明

### 类型
- `feat`: 新功能
- `fix`: Bug修复
- `docs`: 文档更新
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具链更新

### 格式
遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 示例

```bash
# 功能提交
git commit -m "feat: 添加链接验证功能"

# Bug修复
git commit -m "fix: 修复日期计算错误"

# 文档更新
git commit -m "docs: 更新安装指南"

# 重大更新
git commit -m "feat: 实现自动化工作流

- 添加一键更新脚本
- 支持定时任务
- 集成 GitHub Actions
- 编写完整文档"
```
