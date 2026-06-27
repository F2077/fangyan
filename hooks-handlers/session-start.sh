#!/usr/bin/env bash
# SessionStart hook：注入极轻说明（默认普通话，告 /fangyan 用法与十三可选方言）。
python3 -c "
import json
content = '''\\
本会话已启用「方言」插件，但尚未加载任何方言。当前以普通话对话。

加载方言：运行 /fangyan <方言名>，如 /fangyan 东北话。
可选（十三种）：东北话、北京话、天津话、山东话、陕西话、河南话、
  云南话、成都话、重庆话、湖南话、上海话、粤语、闽南话。

加载某方言后，方以该方言对话；未加载前勿自行切换。
落盘之物（commit、代码、文档）一律平实普通话/英文，不受方言影响。
'''
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': content
    }
}, ensure_ascii=False))
"
exit 0
