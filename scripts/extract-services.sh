#!/bin/bash
# 克隆完整仓库以查看 diff
if [ ! -d "tmp/free-for-dev-full" ]; then
  git clone https://github.com/ripienaar/free-for-dev.git tmp/free-for-dev-full
fi

cd tmp/free-for-dev-full

# 对于每个新增提交，提取变更的内容
while IFS='|' read -r sha date message; do
  echo "=== $message ===" >> ../../data/extracted-services.txt
  echo "日期: $date" >> ../../data/extracted-services.txt

  # 获取该次提交中 README.md 的变更内容
  git show $sha -- README.md | grep -E "^\+.*\* " | head -10 >> ../../data/extracted-services.txt 2>&1

  echo "" >> ../../data/extracted-services.txt
done < ../../data/additions-commits.txt
