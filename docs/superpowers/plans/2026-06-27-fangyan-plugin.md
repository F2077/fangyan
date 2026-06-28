# fangyan 方言对话插件（行为层）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个按需加载的方言对话插件——SessionStart 注入极轻说明（默认普通话），`/fangyan <方言>` 命令按需加载单一方言腔调。

**Architecture:** SessionStart hook + slash command 双层。十三方言全套资料卧 `references/` 磁盘，`/fangyan` handler cat `元规则.md` + 单方言精炼片段（从 `方言灵魂.json` 由 python 脚本生成）注入上下文。默认不加载任何方言。

**Tech Stack:** bash（hook/command handler）、python3 标准库 json（片段生成脚本）、markdown（注入指令/资料）、Claude Code plugin（plugin.json / hooks.json / commands）。

**对应 spec:** `docs/superpowers/specs/2026-06-27-fangyan-dialect-plugin-design.md` §1–4、§6（行为层部分）、§7。

**调研资料源：** `/mnt/c/Users/Since1986/Downloads/fangyan/`（已解压的 13 方言调研报告）。

---

## File Structure

| 文件 | 责任 |
|---|---|
| `references/方言报告/*.md` ×13 | 调研报告原文（导入），模型按需 Read |
| `references/方言灵魂.json` | 数据源（导入），生成片段 + 按需 Read |
| `references/方言字典.json` | 390 词条典（导入），按需 Read |
| `references/民间习俗.md` | 习俗 + 大事模板（导入），按需 Read |
| `references/行为规则.md` | 完整行为规范（导入），按需深读 |
| `references/元规则.md` | 通用五黄金法则（**新建**，command 注入，~150 token） |
| `references/方言注入/*.md` ×13 | 精炼片段（**生成**，command 注入，每 ~450 token） |
| `scripts/gen-dialect-snippets.py` | 从 `方言灵魂.json` 生成 `方言注入/*.md` |
| `hooks/hooks.json` | 声明 SessionStart hook |
| `hooks-handlers/session-start.sh` | 注入极轻说明 |
| `commands/fangyan.md` | `/fangyan` 命令定义（frontmatter） |
| `commands-handlers/fangyan.sh` | 别名映射 + cat 元规则 + 片段 |
| `.claude-plugin/plugin.json` | 插件清单 |
| `.claude-plugin/marketplace.json` | 市集清单 |
| `README.md` | 安装与用法文档 |
| `LICENSE` | MIT |
| `tests/test_*.sh` | 脚本行为测试 |

---

## Task 1: 导入调研资料到 references/

**Files:**
- Create: `references/方言报告/*.md` ×13
- Create: `references/方言灵魂.json`、`references/方言字典.json`、`references/民间习俗.md`、`references/行为规则.md`

- [ ] **Step 1: 建目录并批量导入**

```bash
cd /home/work/F2077/others/fangyan
SRC="/mnt/c/Users/Since1986/Downloads/fangyan"
mkdir -p references/方言报告
# 13 份方言报告
cp "$SRC"/北京话.md "$SRC"/天津话.md "$SRC"/东北话.md "$SRC"/山东话.md \
   "$SRC"/陕西话.md "$SRC"/河南话.md "$SRC"/云南话.md "$SRC"/成都话.md \
   "$SRC"/重庆话.md "$SRC"/湖南话.md "$SRC"/上海话.md "$SRC"/粤语.md \
   "$SRC"/闽南话.md references/方言报告/
# 结构化数据 + 规范文档
cp "$SRC"/方言灵魂.json references/方言灵魂.json
cp "$SRC"/方言字典.json references/方言字典.json
cp "$SRC"/民间习俗形式分析.md references/民间习俗.md
cp "$SRC"/AI行为规则.md references/行为规则.md
```

- [ ] **Step 2: 验证导入齐全**

Run:
```bash
cd /home/work/F2077/others/fangyan
echo "报告数: $(ls references/方言报告/*.md | wc -l)"          # 期望 13
python3 -c "import json; d=json.load(open('references/方言灵魂.json',encoding='utf-8')); print('灵魂方言数:', len(d['dialects']))"  # 期望 13
python3 -c "import json; d=json.load(open('references/方言字典.json',encoding='utf-8')); print('字典方言数:', len(d['dialects']))"  # 期望 13
test -f references/民间习俗.md && echo "习俗 OK"
test -f references/行为规则.md && echo "行为规则 OK"
```
Expected: 报告数 13、灵魂方言数 13、字典方言数 13、习俗 OK、行为规则 OK。

- [ ] **Step 3: 提交**

```bash
git add references/
git commit -m "feat(references): import 13-dialect research corpus"
```

---

## Task 2: 编写 references/元规则.md（command 注入之通用段）

**Files:**
- Create: `references/元规则.md`

- [ ] **Step 1: 写元规则.md**

完整内容：

```markdown
# 方言对话通用元规则

> 适用于已加载的任何方言。得体为先，地道自来。

## 五黄金法则

1. **得体 > 地道**：不冒犯比说对话重要。拿不准时降浓度。
2. **亲密度决定浓度**：关系未到不强行方言。陌生人轻点（20–30%），铁哥们放开（80–95%）。
3. **红线词默认关**：粗口/贬称是“金库钥匙”非常用工具。亲密度 80+ 且私下场景方开；正式/商务/丧事即达亦不用。
4. **场景决定风格**：丧事严肃、节日喜庆、工作正式。丧事 −50、商务 −20、节日 +10。
5. **文化不错位**：各方言有其专属民俗——北京=京剧/相声（非二人转），东北=二人转/秧歌（非山歌），云南=山歌（非京剧），陕西=秦腔，粤语=饮茶/舞狮，闽南=拜拜/南音。勿串。

## 浓度速算

浓度 ≈ 亲密度基础浓度 + 场景加成（节日 +10／商务 −20／丧事 −50），夹于 0–100。过塞方言词显“装”——一段话 2–3 个方言词最地道。

## 跟随用户

用户以某方言发言，则随之；用户明确要普通话，则回普通话。同一时间只用一种方言，勿混搭。

## 边界

落盘之物（commit、代码、文档）用平实普通话/英文；技术术语（function、API、git、npm、docker 等）保留原文。
```

- [ ] **Step 2: 验证**

Run:
```bash
cd /home/work/F2077/others/fangyan
grep -q "得体 > 地道" references/元规则.md && grep -q "五黄金法则" references/元规则.md && echo "OK"
```
Expected: `OK`

- [ ] **Step 3: 提交**

```bash
git add references/元规则.md
git commit -m "feat(references): add cross-dialect meta-rules"
```

---

## Task 3: 片段生成脚本 gen-dialect-snippets.py（TDD）

**Files:**
- Create: `scripts/gen-dialect-snippets.py`
- Test: `tests/test_gen.sh`

- [ ] **Step 1: 写失败测试 tests/test_gen.sh**

```bash
#!/usr/bin/env bash
# 验证 gen-dialect-snippets.py 从 方言灵魂.json 生成 13 个结构正确的片段。
set -e
cd "$(dirname "$0")/.."
rm -rf references/方言注入
python3 scripts/gen-dialect-snippets.py references/方言灵魂.json references/方言注入
N=$(ls references/方言注入/*.md | wc -l)
[ "$N" -eq 13 ] || { echo "FAIL: expected 13 snippets, got $N"; exit 1; }
F="references/方言注入/东北话.md"
for kw in "默认之声" "灵魂词" "签名句" "浓度" "红线" "self-check" "整"; do
  grep -q "$kw" "$F" || { echo "FAIL: 东北话片段缺「$kw」"; exit 1; }
done
echo "PASS gen"
```

```bash
cd /home/work/F2077/others/fangyan
mkdir -p tests
# （写入上面内容到 tests/test_gen.sh）
chmod +x tests/test_gen.sh
```

- [ ] **Step 2: 跑测试，确认失败**

Run: `bash tests/test_gen.sh`
Expected: FAIL（`scripts/gen-dialect-snippets.py` 不存在）。

- [ ] **Step 3: 实现 scripts/gen-dialect-snippets.py**

```python
#!/usr/bin/env python3
"""从 方言灵魂.json 生成各方言精炼注入片段 → references/方言注入/<方言>.md。

用法：python3 gen-dialect-snippets.py <灵魂.json> <输出目录>
固定段（开篇/边界/self-check）写死；可变段自 json 填。
"""
import json
import sys
from pathlib import Path

TEMPLATE = """\
# {name}对话模式

已加载{name}；此为默认对话之声，非待宣模式。回复勿冠「（{name}）」之类标签，径以{name}起笔。

## 一、灵魂词（先打开）
{soul_words}

## 二、签名句（语气参照）
{signature_sentences}

## 三、浓度策略
默认浓度：陌生人 {c_stranger}%／熟人 {c_acq}%／朋友 {c_friend}%／铁哥们 {c_close}%。
得体 > 地道：勿为“地道”而过塞方言词致“装”。亲密度愈高浓度愈浓。

## 四、红线词（默认关）
{red_line}
亲密度未达 80（或非私下场景）绝不用；正式/丧事场景即达亦不用。

## 五、禁忌
{do_not}

## 六、边界
- 落盘之物（commit、代码、文档）用平实普通话/英文，不受方言影响。
- 技术术语（function、API、git、npm 等）保留原文。
- 用户明确要求普通话 → 回普通话。

## 七、深入取阅
需具体词汇/习俗大事 → Read references/方言报告/{name}.md 或 references/方言字典.json。

## self-check（每回复前）
1. 是否以{name}起笔，无标签前缀？
2. 浓度是否合亲密度（勿过塞）？
3. 红线词是否已依亲密度过滤？
4. 落盘之物是否平实？
5. 是否纯{name}，无标签前缀？
"""


def fmt_soul_words(d):
    roles = d.get("soul_words_role", {})
    lines = [f"- **{w}**：{roles[w]}" for w in d.get("soul_words", []) if w in roles]
    return "\n".join(lines) if lines else "（无）"


def fmt_signature(d):
    return "／".join(d.get("signature_sentences", [])[:5]) or "（无）"


def fmt_red_line(d):
    return "、".join(d.get("red_line_words", [])) or "（本方言无显式红线词，依通用元规则慎用粗口）"


def fmt_do_not(d):
    return "\n".join(f"- {x}" for x in d.get("do_not", [])) or "（无）"


def gen_one(name, d):
    c = d.get("default_concentration", {})
    return TEMPLATE.format(
        name=name,
        soul_words=fmt_soul_words(d),
        signature_sentences=fmt_signature(d),
        red_line=fmt_red_line(d),
        do_not=fmt_do_not(d),
        c_stranger=c.get("stranger", 20),
        c_acq=c.get("acquaintance", 40),
        c_friend=c.get("friend", 60),
        c_close=c.get("close_friend", 80),
    )


def main():
    if len(sys.argv) != 3:
        print("用法：gen-dialect-snippets.py <灵魂.json> <输出目录>", file=sys.stderr)
        sys.exit(2)
    src, outdir = Path(sys.argv[1]), Path(sys.argv[2])
    dialects = json.loads(src.read_text(encoding="utf-8"))["dialects"]
    outdir.mkdir(parents=True, exist_ok=True)
    for name, d in dialects.items():
        (outdir / f"{name}.md").write_text(gen_one(name, d), encoding="utf-8")
    print(f"生成 {len(dialects)} 个方言片段 → {outdir}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: 跑测试，确认通过**

Run: `bash tests/test_gen.sh`
Expected: `PASS gen`

- [ ] **Step 5: 提交**

```bash
git add scripts/gen-dialect-snippets.py tests/test_gen.sh references/方言注入/
git commit -m "feat(snippets): generate 13 dialect snippets from soul json"
```

---

## Task 4: SessionStart handler session-start.sh（TDD）

**Files:**
- Create: `hooks-handlers/session-start.sh`
- Test: `tests/test_session_start.sh`

- [ ] **Step 1: 写失败测试 tests/test_session_start.sh**

```bash
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
```

- [ ] **Step 2: 跑测试，确认失败**

Run: `bash tests/test_session_start.sh`
Expected: FAIL（handler 不存在）。

- [ ] **Step 3: 实现 hooks-handlers/session-start.sh**

```bash
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
```

- [ ] **Step 4: 跑测试，确认通过**

Run: `bash tests/test_session_start.sh`
Expected: `PASS session-start`

- [ ] **Step 5: 提交**

```bash
git add hooks-handlers/session-start.sh tests/test_session_start.sh
git commit -m "feat(hook): add SessionStart notice handler"
```

---

## Task 5: hooks.json（声明 SessionStart）

**Files:**
- Create: `hooks/hooks.json`

- [ ] **Step 1: 写 hooks.json**

```json
{
  "description": "方言对话插件——按需加载十三方言腔调，/fangyan 切换，默认普通话。",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks-handlers/session-start.sh\""
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: 验证 JSON 合法**

Run: `python3 -m json.tool hooks/hooks.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: 提交**

```bash
git add hooks/hooks.json
git commit -m "feat(hooks): declare SessionStart hook"
```

---

## Task 6: /fangyan handler fangyan.sh（TDD）

**Files:**
- Create: `commands-handlers/fangyan.sh`
- Test: `tests/test_fangyan.sh`

- [ ] **Step 1: 写失败测试 tests/test_fangyan.sh**

```bash
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

OUT_BAD=$(bash "$H" 火星话 || true)
echo "$OUT_BAD" | grep -q "未知方言" || { echo "FAIL: 未知方言未提示"; exit 1; }

OUT_NONE=$(bash "$H" || true)
echo "$OUT_NONE" | grep -q "东北话" && echo "$OUT_NONE" | grep -q "闽南话" || { echo "FAIL: 无参未列方言"; exit 1; }

echo "PASS fangyan"
```

- [ ] **Step 2: 跑测试，确认失败**

Run: `bash tests/test_fangyan.sh`
Expected: FAIL（handler 不存在）。

- [ ] **Step 3: 实现 commands-handlers/fangyan.sh**

```bash
#!/usr/bin/env bash
# /fangyan 命令 handler：据参数 cat 元规则.md + 对应方言片段。
set -u
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DIALECT="${1:-}"
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
  exit 0
fi

cat "$META"
echo
echo "---"
echo
cat "$SNIPPET"
exit 0
```

- [ ] **Step 4: 跑测试，确认通过**

Run: `bash tests/test_fangyan.sh`
Expected: `PASS fangyan`

- [ ] **Step 5: 提交**

```bash
git add commands-handlers/fangyan.sh tests/test_fangyan.sh
git commit -m "feat(command): add /fangyan dialect loader handler"
```

---

## Task 7: commands/fangyan.md（slash command 定义）

**Files:**
- Create: `commands/fangyan.md`

> 实现说明：Claude Code slash command 以 `!` 前缀行执行 bash 并把 stdout 注入对话。若当前版本 `!` 语法不符，改用 command-development skill 所载之等价 inline-bash 形式——但 handler 调用与 `$ARGUMENTS` 传递不变。

- [ ] **Step 1: 写 commands/fangyan.md**

```markdown
---
description: 加载某方言对话腔调（如 /fangyan 东北话）；留空列出十三可选
argument-hint: <方言名，如 东北话；可用拼音/代码>
allowed-tools: Bash
---

!bash "${CLAUDE_PLUGIN_ROOT}/commands-handlers/fangyan.sh" "${ARGUMENTS}"
```

- [ ] **Step 2: 验证 frontmatter 合法（YAML 头 + 命令体）**

Run:
```bash
cd /home/work/F2077/others/fangyan
head -5 commands/fangyan.md | grep -q "description:" && grep -q "fangyan.sh" commands/fangyan.md && echo OK
```
Expected: `OK`

- [ ] **Step 3: 提交**

```bash
git add commands/fangyan.md
git commit -m "feat(command): add /fangyan slash command definition"
```

---

## Task 8: plugin.json + marketplace.json

**Files:**
- Create: `.claude-plugin/plugin.json`、`.claude-plugin/marketplace.json`

- [ ] **Step 1: 写 .claude-plugin/plugin.json**

```json
{
  "name": "fangyan",
  "version": "0.1.0",
  "description": "方言对话插件——按需加载十三方言腔调（东北话/北京话/粤语/闽南话等），/fangyan 切换，默认普通话，token 极简。",
  "author": { "name": "F2077" }
}
```

- [ ] **Step 2: 写 .claude-plugin/marketplace.json**

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "fangyan-marketplace",
  "description": "方言对话插件市集——一方水土，一方言。",
  "owner": { "name": "F2077" },
  "plugins": [
    {
      "name": "fangyan",
      "description": "方言对话插件——按需加载十三方言腔调，/fangyan 切换，默认普通话。",
      "source": ".",
      "category": "productivity",
      "license": "MIT",
      "keywords": ["方言", "dialect", "中文", "chinese", "voice", "腔调"],
      "homepage": "https://github.com/F2077/fangyan"
    }
  ]
}
```

- [ ] **Step 3: 验证两 JSON 合法**

Run:
```bash
cd /home/work/F2077/others/fangyan
python3 -m json.tool .claude-plugin/plugin.json > /dev/null && \
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo OK
```
Expected: `OK`

- [ ] **Step 4: 提交**

```bash
git add .claude-plugin/
git commit -m "feat(plugin): add plugin and marketplace manifests"
```

---

## Task 9: README.md + LICENSE

**Files:**
- Modify: `README.md`（覆盖现有 9 字节占位）
- Create: `LICENSE`

- [ ] **Step 1: 写 README.md**

````markdown
# fangyan · 方言对话插件

> 一方水土，一方言。

让 Claude Code 按需以**十三种方言**对话的插件：东北话、北京话、天津话、山东话、陕西话、河南话、云南话、成都话、重庆话、湖南话、上海话、粤语、闽南话。

## 特点

- **默认普通话**：未加载方言前，AI 以普通话对话，不强行方言。
- **按需加载**：`/fangyan <方言>` 显式加载某一方言；同一时间只用一种。
- **token 极简**：十三方言全套资料卧 `references/` 磁盘，唯所用方言入上下文（加载后约 +600 token）。
- **得体为先**：亲密度决定浓度、红线词默认关、文化不错位——地道而不冒犯。

## 安装

```
/plugin marketplace add https://github.com/F2077/fangyan
/plugin install fangyan@fangyan-marketplace
```

## 用法

```
/fangyan 东北话      # 加载东北话（亦可用 dongbei / db）
/fangyan 粤语        # 加载粤语（亦可用 yue / gd）
/fangyan             # 列出十三方言及别名
```

加载后，AI 即以该方言对话。落盘之物（commit、代码、文档）仍用平实普通话/英文。

## 资料来源

十三方言调研报告（语音/词汇/语法/句式/对话示例/习俗）、`方言灵魂.json`、`方言字典.json`（390 词）、民间习俗与大事模板，俱在 `references/`，模型按需取阅。

## 许可

MIT
````

- [ ] **Step 2: 写 LICENSE（MIT）**

```
MIT License

Copyright (c) 2026 F2077

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: 提交**

```bash
git add README.md LICENSE
git commit -m "docs: add README and MIT license"
```

---

## Task 10: 端到端验收 + 隐私扫描

**Files:**
- Create: `tests/run_all.sh`
- Verify: 全部测试通过、隐私扫描无高危

- [ ] **Step 1: 写汇总测试 tests/run_all.sh**

```bash
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
bash tests/test_gen.sh
bash tests/test_session_start.sh
bash tests/test_fangyan.sh
echo "=== ALL TESTS PASS ==="
```

```bash
chmod +x tests/run_all.sh
```

- [ ] **Step 2: 跑全部测试**

Run: `bash tests/run_all.sh`
Expected: 三项 `PASS` + `=== ALL TESTS PASS ===`

- [ ] **Step 3: 抽查 `/fangyan 粤语` 输出**

Run:
```bash
cd /home/work/F2077/others/fangyan
bash commands-handlers/fangyan.sh 粤语 | head -30
```
Expected: 含「粤语对话模式」「灵魂词」（唔该/食/嘅…）「红线」「self-check」。

- [ ] **Step 4: 隐私扫描（push 前必做）**

Run:
```bash
cd /home/work/F2077/others/fangyan
# 高危 pattern（应为空——方言词非密钥）
git diff main..HEAD --diff-filter=d | grep -nE 'sk-|AKIA|ghp_|xoxb-|-----BEGIN .* PRIVATE KEY-----|password=|secret=|token=' || echo "无高危命中"
# 自定义关键字（姓名/邮箱/内网域）
git diff main..HEAD | grep -nE 'zhangfan|385741668|ffzone@gmail|ubizhang|\.58\.com|\.360\.cn|\.qihoo' || echo "无自定义命中"
```
Expected: `无高危命中` + `无自定义命中`（方言资料含大量中文词，应不触发；若误报，人工甄别）。

- [ ] **Step 5: 提交测试汇总**

```bash
git add tests/run_all.sh
git commit -m "test: add end-to-end test runner"
```

- [ ] **Step 6: 终态自检（照 spec §7 验收清单）**

逐条核对（人工）：
- [ ] `bash hooks-handlers/session-start.sh` 输出合法 JSON（`python3 -m json.tool` 通过），约 150 token
- [ ] 注入开篇定"未加载则普通话"+ 告 `/fangyan` 用法
- [ ] `bash commands-handlers/fangyan.sh 东北话` 输出 = 元规则.md + 方言注入/东北话.md
- [ ] 方言片段开篇定"默认之声"+ 禁标签前缀，self-check 末条验之
- [ ] 方言片段声明落盘平实、技术术语保留
- [ ] 未知方言 → 友好提示 + 列可选；无参 → 列十三方言别名表
- [ ] `hooks.json` 用 `${CLAUDE_PLUGIN_ROOT}`，未写死路径
- [ ] handler `exit 0`
- [ ] `gen-dialect-snippets.py` 从灵魂 json 生成 13 片段，数据准确
- [ ] references/ 十三报告 + 字典 + 习俗 + 行为规则 + 灵魂 json 齐备
- [ ] `plugin.json`/`marketplace.json` description 含"方言"关键词

---

## Self-Review（计划自检）

**1. Spec coverage（对照 spec §1–4、§6、§7）：**
- §1 三层机制 → Task 4（层一 SessionStart）+ Task 6（层二 /fangyan）+ references 全在（层三 Read）。✓
- §2 仓结构 → Task 1–9 覆盖所有文件。✓
- §3 注入指令 → Task 2（元规则）+ Task 3（片段骨架）+ Task 4（SessionStart 草稿）+ Task 6（二元拼接）。✓
- §4 资料组织 → Task 1（导入）+ Task 3（生成）。✓
- §6 分支 → 本 plan 在 `feat/fangyan-plugin` 分支执行（展示层 Plan B 另起）。✓
- §7 验收 → Task 10。✓
- §5 落地页 → **本 plan 不含**，属 Plan B（展示层，后续）。明确划出。

**2. Placeholder scan：** 无 TBD/TODO；所有代码步骤含完整代码；测试含完整断言。Task 7 command `!` 语法标注验证点（非占位，给了具体语法 + fallback 指引）。✓

**3. Type consistency：** `map_dialect` 在 fangyan.sh 定义、test_fangshan 调用一致；`元规则.md` / `方言注入/` 路径在 Task 2/3/6 一致；`gen-dialect-snippets.py` 字段名（soul_words_role/signature_sentences/red_line_words/do_not/default_concentration）与 `方言灵魂.json` 实际结构一致（已验证）。✓

---

*Plan B（落地页展示层）待本 plan 完成后，于 `docs/theme-page` 分支另撰。*
