#!/usr/bin/env bash
# 完整性：方言灵魂.json schema 齐全 + 已提交片段与 gen 输出无漂移。
set -e
cd "$(dirname "$0")/.."

# 1) schema：每方言必备字段（缺字段会让 fmt_* 静默生成空段）
python3 -c "
import json
d = json.load(open('references/方言灵魂.json', encoding='utf-8'))
req = ['soul_words', 'soul_words_role', 'signature_sentences',
       'red_line_words', 'do_not', 'default_concentration', 'terms_of_address']
for n, dd in d['dialects'].items():
    miss = [k for k in req if k not in dd]
    assert not miss, f'{n} 缺字段: {miss}'
# terms_of_address 子字段
for n, dd in d['dialects'].items():
    t = dd['terms_of_address']
    for k in ('polite', 'friendly', 'intimate', 'self'):
        assert k in t, f'{n}.terms_of_address 缺 {k}'
print('schema ok')
"

# 2) drift：HEAD 提交版片段 == 现场生成版（改 方言灵魂.json 后须重生成并提交）
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
python3 scripts/gen-dialect-snippets.py references/方言灵魂.json "$TMP/s" >/dev/null
for f in references/方言注入/*.md; do
  b=$(basename "$f")
  diff -q <(git show "HEAD:references/方言注入/$b") "$TMP/s/$b" >/dev/null 2>&1 || {
    echo "FAIL: $b 漂移（HEAD 提交版 ≠ gen 输出；改了 方言灵魂.json 后忘重生成并提交？）" >&2
    exit 1
  }
done

# 3) single-source：每个 方言灵魂.json 方言名都能被 dialect-lookup.py 解析（防止清单与 JSON 漂移）
python3 -c "
import json, subprocess
d = json.load(open('references/方言灵魂.json', encoding='utf-8'))
for n in d['dialects']:
    r = subprocess.run(['python3', 'scripts/dialect-lookup.py', 'resolve', n], capture_output=True, text=True)
    assert r.returncode == 0 and r.stdout.strip() == n, f'{n} 解析失败: rc={r.returncode} out={r.stdout!r}'
print('single-source ok')
"

echo "PASS integrity"
