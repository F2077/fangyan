# fangyan 情绪价值增强 + 不退化保证 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为方言插件加上「情绪价值」四件套——不退化硬约束、性别中立的称谓、工程里程碑庆祝、克制 Emoji——同时保证编程能力零退化。

**Architecture:** 数据落在 `方言灵魂.json` 新字段 `terms_of_address`，由既有 `gen-dialect-snippets.py` 渲染进片段顶部「称谓」段；不退化机制与里程碑庆祝落在 `元规则.md`（`/fangyan` cat 的共享层）。零改 handler、零改 hooks、零改 command。默认普通话架构不变（未加载方言时零影响）。

**Tech Stack:** python3 标准库 json（数据写入 + 片段生成）、bash（测试）、markdown（注入内容）、既有 Claude Code 插件结构。

**对应 spec:** `docs/superpowers/specs/2026-06-27-fangyan-emotional-value-design.md`（已批准）。

---

## Global Constraints

- **工作目录**：`/home/work/F2077/others/fangyan`；当前分支 `feat/fangyan-plugin`（在其上继续，不切分支）。
- **commit 规范**：英文 subject + Conventional Commits（`feat/...`、`test/...`、`docs/...`），imperative，≤72 字符；末尾**恰好一条** `Co-Authored-By: glm-5.2`（无邮箱、无其它 trailer）。
- **零改 handler/hooks/command**：本计划只动 `references/`、`scripts/`、`tests/`。`commands-handlers/fangyan.sh`、`hooks-handlers/session-start.sh`、`commands/fangyan.md`、`hooks/hooks.json` 一律不动。
- **不退化是硬约束**：所有新增注入内容仅影响对话层；落盘之物（含本计划产出的 commit message）平实、零 Emoji。
- **JSON 写入**：`json.dump(..., ensure_ascii=False, indent=2)`，保留中文字符与 2-space 缩进。

---

## File Structure

| 文件 | 动作 | 责任 |
|---|---|---|
| `references/方言灵魂.json` | Modify | 13 方言各加 `terms_of_address`（中立默认 + 性别变体） |
| `scripts/gen-dialect-snippets.py` | Modify | 模板顶部渲染「〇、称谓」段；新增 `fmt_terms` |
| `references/方言注入/*.md` ×13 | Regenerate | 重新生成（顶部含称谓段） |
| `references/元规则.md` | Modify | 新增「工程里程碑庆祝」段；「边界」段升级为「落盘不退化」段 |
| `tests/test_gen.sh` | Modify | 增断言：称谓/老铁中立/性别变体/fangyan.local.md |
| `tests/test_meta.sh` | Create | 新建：验 元规则 含不退化 + 里程碑 + 术语白名单 |
| `tests/run_all.sh` | Modify | 加入 `test_meta.sh` |

---

## Task 1: 为 13 方言写入 terms_of_address（数据）

**Files:**
- Modify: `references/方言灵魂.json`（每方言 dialect 对象加 `terms_of_address`）

**Interfaces:**
- Produces: `方言灵魂.json.dialects[*].terms_of_address`，schema 为 `{polite, friendly, intimate, self, male_note?, female_note?}`（字符串）。Task 2 的 `fmt_terms` 消费它。

- [ ] **Step 1: 写校验并确认当前缺失（红灯）**

Run:
```bash
cd /home/work/F2077/others/fangyan
python3 -c "
import json
d = json.load(open('references/方言灵魂.json', encoding='utf-8'))
miss = [n for n,v in d['dialects'].items() if 'terms_of_address' not in v]
assert not miss, f'缺 terms_of_address: {miss}'
db = d['dialects']['东北话']['terms_of_address']
assert db['friendly'] == '老铁', f'东北话 friendly 应为中立 老铁，实为 {db[\"friendly\"]}'
print('OK')
" || echo "(red as expected — terms_of_address 尚未写入)"
```
Expected: 报 `缺 terms_of_address`（红）。

- [ ] **Step 2: 用脚本写入 13 方言 terms_of_address**

写临时脚本 `/tmp/add_terms.py`：
```python
import json
from pathlib import Path

# 13 方言称谓表（中立默认恒在；性别变体按需）。来源：spec §5.4，curate 自语料。
TERMS = {
    "北京话": {"polite":"您内","friendly":"哥们儿","intimate":"磁器","self":"咱","male_note":"爷们儿","female_note":"姐们儿"},
    "天津话": {"polite":"您","friendly":"姐姐","intimate":"哥们儿","self":"咱","male_note":"哥们儿","female_note":"姐姐"},
    "东北话": {"polite":"师傅","friendly":"老铁","intimate":"老铁","self":"咱","male_note":"大兄弟","female_note":"大妹子／老妹儿"},
    "山东话": {"polite":"老师儿","friendly":"恁","intimate":"恁","self":"俺","male_note":"爷们儿","female_note":"妮儿"},
    "陕西话": {"polite":"乡党","friendly":"乡党","intimate":"乡党","self":"额／俺","male_note":"后生","female_note":"女子"},
    "河南话": {"polite":"恁","friendly":"恁","intimate":"哥们儿","self":"俺","male_note":"兄弟","female_note":"妮儿"},
    "云南话": {"polite":"嬢嬢","friendly":"老乡","intimate":"老表","self":"我","male_note":"老表","female_note":"嬢嬢"},
    "成都话": {"polite":"师傅","friendly":"兄弟伙","intimate":"嬢嬢","self":"我","male_note":"兄弟伙","female_note":"嬢嬢"},
    "重庆话": {"polite":"师傅","friendly":"崽儿","intimate":"龟儿（朋友间昵）","self":"老子／我","male_note":"崽儿","female_note":"妹儿"},
    "湖南话": {"polite":"师傅","friendly":"朋友","intimate":"满哥","self":"我","male_note":"满哥","female_note":"妹子"},
    "上海话": {"polite":"侬","friendly":"侬","intimate":"侬","self":"阿拉"},
    "粤语":   {"polite":"唔该／先生","friendly":"老友记","intimate":"老友记","self":"我","male_note":"靓仔","female_note":"靓女"},
    "闽南话": {"polite":"恁","friendly":"汝","intimate":"汝","self":"阮"},
}

p = Path("references/方言灵魂.json")
data = json.loads(p.read_text(encoding="utf-8"))
assert set(TERMS) == set(data["dialects"]), f"方言集合不一致: {set(TERMS) ^ set(data['dialects'])}"
for name, d in data["dialects"].items():
    new = {}
    for k, v in d.items():
        new[k] = v
        if k == "name_en":           # 插在 name_en 之后，显眼
            new["terms_of_address"] = TERMS[name]
    new.setdefault("terms_of_address", TERMS[name])
    data["dialects"][name] = new
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("written")
```

Run:
```bash
cd /home/work/F2077/others/fangyan
python3 /tmp/add_terms.py
```
Expected: `written`。

- [ ] **Step 3: 重跑校验（绿灯）+ 抽查东北话/粤语/闽南话**

Run:
```bash
cd /home/work/F2077/others/fangyan
python3 -c "
import json
d = json.load(open('references/方言灵魂.json', encoding='utf-8'))
miss = [n for n,v in d['dialects'].items() if 'terms_of_address' not in v]
assert not miss, f'缺: {miss}'
db = d['dialects']['东北话']['terms_of_address']
assert db['friendly'] == '老铁', db['friendly']
assert d['dialects']['粤语']['terms_of_address']['female_note'] == '靓女'
assert 'male_note' not in d['dialects']['闽南话']['terms_of_address']  # 性别中立，无变体
print('OK 13 dialects, 东北话 friendly=老铁')
"
```
Expected: `OK 13 dialects, 东北话 friendly=老铁`。

- [ ] **Step 4: 提交**

```bash
cd /home/work/F2077/others/fangyan
git add references/方言灵魂.json
git commit -m "feat(references): add gender-neutral terms_of_address to soul json

Adds terms_of_address (polite/friendly/intimate/self neutral defaults
+ optional male_note/female_note) to all 13 dialects, curated from the
corpus. Neutral primaries chosen so the plugin never assumes the user's
gender (东北话 老铁, 山东话 老师儿, 粤语 老友记, 上海话 侬, 闽南话 汝).
性别中立方言（上海/闽南）省略 *_note.

Co-Authored-By: glm-5.2"
```

---

## Task 2: gen 脚本渲染「〇、称谓」段（TDD）

**Files:**
- Modify: `scripts/gen-dialect-snippets.py`（TEMPLATE 顶部加称谓段 + 新增 `fmt_terms`）
- Modify: `tests/test_gen.sh`（增断言）
- Regenerate: `references/方言注入/*.md` ×13

**Interfaces:**
- Consumes: Task 1 的 `terms_of_address`。
- Produces: 每个片段文件顶部 `## 〇、称谓（先叫对人）` 段。

- [ ] **Step 1: 改测试加断言（红灯先行）**

把 `tests/test_gen.sh` 的关键字循环改为：
```bash
for kw in "默认之声" "灵魂词" "签名句" "浓度" "红线" "self-check" "整" "民间习俗" "里程碑" "称谓" "老铁" "大兄弟" "fangyan.local.md"; do
  grep -q "$kw" "$F" || { echo "FAIL: 东北话片段缺「$kw」"; exit 1; }
done
```
（即在原列表尾追加 `"称谓" "老铁" "大兄弟" "fangyan.local.md"`。）

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/test_gen.sh`
Expected: `FAIL: 东北话片段缺「称谓」`（红）。

- [ ] **Step 3: 改 gen 脚本——模板顶部插称谓段 + fmt_terms**

在 `scripts/gen-dialect-snippets.py` 中：

(a) `TEMPLATE` 顶部（`已加载{name}…起笔。` 之后、`## 一、灵魂词` 之前）插入：
```

## 〇、称谓（先叫对人）
{terms}
```

(b) 新增 `fmt_terms` 函数（放在 `fmt_soul_words` 之前）：
```python
def fmt_terms(d):
    t = d.get("terms_of_address", {})
    lines = [
        f"- 尊称/陌生：{t.get('polite', '')}",
        f"- 熟人/朋友：{t.get('friendly', '')}",
        f"- 铁哥们/私下：{t.get('intimate', '')}",
        f"- 自称：{t.get('self', '')}",
    ]
    male, female = t.get("male_note"), t.get("female_note")
    if male or female:
        parts = []
        if male:
            parts.append(f"已知男 → {male}")
        if female:
            parts.append(f"已知女 → {female}")
        lines.append("- " + "；".join(parts))
    lines.append("")
    lines.append("勿预设性别，默认中立称谓；从对话线索判断后再换；用户曾明示或于 .claude/fangyan.local.md 固定（address_gender）则从之。浓度愈高用愈亲昵的称谓。")
    return "\n".join(lines)
```

(c) `gen_one` 的 `TEMPLATE.format(...)` 调用新增一项 `terms=fmt_terms(d),`。

- [ ] **Step 4: 重新生成并跑测试（绿灯）**

Run:
```bash
cd /home/work/F2077/others/fangyan
python3 scripts/gen-dialect-snippets.py references/方言灵魂.json references/方言注入
bash tests/test_gen.sh
```
Expected: `生成 13 个方言片段 → …` 且 `PASS gen`。

- [ ] **Step 5: 抽查东北话称谓段**

Run:
```bash
cd /home/work/F2077/others/fangyan
sed -n '/## 〇、称谓/,/## 一、灵魂词/p' references/方言注入/东北话.md
```
Expected: 含 `- 熟人/朋友：老铁`、`已知男 → 大兄弟；已知女 → 大妹子／老妹儿`、`fangyan.local.md`。

- [ ] **Step 6: 提交**

```bash
cd /home/work/F2077/others/fangyan
git add scripts/gen-dialect-snippets.py tests/test_gen.sh references/方言注入/
git commit -m "feat(snippets): render gender-neutral 称谓 section at snippet top

gen-dialect-snippets.py renders a 称谓 section from terms_of_address
at the top of each snippet (mirroring wen's 代字 Principle 1). Defaults
are gender-neutral; *_note variants render as '已知男/女 → …'. The
section carries the no-assumption rule + .claude/fangyan.local.md pin
note. test_gen.sh locks 称谓/老铁/大兄弟/fangyan.local.md.

Co-Authored-By: glm-5.2"
```

---

## Task 3: 元规则——里程碑庆祝 + 落盘不退化（TDD）

**Files:**
- Modify: `references/元规则.md`（新增「工程里程碑庆祝」段；「边界」段升级为「落盘不退化」段）
- Create: `tests/test_meta.sh`

**Interfaces:**
- Produces: `元规则.md` 含两个新段；`/fangyan` handler 既有的 `cat 元规则.md` 会自动带上（handler 不改）。

> 设计决定（对 spec §11 的精确化）：既有「## 边界」段当前内容就是「落盘平实 + 术语保留」（非退化雏形）。为免重复，本任务将其**替换**为更强的「## 落盘不退化」段（内容完全覆盖旧边界并升级到文言级）。spec §11「保留边界」是基于对旧边界内容的误述；合并既满足 spec「强化不退化」的意图，又避免两段重复。

- [ ] **Step 1: 写失败测试 tests/test_meta.sh**

```bash
#!/usr/bin/env bash
# 验证 元规则.md 含：落盘不退化（术语白名单/仅对话层/技术判断零退化）+ 工程里程碑庆祝。
set -e
cd "$(dirname "$0")/.."
M="references/元规则.md"
for kw in "落盘不退化" "术语白名单" "工程里程碑庆祝" "仅对话层" "技术判断零退化" "function" "API" "git" "npm" "勿凡回合皆庆"; do
  grep -q "$kw" "$M" || { echo "FAIL: 元规则缺「$kw」"; exit 1; }
done
echo "PASS meta"
```

```bash
cd /home/work/F2077/others/fangyan
chmod +x tests/test_meta.sh
```

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/test_meta.sh`
Expected: `FAIL: 元规则缺「落盘不退化」`（红）。

- [ ] **Step 3: 在 元规则.md「## 跟随用户」段之后、「## 边界」段之前，插入「工程里程碑庆祝」段**

用 Edit，old_string 取「## 跟随用户」段末尾到「## 边界」标题的衔接处。将：
```
用户以某方言发言，则随之；用户明确要普通话，则回普通话。同一时间只用一种方言，勿混搭。

## 边界
```
替换为：
```
用户以某方言发言，则随之；用户明确要普通话，则回普通话。同一时间只用一种方言，勿混搭。

## 工程里程碑庆祝

遇真正的工程里程碑（大 feature 落成、围因已久的 bug 修复、发版、长调试后测试全绿等；AI 自识或用户明示），以当前方言区的民俗形式（东北二人转、云南山歌、陕西秦腔、粤语饮茶舞狮、北京相声…）庆祝一两句，化用到编程语境——取其庆祝味与符号，勿照搬人生仪式。

- 仅对话层：庆祝只在口头，绝不写进落盘之物。
- 勿凡回合皆庆：只对真里程碑，普通回合不庆。
- Emoji 点缀：可缀一个对应民俗符号的 Emoji（粤语🍵🦁、云南🍄🔥、东北🍺、闽南🏮、陕西🍜…），不每句撒；正式/商务免。
- 素材：具体民俗形式与符号 → Read references/民间习俗.md §1/§2。

## 边界
```

- [ ] **Step 4: 把「## 边界」段替换为「## 落盘不退化」段**

用 Edit，将：
```
## 边界

落盘之物（commit、代码、文档）用平实普通话/英文；技术术语（function、API、git、npm、docker 等）保留原文。
```
替换为：
```
## 落盘不退化（硬约束·同文言插件）

本模式仅影响口语对话。方言腔调、民俗庆祝、Emoji 一概不渗入执行层。

- **术语白名单原样保留**：function/API/git/npm/docker/cache/log/HTTP/parameter/commit/branch/merge 等计算术语保持原文，不方言化、不翻译。只把“一般口语词”方言化（做→整/搞、看→瞅/睇、很→贼/甚…）。
- **落盘之物平实**：代码、命令、commit、文档、配置、API 调用、技术判断——一律平实普通话/英文，零方言味、零 Emoji。
- **技术判断零退化**：分析、方案、debug、取舍的准确性与严谨度，不得因方言腔调打折扣。
- **冲突让位**：与他插件冲突时，本模式让位。

self-check（落盘前）：术语是否原样？落盘物是否零方言味零 Emoji？技术判断是否准确未受影响？
```

- [ ] **Step 5: 跑测试（绿灯）**

Run: `bash tests/test_meta.sh`
Expected: `PASS meta`。

- [ ] **Step 6: 确认既有 handler 测试不回归**

Run: `bash tests/test_fangyan.sh`
Expected: `PASS fangyan`（元规则仍含「得体 > 地道」「五黄金法则」，handler 不变）。

- [ ] **Step 7: 提交**

```bash
cd /home/work/F2077/others/fangyan
git add references/元规则.md tests/test_meta.sh
git commit -m "feat(meta): add milestone celebration + wen-grade non-degradation

元规则.md gains an 工程里程碑庆祝 section (folk-form celebration of
real engineering milestones, dialogue-only, sparing Emoji) and the
terse 边界 section is replaced by a wen-grade 落盘不退化 section:
terminology whitelist, dialogue-only, zero technical-judgment decay,
conflict-yields, plus a pre-disk self-check. test_meta.sh locks the
required keywords and whitelist samples.

Co-Authored-By: glm-5.2"
```

---

## Task 4: 测试汇总 + 端到端验收

**Files:**
- Modify: `tests/run_all.sh`（加入 test_meta）

- [ ] **Step 1: run_all.sh 加入 test_meta**

将 `tests/run_all.sh` 的测试序列改为：
```bash
bash tests/test_gen.sh
bash tests/test_session_start.sh
bash tests/test_fangyan.sh
bash tests/test_meta.sh
echo "=== ALL TESTS PASS ==="
```

- [ ] **Step 2: 跑全部测试**

Run: `bash tests/run_all.sh`
Expected: 四项 `PASS`（gen / session-start / fangyan / meta）+ `=== ALL TESTS PASS ===`。

- [ ] **Step 3: 端到端抽查 `/fangyan 东北话` 完整输出**

Run:
```bash
cd /home/work/F2077/others/fangyan
bash commands-handlers/fangyan.sh 东北话 | sed -n '1,40p'
```
Expected: 顶部为元规则（含「五黄金法则」「工程里程碑庆祝」「落盘不退化」），`---` 分隔后片段顶部为「〇、称谓（先叫对人）」含 `熟人/朋友：老铁`、`已知男 → 大兄弟；已知女 → 大妹子／老妹儿`。

- [ ] **Step 4: token 增量抽估**

Run:
```bash
cd /home/work/F2077/others/fangyan
echo "元规则 字符数: $(wc -m < references/元规则.md)"
echo "东北话片段字符数: $(wc -m < references/方言注入/东北话.md)"
```
Expected: 元规则 < ~1200 字符（~+90 token 增量可控）；片段 < ~1100 字符（称谓段 ~+60 token）。

- [ ] **Step 5: 提交**

```bash
cd /home/work/F2077/others/fangyan
git add tests/run_all.sh
git commit -m "test: include meta-rules test in run_all

run_all.sh now runs test_meta.sh alongside gen/session-start/fangyan,
giving a single entry point for the full behavior + emotional-value
test suite.

Co-Authored-By: glm-5.2"
```

- [ ] **Step 6: 终态自检（照 spec §10 验收清单）**

逐条核对（人工）：
- [ ] `元规则.md` 含「落盘不退化」段（术语白名单 + 仅对话层 + 收尾让位 + self-check）。
- [ ] `元规则.md` 含「工程里程碑庆祝」段（仅对话层 + 勿凡回合皆庆 + Emoji 克制 + 指向 民间习俗.md）。
- [ ] `方言灵魂.json` 13 方言各含 `terms_of_address`（中立默认 + 可选 `*_note`）。
- [ ] 片段顶部「〇、称谓」段；东北话默认中立「老铁」（非「大兄弟」）。
- [ ] 性别策略：默认中立、被动推断、`.claude/fangyan.local.md` 可选固定（片段提及、零改 handler）。
- [ ] gen/meta/handler 测试全过；现有套件不回归。
- [ ] 运行时人工验：落盘物零方言味零 Emoji、术语原样、技术判断零退化。

---

## Self-Review（计划自检）

**1. Spec coverage（对照 spec §1–§11）：**
- §3 组件①不退化 → Task 3（元规则 落盘不退化段 + test_meta）。✓
- §3 组件②称谓（含 §5.1 性别策略、§5.2 schema、§5.3 渲染、§5.4 表）→ Task 1（数据）+ Task 2（渲染 + 测试）。✓
- §3 组件③工程里程碑庆祝 → Task 3（元规则段）。✓
- §3 组件④Emoji（并入③）→ Task 3 Step 3 工程里程碑庆祝段内含 Emoji 行。✓
- §9 测试 → Task 2（gen）+ Task 3（meta 新建）+ Task 4（run_all + e2e）。✓
- §10 验收 → Task 4 Step 6。✓
- §11 与既有工作关系（ba9dbc7 保留、边界合并）→ Task 3 设计决定段已述。✓

**2. Placeholder scan：** 无 TBD/TODO；每步含完整代码/命令/期望；称谓 JSON 13 方言全列出；元规则两段完整文。✓

**3. Type consistency：** `terms_of_address` schema（polite/friendly/intimate/self/male_note?/female_note?）在 Task 1 写入、Task 2 `fmt_terms` 读取、test 断言一致；`fmt_terms` 函数名在 Task 2 Step 3 定义且仅本任务用；`## 〇、称谓` 标题在 Task 2 渲染、Task 4 Step 3 抽查一致。✓

---

*运行时不退化与性别适配为人工验收项（非自动化），见 Task 4 Step 6。*
