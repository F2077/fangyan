# fangyan · 方言对话插件

> 一方水土，一方言。

让 Claude Code 按需以**多种方言**对话的插件——东北话、北京话、粤语、闽南话等。方言集以 `references/方言灵魂.json` 为唯一真相源（运行 `/fangyan` 查看全部）。

## 特点

- **默认普通话**：未加载方言前，AI 以普通话对话，不强行方言。
- **按需加载**：`/fangyan <方言>` 显式加载某一方言；同一时间只用一种。
- **token 极简**：各方言全套资料卧 `references/` 磁盘，唯所用方言入上下文（加载后约 +600 token）。
- **得体为先**：亲密度决定浓度、红线词默认关、文化不错位——地道而不冒犯。

## 安装

**运行环境**：需 `python3`（SessionStart 注入与片段生成均依赖）。Claude Code 环境通常自带。

```
/plugin marketplace add https://github.com/F2077/fangyan
/plugin install fangyan@fangyan-marketplace
```

## 用法

```
/fangyan 东北话        # 加载方言（亦可用 dongbei / db）；默认亲密度 80（朋友级）
/fangyan dongbei 95   # 末尾 0-100 覆盖浓度：95 铁哥们、50 收着
/fangyan              # 列出全部方言与用法
```

加载后，AI 即以该方言对话（默认亲密度 80%）。末尾数字 0-100 可临时覆盖浓度。落盘之物（commit、代码、文档）仍用平实普通话/英文。

## 资料来源

各方言调研报告（语音/词汇/语法/句式/对话示例/习俗）、`方言灵魂.json`、`方言字典.json`、民间习俗与大事模板，俱在 `references/`，模型按需取阅。

## 添加方言

方言集以 `references/方言灵魂.json` 为唯一真相源。新增一方言：

1. 在 `方言灵魂.json` 的 `dialects` 加一条目（含 `code`、`aliases`、`soul_words`、`soul_words_role`、`signature_sentences`、`red_line_words`、`do_not`、`default_concentration`、`terms_of_address`）。
2. 放一份 `references/方言报告/<方言>.md` 调研报告。
3. 运行 `python3 scripts/gen-dialect-snippets.py references/方言灵魂.json references/方言注入` 生成片段。
4. （内容性，按需）补 `references/民间习俗.md` 的大事模板与 `references/元规则.md` 法则五的民俗形式映射。

`/fangyan` 可选清单、SessionStart 通知、片段生成、测试计数皆自动跟随，无需另改。

## 许可

MIT
