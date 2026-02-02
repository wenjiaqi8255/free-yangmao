#!/bin/bash
# 验证文档中的所有链接是否有效

echo "# 链接验证报告" > data/link-check-report.txt
echo "" >> data/link-check-report.txt
echo "生成时间: $(date)" >> data/link-check-report.txt
echo "" >> data/link-check-report.txt

# 提取所有链接
grep -E "http.*\]" docs/free-for-dev-最新资源.md | \
  sed 's/.*\](\(.*\)).*/\1/' | \
  sort -u | \
  while read url; do
    echo "检查: $url" | tee -a data/link-check-report.txt
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    if echo "$response" | grep -E "^(200|301|302)" > /dev/null; then
      echo "✓ OK (HTTP $response)" | tee -a data/link-check-report.txt
    else
      echo "✗ 失败 (HTTP $response)" | tee -a data/link-check-report.txt
    fi
    echo "" | tee -a data/link-check-report.txt
  done
