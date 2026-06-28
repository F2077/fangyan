#!/usr/bin/env bash
# 验证 元规则.md 含：落盘不退化（术语白名单/仅对话层/技术判断零退化）+ 工程里程碑庆祝。
set -e
cd "$(dirname "$0")/.."
M="references/元规则.md"
for kw in "落盘不退化" "术语白名单" "工程里程碑庆祝" "仅对话层" "技术判断零退化" "function" "API" "git" "npm" "勿凡回合皆庆"; do
  grep -q "$kw" "$M" || { echo "FAIL: 元规则缺「$kw」"; exit 1; }
done
echo "PASS meta"
