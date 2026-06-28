#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
bash tests/test_gen.sh
bash tests/test_session_start.sh
bash tests/test_fangyan.sh
bash tests/test_meta.sh
bash tests/test_integrity.sh
echo "=== ALL TESTS PASS ==="
