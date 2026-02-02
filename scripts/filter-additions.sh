#!/bin/bash
# 过滤出真正新增资源的提交（排除 merge 和 update 提交）
grep -E "(Add|add)" data/recent-commits.txt | \
  grep -vE "(Merge|Update|update|Revise|remove|Remove|Useless|useless)" | \
  head -15 > data/additions-commits.txt
