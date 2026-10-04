#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
case "${1:-test}" in
 test) node "$root/test/yard_decor_prototype/suite.mjs" ;;
 serve) cd "$root"; python3 -m http.server "${PORT:-8768}" --bind 127.0.0.1 ;;
 *) echo 'usage: test | serve' >&2; exit 2 ;;
esac
