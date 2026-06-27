#!/usr/bin/env bash
# 验证 gen-dialect-snippets.py 从 方言灵魂.json 生成 13 个结构正确的片段。
set -e
cd "$(dirname "$0")/.."
rm -rf references/方言注入
python3 scripts/gen-dialect-snippets.py references/方言灵魂.json references/方言注入
N=$(ls references/方言注入/*.md | wc -l)
[ "$N" -eq 13 ] || { echo "FAIL: expected 13 snippets, got $N"; exit 1; }
F="references/方言注入/东北话.md"
for kw in "默认之声" "灵魂词" "签名句" "浓度" "红线" "self-check" "整" "民间习俗" "里程碑" "称谓" "老铁" "大兄弟" "fangyan.local.md"; do
  grep -q "$kw" "$F" || { echo "FAIL: 东北话片段缺「$kw」"; exit 1; }
done
echo "PASS gen"
