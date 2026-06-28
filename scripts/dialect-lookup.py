#!/usr/bin/env python3
"""方言清单单一真相源：从 方言灵魂.json 派生方言名/别名解析、清单、未知提示。

用法：
  dialect-lookup.py resolve <输入>   命中 → 打印规范名（exit 0）；未命中 exit 1
  dialect-lookup.py list             打印 /fangyan 无参用法（各方言 + 别名）
  dialect-lookup.py error <输入>     打印未知方言提示（exit 0，用户向帮助）

匹配：中文名精确，或输入（不分大小写）∈ {code} ∪ aliases。
"""
import json
import sys
from pathlib import Path

SOUL = Path(__file__).resolve().parent.parent / "references" / "方言灵魂.json"


def load():
    return json.loads(SOUL.read_text(encoding="utf-8"))["dialects"]


def tokens(dd):
    """该方言可接受的拉丁 token（小写）。中文名由调用方精确匹配。"""
    t = {dd.get("code", "").lower()}
    for a in dd.get("aliases", []):
        t.add(a.lower())
    t.discard("")
    return t


def resolve(inp):
    low = inp.lower()
    for name, dd in load().items():
        if name == inp or low in tokens(dd):
            return name
    return None


def fmt_aliases(dd):
    pool = list(dd.get("aliases", [])) + [dd.get("code", "").lower()]
    pool = [x for x in pool if x]
    return "/".join(pool[:2]) if pool else ""


def cmd_list():
    items = [f"{name}({fmt_aliases(dd)})" for name, dd in load().items()]
    print("未指定方言。用法：/fangyan <方言名>。可选（中文/拼音/代码）：")
    for i in range(0, len(items), 3):
        print("  " + "  ".join(items[i:i + 3]))
    return 0


def cmd_error(inp):
    names = "/".join(load().keys())
    print(f"未知方言「{inp}」。可选：{names}（亦可用拼音或代码）。")
    return 0


def main():
    if len(sys.argv) < 2:
        print("用法：dialect-lookup.py resolve|list|error [<输入>]", file=sys.stderr)
        return 2
    cmd = sys.argv[1]
    if cmd == "list":
        return cmd_list()
    if cmd == "error":
        if len(sys.argv) != 3:
            return 2
        return cmd_error(sys.argv[2])
    if cmd == "resolve":
        if len(sys.argv) != 3:
            return 2
        name = resolve(sys.argv[2])
        if name is None:
            return 1
        print(name)
        return 0
    print(f"未知子命令：{cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
