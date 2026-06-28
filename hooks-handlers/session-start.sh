#!/usr/bin/env bash
# SessionStart hook：注入极轻说明（默认普通话，告 /fangyan 用法；方言名单派生自 方言灵魂.json）。
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
python3 -c "
import json
from pathlib import Path
soul = Path('$ROOT') / 'references' / '方言灵魂.json'
dialects = list(json.loads(soul.read_text(encoding='utf-8'))['dialects'].keys())
names = '、'.join(dialects)
n = len(dialects)
content = (
    '本会话已启用「方言」插件，但尚未加载任何方言。当前以普通话对话。\n\n'
    f'加载方言：运行 /fangyan <方言> [0-100]，如 /fangyan 东北话、/fangyan dongbei 95。\n'
    f'可选（共 {n} 种）：{names}。\n\n'
    '加载某方言后，方以该方言对话；默认亲密度 80（朋友级），可带 0-100 调浓度。未加载前勿自行切换。\n'
    '落盘之物（commit、代码、文档）一律平实普通话/英文，不受方言影响。\n'
)
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'SessionStart', 'additionalContext': content}}, ensure_ascii=False))
"
exit 0
