# Free-Yangmao 故障排查指南

> **最后更新**: 2026-02-02
> **版本**: 1.0

本文档提供常见问题的解决方案和调试技巧。

---

## 📋 目录

- [快速诊断](#快速诊断)
- [依赖问题](#依赖问题)
- [网络问题](#网络问题)
- [执行错误](#执行错误)
- [输出问题](#输出问题)
- [自动化问题](#自动化问题)
- [调试技巧](#调试技巧)

---

## 🔍 快速诊断

### 诊断脚本

运行以下命令快速检查问题：

```bash
# 完整诊断
bash update.sh --verbose 2>&1 | tee diagnose.log

# 检查依赖
for cmd in bash curl jq git; do
  if command -v $cmd >/dev/null 2>&1; then
    echo "✓ $cmd: $(command -v $cmd)"
  else
    echo "✗ $cmd: 未安装"
  fi
done

# 检查网络
curl -I https://api.github.com
```

### 检查日志

```bash
# 今天的日志
cat logs/update-$(date +%Y-%m-%d).log

# 最近的所有日志
ls -lht logs/ | head -10

# 实时监控日志
tail -f logs/update-$(date +%Y-%m-%d).log
```

---

## 🔧 依赖问题

### 问题: jq 未找到

**错误信息**:
```
jq: command not found
```

**解决方案**:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install -y jq

# CentOS/RHEL
sudo yum install -y jq

# 验证
jq --version
```

### 问题: curl 版本过旧

**错误信息**:
```
curl: option --max-time: is unknown
```

**解决方案**:

```bash
# macOS
brew install curl

# Ubuntu/Debian
sudo apt-get install --only-upgrade curl

# 验证版本
curl --version | head -n 1
```

### 问题: bash 版本过低

**错误信息**:
```
syntax error near unexpected token
```

**解决方案**:

```bash
# 检查版本
bash --version

# macOS（使用 Homebrew 安装的 bash）
brew install bash
# 添加到 /etc/shells: /usr/local/bin/bash
# chsh -s /usr/local/bin/bash

# Linux
sudo apt-get install bash
```

---

## 🌐 网络问题

### 问题: 无法连接到 GitHub API

**错误信息**:
```
curl: (7) Failed to connect
```

**解决方案**:

1. **检查网络连接**
   ```bash
   ping api.github.com
   curl -I https://api.github.com
   ```

2. **检查代理设置**
   ```bash
   # 如果使用代理
   export https_proxy=http://proxy.example.com:8080
   export http_proxy=http://proxy.example.com:8080

   # 或在 config.sh 中配置
   export https_proxy=http://proxy.example.com:8080
   ```

3. **使用 GitHub Token**
   ```bash
   # 创建 Token: https://github.com/settings/tokens
   export GITHUB_TOKEN="your_token_here"

   # 修改 API URL（在脚本中）
   # https://api.github.com/repos/...
   # 改为
   # https://${GITHUB_TOKEN}@api.github.com/repos/...
   ```

### 问题: API 限流

**错误信息**:
```
HTTP 403: rate limit exceeded
```

**解决方案**:

1. **设置 GitHub Token**
   ```bash
   # 创建 Personal Access Token
   # 访问: https://github.com/settings/tokens
   # 选择权限: repo (public_repo)

   # 设置环境变量
   export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

   # 或添加到 .env 文件
   echo "GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx" >> .env
   ```

2. **减少请求频率**
   ```bash
   # 增加超时时间
   API_TIMEOUT=60 bash update.sh

   # 减少每页数量
   PER_PAGE=50 bash update.sh
   ```

### 问题: SSL 证书错误

**错误信息**:
```
SSL certificate problem
```

**解决方案**:

```bash
# 临时跳过验证（不推荐）
export GIT_SSL_NO_VERIFY=1

# 或更新 CA 证书
# macOS
brew install ca-certificates

# Ubuntu/Debian
sudo apt-get install ca-certificates
sudo update-ca-certificates
```

---

## ⚠️ 执行错误

### 问题: Permission denied

**错误信息**:
```
bash: ./update.sh: Permission denied
```

**解决方案**:

```bash
# 添加执行权限
chmod +x update.sh
chmod +x scripts/*.sh
chmod +x scripts/lib/*.sh

# 验证
ls -l update.sh
ls -l scripts/*.sh
```

### 问题: 配置文件未找到

**错误信息**:
```
config.sh: No such file or directory
```

**解决方案**:

```bash
# 检查文件是否存在
ls -la config.sh

# 如果不存在，从默认配置创建
cat > config.sh << 'EOF'
#!/bin/bash
DAYS_AGO=90
MAX_RESOURCES=15
# ... 其他配置
EOF

# 或从示例恢复
cp config.sh.example config.sh 2>/dev/null || true
```

### 问题: 目录不存在

**错误信息**:
```
No such file or directory: data/
```

**解决方案**:

```bash
# 创建必要目录
mkdir -p data logs tmp docs
touch logs/.gitkeep

# 验证
ls -la data/ logs/ tmp/ docs/
```

### 问题: git 命令失败

**错误信息**:
```
fatal: not a git repository
```

**解决方案**:

```bash
# 初始化 git 仓库（如果需要）
git init

# 或克隆 free-for-dev 仓库（用于提取服务）
cd tmp/
git clone --depth 1 https://github.com/ripienaar/free-for-dev.git
cd ..
```

---

## 📄 输出问题

### 问题: 输出文件未生成

**症状**: 执行成功但 `docs/free-for-dev-最新资源.md` 不存在

**解决方案**:

```bash
# 检查输出目录
ls -la docs/

# 检查 data 目录
ls -la data/

# 手动指定输出路径
OUTPUT_PATH=/custom/path/output.md bash update.sh

# 检查权限
touch docs/test.txt && rm docs/test.txt
```

### 问题: 输出文件为空

**症状**: 文件存在但内容为空或很少

**解决方案**:

```bash
# 检查数据文件
cat data/recent-commits.txt
cat data/additions-commits.txt

# 可能的原因：
# 1. 查询时间范围内没有新增资源
# 2. 过滤规则太严格

# 调整配置
DAYS_AGO=180 bash update.sh  # 扩大时间范围
MAX_RESOURCES=50 bash update.sh  # 增加资源数量

# 查看原始提交
cat data/recent-commits.txt | wc -l
```

### 问题: 编码问题

**症状**: 输出文件中文乱码

**解决方案**:

```bash
# 检查文件编码
file docs/free-for-dev-最新资源.md

# 转换编码
iconv -f UTF-8 -t UTF-8 docs/free-for-dev-最新资源.md > temp.md
mv temp.md docs/free-for-dev-最新资源.md

# 或在脚本中设置
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
```

---

## ⏰ 自动化问题

### 问题: Launchd 任务不执行

**症状**: 定时任务配置了但没有运行

**诊断步骤**:

```bash
# 1. 检查服务是否加载
launchctl list | grep free-yangmao

# 2. 查看服务日志
tail -f logs/launchd-out.log
tail -f logs/launchd-err.log

# 3. 检查 plist 文件语法
plutil -lint ~/Library/LaunchAgents/com.user.free-yangmao.update.plist

# 4. 手动触发测试
launchctl start com.user.free-yangmao.update
```

**解决方案**:

```bash
# 1. 确保路径正确
# 编辑 plist 文件，确保所有路径都是绝对路径
vim ~/Library/LaunchAgents/com.user.free-yangmao.update.plist

# 2. 重新加载服务
launchctl unload ~/Library/LaunchAgents/com.user.free-yangmao.update.plist
launchctl load ~/Library/LaunchAgents/com.user.free-yangmao.update.plist

# 3. 验证权限
ls -l update.sh
ls -l ~/Library/LaunchAgents/com.user.free-yangmao.update.plist
```

### 问题: Cron 任务不执行

**症状**: Cron 任务没有运行

**诊断步骤**:

```bash
# 1. 检查 cron 服务
# Linux
sudo systemctl status cron
# macOS
sudo launchctl list | grep cron

# 2. 查看当前用户的定时任务
crontab -l

# 3. 查看 cron 日志
# Linux
tail -f /var/log/syslog | grep CRON
# macOS
log show --predicate 'process == "cron"' --last 1h
```

**解决方案**:

```bash
# 1. 编辑 crontab
crontab -e

# 2. 确保使用绝对路径
# 错误示例:
# 0 9 * * * cd free-yangmao && bash update.sh

# 正确示例:
# 0 9 * * * cd /full/path/to/free-yangmao && /bin/bash update.sh >> /full/path/to/logs/cron.log 2>&1

# 3. 确保 PATH 正确
# 在 crontab 中添加:
PATH=/usr/local/bin:/usr/bin:/bin

# 4. 测试命令
# 手动执行 crontab 中的命令，确保可以运行
cd /full/path/to/free-yangmao && /bin/bash update.sh
```

### 问题: GitHub Actions 失败

**症状**: Workflow 运行失败

**诊断步骤**:

```bash
# 1. 查看 Actions 日志
gh run list --workflow=update-resources.yml
gh run view <run-id> --log

# 2. 检查 workflow 文件语法
yamllint .github/workflows/update-resources.yml

# 3. 本地测试
# 使用 act 工具本地运行 GitHub Actions
act push
```

**常见原因**:

1. **依赖未安装**
   ```yaml
   # 在 workflow 中添加
   - name: Setup dependencies
     run: |
       sudo apt-get update
       sudo apt-get install -y jq curl git
   ```

2. **权限问题**
   ```yaml
   # 确保 token 有足够权限
   - name: Checkout
     uses: actions/checkout@v4
     with:
       token: ${{ secrets.GITHUB_TOKEN }}
       persist-credentials: true
   ```

3. **路径错误**
   ```yaml
   # 使用绝对路径或确保在正确目录
   - name: Run update
     run: |
       pwd
       ls -la
       bash update.sh
   ```

---

## 🐛 调试技巧

### 启用详细日志

```bash
# 方法1: 使用 --verbose 参数
bash update.sh --verbose

# 方法2: 设置环境变量
LOG_LEVEL=DEBUG bash update.sh

# 方法3: 修改 config.sh
# LOG_LEVEL="DEBUG"
```

### 跟踪执行

```bash
# 使用 bash -x 跟踪执行
bash -x update.sh

# 或在脚本开头添加
set -x  # 跟踪执行
set -v  # 打印输入
```

### 分步调试

```bash
# 单独执行每个脚本
bash scripts/get-recent-commits.sh
# 检查输出
cat data/recent-commits.txt

bash scripts/filter-additions.sh
# 检查输出
cat data/additions-commits.txt

# 继续下一步...
```

### 隔离问题

```bash
# 创建最小测试脚本
cat > test.sh << 'EOF'
#!/bin/bash
set -x
source config.sh
echo "DAYS_AGO=$DAYS_AGO"
echo "GITHUB_REPO=$GITHUB_REPO"
curl -s "https://api.github.com/repos/${GITHUB_REPO}/commits?per_page=1" | jq .
EOF

chmod +x test.sh
bash test.sh
```

### 清理并重试

```bash
# 清理所有生成文件
rm -rf data/* logs/* tmp/*

# 重新执行
bash update.sh --verbose
```

---

## 📞 获取帮助

### 收集诊断信息

```bash
# 创建诊断脚本
cat > diagnose.sh << 'EOF'
#!/bin/bash
echo "=== 系统信息 ==="
uname -a

echo -e "\n=== 依赖版本 ==="
bash --version | head -n 1
jq --version
curl --version | head -n 1
git --version

echo -e "\n=== 网络连接 ==="
curl -I https://api.github.com 2>&1 | head -n 1

echo -e "\n=== 文件权限 ==="
ls -l update.sh
ls -l scripts/*.sh

echo -e "\n=== 最近日志 ==="
tail -n 50 logs/update-$(date +%Y-%m-%d).log 2>/dev/null || echo "无日志文件"

echo -e "\n=== 配置 ==="
grep -E "^(DAYS_AGO|MAX_RESOURCES|LOG_LEVEL)" config.sh
EOF

chmod +x diagnose.sh
bash diagnose.sh > diagnosis.txt 2>&1
```

### 提交 Issue 时包含

1. 系统信息：`uname -a`
2. 错误信息：完整的错误输出
3. 配置信息：`config.sh` 中的关键配置
4. 日志文件：`logs/update-$(date +%Y-%m-%d).log`
5. 复现步骤：如何触发问题

### 有用的资源

- [Bash 调试技巧](https://www.cyberciti.biz/tips/debugging-shell-script.html)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Launchd 编程指南](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

---

## ✅ 检查清单

使用此检查清单排查问题：

- [ ] 所有依赖已安装（bash, curl, jq, git）
- [ ] 所有脚本有执行权限
- [ ] 网络连接正常
- [ ] config.sh 配置正确
- [ ] 必要目录已创建（data, logs, tmp, docs）
- [ ] 日志文件可写
- [ ] GitHub Token 已设置（如果需要）
- [ ] Launchd/Cron 已正确配置（如果使用自动化）
- [ ] 路径都是绝对路径（在自动化脚本中）

---

**仍无法解决？** 提交 Issue 并包含诊断信息。
