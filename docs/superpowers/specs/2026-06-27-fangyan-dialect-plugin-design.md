# fangyan · 方言对话插件 设计文档

> **日期**：2026-06-27
> **状态**：设计已与用户确认，待出实施计划
> **协同**：claude（glm-5.2）与 F2077
> **参考**：`wen` 仓 PLAYBOOK（同源 hook + 落地页范式）；方言调研报告（十三方言资料）

---

## 0. 一句话定位

一个 **SessionStart hook 注入极轻说明** + **slash command `/fangyan <方言>` 按需加载单一方言** 的 Claude Code 方言对话插件，配一座「一方水土，一方言」主题静态落地页。

**与 wen 的根本差异**：wen 是单一语音（文言）每会话注入；fangyan 是 **十三方言按需加载**——默认不加载任何方言（普通话对话），唯用户以命令指定之方言方入上下文，余十二绝不混入。token 极简是核心约束。

---

## 1. 核心机制：按需加载三层

三条定则（用户确认）：

1. **默认不加载任何方言**——未指定前 AI 以普通话对，绝不自行方言。
2. **同一时间惟用一种方言**——用户以 `/fangyan <方言>` 显式指定（非智能跟随）。
3. **token 之效**——十三方言资料虽备，唯所用方言入上下文。

三层数据流：

- **层一 · SessionStart**：注入极轻说明（~150 token）。普通话对，告 `/fangyan` 用法与十三可选方言。
- **层二 · `/fangyan <方言>`**：handler cat `references/元规则.md` + `references/方言注入/<方言>.md`（+~600 token）。模型此后以该方言对。
- **层三 · 深入取阅**：模型按需 `Read` `references/方言报告/<方言>.md`、`方言字典.json`、`民间习俗.md`，用毕即释，不常驻。

token 账本：

| 状态 | 常驻上下文 |
|---|---|
| 未加载方言 | ~150 token |
| 已加载一方言 | ~150 + ~600 ≈ 750 token |
| 深入查询 | 临时 +Read，不累积 |
| 十三方言全套资料（~30 万字） | **永不入默认上下文**，卧 references/ 磁盘 |

---

## 2. 仓结构

```
fangyan/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── hooks/
│   └── hooks.json                  # SessionStart → handler
├── hooks-handlers/
│   └── session-start.sh            # 注入极轻说明（~150 token）
├── commands/
│   └── fangyan.md                  # /fangyan <方言> 命令（frontmatter）
├── commands-handlers/
│   └── fangyan.sh                  # case 别名映射 + cat 元规则+片段
├── references/
│   ├── 元规则.md                   # 通用元规则精华（command 注入，~150 token）
│   ├── 方言注入/                   # ★13 精炼片段（command 注入，每 ~450 token）
│   │   └── 东北话.md … 闽南话.md
│   ├── 方言报告/                   # 13 完整报告（模型按需 Read）
│   │   └── 东北话.md … 闽南话.md
│   ├── 方言灵魂.json               # 数据源（生成片段 + 按需 Read）
│   ├── 方言字典.json               # 390 词（按需 Read）
│   ├── 民间习俗.md                 # 习俗 + 大事模板（按需 Read）
│   └── 行为规则.md                 # 完整行为规范（按需深读）
├── scripts/
│   └── gen-dialect-snippets.py     # 从 方言灵魂.json 生成 方言注入/*.md
├── docs/                           # 主题落地页
│   ├── index.html
│   ├── style.css
│   └── script.js
├── .github/workflows/deploy-pages.yml
├── README.md  LICENSE  PLAYBOOK.md
└── .gitignore
```

---

## 3. 注入指令设计

### 3.1 SessionStart 极轻指令（~150 token）

`session-start.sh` 以 python3 拼 JSON 输出 `additionalContext`（承 wen，避转义地狱，直接写 UTF-8 中文）：

```
本会话已启用「方言」插件，但尚未加载任何方言。当前以普通话对话。

加载方言：运行 /fangyan <方言名>，如 /fangyan 东北话。
可选（十三种）：东北话、北京话、天津话、山东话、陕西话、河南话、
  云南话、成都话、重庆话、湖南话、上海话、粤语、闽南话。

加载某方言后，方以该方言对话；未加载前勿自行切换。
落盘之物（commit、代码、文档）一律平实普通话/英文，不受方言影响。
```

### 3.2 `/fangyan` 二元拼接

command 注入 = 两文件之合：

- `references/元规则.md`（通用五黄金法则，~150 token，单点维护）
- `references/方言注入/<方言>.md`（方言特色，~450 token）

方言片段**只**讲该方言特色，不重复通用规则。切换方言时元规则随之重注（自洽且强化）。

### 3.3 方言片段统一骨架（十三份同构）

模板固定段 + json 可变段：

```
# <方言>对话模式
[开篇] 已加载 <方言>；此为默认之声，非待宣模式。勿冠「（方言）」标签，径以 <方言> 起笔。  ← 固定
一、灵魂词（先打开）          ← json: soul_words + role
二、签名句（语气参照）        ← json: signature_sentences 选 3-5
三、浓度策略                  ← json: default_concentration + "得体>地道"
四、红线词（默认关）          ← json: red_line_words + 亲密度门槛
五、禁忌 do_not               ← json: do_not
六、边界                      ← 固定：落盘平实 / 技术术语保留 / 用户要普通话则回
七、深入取阅                  ← 固定：指向 references/方言报告 与 方言字典.json
self-check（五条，末条验无标签前缀）  ← 固定
```

### 3.4 样例：东北话片段（缩略）

```
# 东北话对话模式
已加载东北话；此为默认之声。勿冠标签，径以东北话起笔。
一、灵魂词：整(万能动词)／贼(很)／嘎哈(干嘛)／得劲(爽)／嘚瑟(显摆)
二、签名句：嘎哈呢？／咋整啊？／整一个呗！／贼好！／得劲！／走着！
三、浓度：陌生人30%／熟人55%／朋友80%／铁哥们95%。得体>地道，勿过塞致"装"。
四、红线(亲密度80+私下方开)：傻逼、装逼、扯犊子、完犊子、滚犊子、瘪犊子
五、禁忌：勿"我认为"(用"我寻思")／勿"非常"(用"贼")／勿敬语／"老铁"对非东北人慎用／二人转仅节日聚会
六、边界：落盘平实；技术术语保留；用户要普通话则回
七、深入：Read references/方言报告/东北话.md 或 方言字典.json
self-check：①东北话起笔无标签？②浓度合亲密度？③红线已过滤？④落盘平实？⑤无标签前缀？
```

### 3.5 防坑要点（承 wen PLAYBOOK）

- **坑#1 必防**：每片段开篇定"默认之声"+ 禁标签前缀，self-check 末条验之——否则模型易每条贴「（东北话）」。
- **落盘平实**：commit/代码/文档不受方言污染。
- **handler 直接写 UTF-8 中文**（坑#4），勿 `\uXXXX` 转义。
- **handler `exit 0`**，否则 Claude Code 报 hook 错误。

---

## 4. references 资料组织与片段生成

### 4.1 导入与生成全貌

| 调研原始文件 | → references/ 位置 | 用途 | 入上下文？ |
|---|---|---|---|
| `AI行为规则.md` | `行为规则.md` ＋ 凝练出 `元规则.md` | 完整规范存档；精华注入 | 元规则注入；全文按需 Read |
| `方言灵魂.json` | `方言灵魂.json` | **数据源**（生成片段）+ 查阅 | 否 |
| `方言字典.json` | `方言字典.json` | 390 词查询 | 否，按需 Read |
| `民间习俗形式分析.md` | `民间习俗.md` | 婚/生/迁/丧/节模板 | 否，按需 Read |
| 13 份 `XX话.md` | `方言报告/XX话.md` | 完整方言攻略 | 否，按需 Read |
| *（新生物）* | `方言注入/XX话.md` ×13 | command 注入片段 | **是**（按需单方言） |
| *（新生物）* | `元规则.md` | 通用元规则精华 | **是**（随 command） |

**不入仓**：调研包内 `.claude/settings.local.json`（用户私有项目设置，非插件资产）。

### 4.2 片段生成：`gen-dialect-snippets.py`

python3 标准库 `json`（无需 pip）。开发时运行一次，产物提交：

- 读 `方言灵魂.json` → 逐方言套模板（§3.3 骨架）→ 写 `方言注入/<方言>.md`。
- 固定段写死，可变段自 json 填。
- json 为唯一数据源，更新后可重生，保证十三份准确同构。
- **非运行时构建**——产物即源文件，用户无须运行。

### 4.3 command 别名映射（`fangyan.sh`）

容**中文／拼音／代码**三别名，避错字与空格：

```bash
case "$DIALECT" in
  东北话|dongbei|DB|db) snippet="方言注入/东北话.md" ;;
  北京话|beijing|BJ|bj) snippet="方言注入/北京话.md" ;;
  # … 余十一方言 …
  *) echo "未知方言。可选：东北话/北京话/…/闽南话（亦可用拼音/代码）。"; exit 0 ;;
esac
cat "${ROOT}/references/元规则.md"; echo; cat "${ROOT}/references/${snippet}"
```

无参数 `/fangyan` → 列出十三方言及其别名表。

---

## 5. 落地页（主题 GitHub Page）

### 5.1 融合方案（用户浏览器点选 A/B/C 后定）

- **A 方言版图** 为 hero（主视觉）
- **B 十三方言卡片墙** 为详展
- **C 浓度原理** 为深色点缀段

### 5.2 五节结构

1. **HERO 方言版图**——宣纸底，书法体题额「一方水土，一方言」，十三方言点位一点朱。
2. **十三方言卡片墙**——各方言代表色 + 灵魂词 + 签名句，手写体。
3. **插件原理**（深色段）——浓度色谱 / 亲密度五级 / 红线默认关。
4. **安装**——`/plugin marketplace add` + `/plugin install`。
5. **Footer**——author / license。

### 5.3 配色

- 底：宣纸 `#f4ede0` · 墨 `#2c2c2c` · 朱 `#c0392b`（统全页之气）
- 点缀：十三方言代表色（东北 `#c0392b`／北京 `#8e44ad`／天津 `#16a085`／山东 `#d35400`／陕西 `#a0522d`／河南 `#b8860b`／云南 `#27ae60`／成都 `#e67e22`／重庆 `#e74c3c`／湖南 `#9b59b6`／上海 `#2c7a7b`／粤语 `#f1c40f`／闽南 `#00838f`，实现时可微调避撞色）

### 5.4 字体

- 标题/方言名：「Ma Shan Zheng」马善政书法体（Google Fonts）
- 正文：「Noto Serif SC」思源宋体（Google Fonts）
- 皆 CDN `@import`/`<link>`，零构建。

### 5.5 tagline

**「一方水土，一方言」**——贯穿 plugin description、README、页面题额、meta。

### 5.6 技术约束（承 wen）

- 纯静态，无构建。JS 仅渐进增强，无 JS 时内容全可见。
- `prefers-reduced-motion` 全局降级。
- 移动端断点（760px / 460px），无水平溢出。
- `deploy-pages.yml`：`paths: ['docs/**', '.github/workflows/deploy-pages.yml']`，无 `run:` 注入风险。
- 上线须手点 Settings → Pages → Source = GitHub Actions。

---

## 6. 分支与工作流策略

- **本分支 `feat/fangyan-plugin`**：行为层（hook/handler/command/references/生成脚本/plugin 清单/README）。
- **展示层分支**（后续）：`docs/theme-page`（docs/ 落地页 + 全仓文案统一）。
- 两层耦合低，各自 review/回滚，线性 rebase 入 main。
- commit 规约：Conventional Commits，英文 subject/body/footer，`Co-Authored-By: glm-5.2`（仅模型名，无邮箱）。
- **push 前隐私扫描**：`git diff <base>..HEAD` grep 高危 pattern + 自定义关键字（姓名/邮箱/内网域名）。方言资料含大量中文词汇，扫描时注意区分真实密钥与方言词。

---

## 7. 验收清单

照 wen PLAYBOOK §6 + 方言特有：

- [ ] `bash hooks-handlers/session-start.sh` 输出合法 JSON（`python3 -m json.tool` 通过），~150 token
- [ ] 注入开篇定"未加载则普通话"+ 告 `/fangyan` 用法
- [ ] `/fangyan 东北话` 输出 = 元规则.md + 方言注入/东北话.md 合，合法
- [ ] 方言片段开篇定"默认之声"+ 禁标签前缀，self-check 末条验之
- [ ] 方言片段声明落盘平实、技术术语保留
- [ ] 未知方言 → 友好提示 + 列可选；无参 → 列十三方言别名表
- [ ] `hooks.json` 用 `${CLAUDE_PLUGIN_ROOT}`，未写死路径
- [ ] handler `exit 0`
- [ ] `gen-dialect-snippets.py` 从灵魂 json 生成 13 片段，数据准确
- [ ] references/ 十三报告 + 字典 + 习俗 + 行为规则 + 灵魂 json 齐备
- [ ] `plugin.json`/`marketplace.json` description 含"方言"关键词
- [ ] 落地页：无 JS 内容全可见、reduced-motion 降级、移动端无溢出、字体走 CDN
- [ ] deploy workflow 无 `run:` 注入风险
- [ ] tagline「一方水土，一方言」贯穿一致
- [ ] push 前隐私扫描通过

---

## 8. 待实现时定夺的细节

- plugin name（`fangyan`？）、version、marketplace name、author
- 各方言代表色微调（避撞色，如东北/重庆/湖南皆红系）
- command frontmatter 的 `allowed-tools`（须含 Bash 以执行 handler）
- handler `case` 的拼音/代码别名完整表
- 落地页版图 SVG 的简化中国轮廓画法

---

*本 spec 随实现演化。架构变更同步更新。*
