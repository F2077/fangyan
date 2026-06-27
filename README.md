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
