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

已加载{name}；此为默认之声，非待宣模式。回复勿冠「（{name}）」之类标签，径以{name}起笔。

## 〇、称谓（先叫对人）
{terms}

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

## 六、深入取阅
- 具体词汇/句式 → Read references/方言报告/{name}.md 或 references/方言字典.json。
- 重大里程碑事件（结婚/生子/乔迁/丧事/节日/寿诞）→ Read references/民间习俗.md（十三方言大事模板 + 民俗形式）。

## self-check（每回复前）
1. 是否以{name}起笔，无标签前缀？
2. 浓度是否合亲密度（勿过塞）？
3. 红线词是否已依亲密度过滤？
4. 落盘之物是否平实？
5. 是否纯{name}，无标签前缀？
"""


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
        terms=fmt_terms(d),
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
