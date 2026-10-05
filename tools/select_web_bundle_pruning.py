#!/usr/bin/env python3
"""Choose old Pages bundles by publication history, never by commit spelling.

Run in the staged gh-pages worktree. This only prints basenames; the publisher
owns deletion. The current bundle may be uncommitted and is always retained.
"""
import re
import subprocess
import sys
from pathlib import Path


def choose(current: str, keep: int) -> list[str]:
    if not re.fullmatch(r"game-[0-9a-f]+", current) or keep < 0:
        raise ValueError("invalid current bundle or retention count")
    existing = {p.stem for p in Path('.').glob('game-*.pck')
                if re.fullmatch(r"game-[0-9a-f]+", p.stem)}
    if current not in existing:
        raise ValueError("current staged PCK is missing")
    if keep == 0 or len(existing) <= keep:
        return []
    shallow = subprocess.check_output(
        ['git', 'rev-parse', '--is-shallow-repository'], text=True).strip()
    if shallow == 'true':
        print('[publish] WARNING: shallow bundle history; retaining all bundles',
              file=sys.stderr)
        return []
    history = subprocess.check_output(
        ['git', 'log', '--first-parent', '--format=', '--name-only',
         '--diff-filter=AM', '--no-renames', '--', 'game-*.pck'], text=True)
    newest = [current]
    for line in history.splitlines():
        name = line.removesuffix('.pck')
        if line.endswith('.pck') and name in existing and name not in newest:
            newest.append(name)
    # A shallow/missing history cannot prove which unranked bundle is oldest.
    # Preserve everything instead of guessing and deleting a recent version.
    if set(newest) != existing:
        print('[publish] WARNING: incomplete bundle history; retaining all bundles',
              file=sys.stderr)
        return []
    retained = set(newest[:keep])
    return sorted(existing - retained)


if __name__ == '__main__':
    try:
        for name in choose(sys.argv[1], int(sys.argv[2])):
            print(name)
    except (ValueError, IndexError, subprocess.CalledProcessError) as error:
        print(f'[publish] ERROR: cannot select old bundles: {error}', file=sys.stderr)
        sys.exit(1)
