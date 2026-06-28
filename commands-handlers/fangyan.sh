#!/usr/bin/env bash
# /fangyan 命令 handler：据参数 cat 元规则.md + 对应方言片段。
set -u
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DIALECT="${1:-}"
# 去首尾空白（harness 偶传尾随空格，否则被误判「未知方言」）
DIALECT="${DIALECT#"${DIALECT%%[![:space:]]*}"}"
DIALECT="${DIALECT%"${DIALECT##*[![:space:]]}"}"
META="${ROOT}/references/元规则.md"
INJ="${ROOT}/references/方言注入"

map_dialect() {
  case "$1" in
    东北话|dongbei|db|DB)        echo "东北话" ;;
    北京话|beijing|bj|BJ)        echo "北京话" ;;
    天津话|tianjin|tj|TJ)        echo "天津话" ;;
    山东话|shandong|sd|SD)       echo "山东话" ;;
    陕西话|shaanxi|sx|SX)        echo "陕西话" ;;
    河南话|henan|hn|HN)          echo "河南话" ;;
    云南话|yunnan|yn|YN)         echo "云南话" ;;
    成都话|chengdu|cd|CD)        echo "成都话" ;;
    重庆话|chongqing|cq|CQ)      echo "重庆话" ;;
    湖南话|hunan|xiang|hnx|HNX)  echo "湖南话" ;;
    上海话|shanghai|sh|SH)       echo "上海话" ;;
    粤语|yue|gd|GD)              echo "粤语" ;;
    闽南话|minnan|mn|MN)         echo "闽南话" ;;
    *) return 1 ;;
  esac
}

if [ -z "$DIALECT" ]; then
  echo "未指定方言。用法：/fangyan <方言名>。可选（中文/拼音/代码）："
  echo "  东北话(dongbei/db)  北京话(beijing/bj)  天津话(tianjin/tj)"
  echo "  山东话(shandong/sd) 陕西话(shaanxi/sx)  河南话(henan/hn)"
  echo "  云南话(yunnan/yn)   成都话(chengdu/cd)  重庆话(chongqing/cq)"
  echo "  湖南话(hunan/hnx)   上海话(shanghai/sh) 粤语(yue/gd)"
  echo "  闽南话(minnan/mn)"
  exit 0
fi

NAME=$(map_dialect "$DIALECT") || {
  echo "未知方言「$DIALECT」。可选：东北话/北京话/天津话/山东话/陕西话/河南话/云南话/成都话/重庆话/湖南话/上海话/粤语/闽南话（亦可用拼音或代码）。"
  exit 0
}

SNIPPET="${INJ}/${NAME}.md"
if [ ! -f "$SNIPPET" ]; then
  echo "片段缺失：${SNIPPET}。请运行 scripts/gen-dialect-snippets.py 生成。"
  exit 1
fi

cat "$META"
echo
echo "---"
echo
cat "$SNIPPET"
exit 0
