#!/usr/bin/env bash
# 验证 fangyan.sh：中文名/拼音别名等效、含元规则与灵魂词、未知方言提示、无参列方言。
set -e
cd "$(dirname "$0")/.."
H=commands-handlers/fangyan.sh

OUT_CN=$(bash "$H" 东北话)
OUT_PY=$(bash "$H" dongbei)
[ "$OUT_CN" = "$OUT_PY" ] || { echo "FAIL: 别名输出不一致"; exit 1; }
echo "$OUT_CN" | grep -q "得体 > 地道" || { echo "FAIL: 缺元规则"; exit 1; }
echo "$OUT_CN" | grep -q "灵魂词" || { echo "FAIL: 缺灵魂词段"; exit 1; }
echo "$OUT_CN" | grep -q "整" || { echo "FAIL: 缺东北话灵魂词"; exit 1; }
echo "$OUT_CN" | grep -q "落盘不退化" || { echo "FAIL: handler 输出缺 落盘不退化"; exit 1; }
echo "$OUT_CN" | grep -q "^## 六、边界" && { echo "FAIL: handler 输出残留重复的 六、边界"; exit 1; } || true
# 尾随空格应被裁剪，照常加载（harness 偶传尾随空格）
OUT_SP=$(bash "$H" "东北话 ")
echo "$OUT_SP" | grep -q "默认之声" || { echo "FAIL: 尾随空格未被裁剪，误判未知方言"; exit 1; }

OUT_BAD=$(bash "$H" 火星话 || true)
echo "$OUT_BAD" | grep -q "未知方言" || { echo "FAIL: 未知方言未提示"; exit 1; }

OUT_NONE=$(bash "$H" || true)
echo "$OUT_NONE" | grep -q "东北话" && echo "$OUT_NONE" | grep -q "闽南话" || { echo "FAIL: 无参未列方言"; exit 1; }

# 性别固定：.claude/fangyan.local.md 命中 address_gender 时注入提示（#4）
HABS="$(cd "$(dirname "$0")/.." && pwd)/commands-handlers/fangyan.sh"
TMPD=$(mktemp -d); mkdir -p "$TMPD/.claude"
printf -- '---\naddress_gender: female\n---\n' > "$TMPD/.claude/fangyan.local.md"
( cd "$TMPD" && bash "$HABS" 东北话 ) | grep -q "优先用女性称谓变体" || { echo "FAIL: 性别固定提示未注入"; rm -rf "$TMPD"; exit 1; }
rm -rf "$TMPD"

echo "PASS fangyan"
