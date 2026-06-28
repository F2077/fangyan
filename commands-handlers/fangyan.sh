#!/usr/bin/env bash
# /fangyan 命令 handler：据参数 cat 元规则.md + 对应方言片段。
# 用法：/fangyan <方言> [0-100]  —— 末尾 0-100 为浓度覆盖（不给则默认亲密度 80）。
# 方言清单派生自 方言灵魂.json（经 scripts/dialect-lookup.py），单一真相源。
set -u
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ARG="${1:-}"
# 去首尾空白（harness 偶传尾随空格，否则被误判「未知方言」）
ARG="${ARG#"${ARG%%[![:space:]]*}"}"
ARG="${ARG%"${ARG##*[![:space:]]}"}"
META="${ROOT}/references/元规则.md"
INJ="${ROOT}/references/方言注入"

# 拆出可选浓度：末尾为 0-100 的 token 即浓度覆盖，余下为方言
DIALECT="$ARG"
CONC=""
if [ -n "$ARG" ]; then
  last="${ARG##* }"
  if [ "$last" != "$ARG" ]; then
    case "$last" in
      [0-9]|[0-9][0-9]|100) CONC="$last"; DIALECT="${ARG% *}";;
    esac
  fi
fi

lookup() { python3 "${ROOT}/scripts/dialect-lookup.py" "$@"; }

if [ -z "$DIALECT" ]; then
  lookup list
  echo
  echo "用法：/fangyan <方言> [0-100]"
  echo "  方言可用中文/拼音/代码（如 东北话 / dongbei / db）。"
  echo "  [0-100] 可选浓度覆盖；不给则默认亲密度 80（朋友级）。"
  echo "  例：/fangyan 东北话 50（收着）　/fangyan dongbei 95（铁哥们）"
  exit 0
fi

if ! NAME=$(lookup resolve "$DIALECT"); then
  lookup error "$DIALECT"
  exit 0
fi

SNIPPET="${INJ}/${NAME}.md"
if [ ! -f "$SNIPPET" ]; then
  echo "片段缺失：${SNIPPET}。请运行 scripts/gen-dialect-snippets.py 生成。"
  exit 1
fi

# 性别固定（可选）：读 $PWD/.claude/fangyan.local.md 的 address_gender，命中则显式提示
PIN_HINT=""
LOCAL="${PWD}/.claude/fangyan.local.md"
if [ -f "$LOCAL" ]; then
  G=$(grep -Ei '^address_gender:' "$LOCAL" | head -1 | sed -E 's/^address_gender:[[:space:]]*//I; s/[[:space:]]*$//')
  case "$G" in
    female|女)      PIN_HINT="女性" ;;
    male|男)        PIN_HINT="男性" ;;
    neutral|中立)  PIN_HINT="中立" ;;
  esac
fi

cat "$META"
echo
echo "---"
echo
cat "$SNIPPET"
if [ -n "$CONC" ]; then
  echo
  echo "---"
  echo
  echo "## 浓度（本次：亲密度 ${CONC}%）"
  echo
  echo "本次按浓度 ${CONC}% 对话（覆盖默认亲密度 80%）。"
fi
if [ -n "$PIN_HINT" ]; then
  echo
  echo "---"
  echo
  echo "## 称谓固定（自 .claude/fangyan.local.md：address_gender=$G）"
  echo
  echo "优先用${PIN_HINT}称谓变体（见上方「称谓」段）。"
fi
exit 0
