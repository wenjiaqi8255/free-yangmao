#!/bin/bash
# 获取原始仓库最近3个月的提交历史
curl -s "https://api.github.com/repos/ripienaar/free-for-dev/commits?per_page=100&since=2024-11-01" \
  | jq -r '.[] | "\(.sha[0:7])|\(.commit.author.date)|\(.commit.message | split("\n")[0])"' \
  > data/recent-commits.txt
