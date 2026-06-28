#!/usr/bin/env bash
# 验证 session-start.sh 输出合法 JSON、含 hookSpecificOutput.additionalContext、含必要说明。
set -e
cd "$(dirname "$0")/.."
OUT=$(bash hooks-handlers/session-start.sh)
echo "$OUT" | python3 -m json.tool > /dev/null
echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
c = d['hookSpecificOutput']['additionalContext']
for kw in ['方言', '/fangyan', '普通话', '东北话', '闽南话']:
    assert kw in c, f'missing {kw}'
print('ok')
"
echo "PASS session-start"
