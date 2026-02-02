#!/bin/bash
# 从 GitHub 获取每个提交的详细信息
echo "# 资源详情" > data/resource-details.md
echo "" >> data/resource-details.md

while IFS='|' read -r sha date message; do
  echo "## $message" >> data/resource-details.md
  echo "**日期**: $date" >> data/resource-details.md
  echo "**提交**: $sha" >> data/resource-details.md
  echo "" >> data/resource-details.md

  # 获取该提交的文件变更
  curl -s "https://api.github.com/repos/ripienaar/free-for-dev/commits/$sha" | \
    jq -r '.files[] | select(.status == "added" or .status == "modified") | "\(.filename): \(.status)"' | \
    head -5 >> data/resource-details.md
  echo "" >> data/resource-details.md
done < data/additions-commits.txt
