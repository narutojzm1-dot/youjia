"""Read-only production audit: mutate only temporary local Git fixtures."""
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
HELPER = Path(__file__).resolve().parents[3] / 'tools/select_web_bundle_pruning.py'

def run(*args, cwd=None, check=True):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if check and result.returncode:
        raise RuntimeError(f'{args!r}: {result.stderr}')
    return result

def git(where, *args):
    return run('git', *args, cwd=where).stdout.strip()

def identity(where):
    git(where, 'config', 'user.name', 'Isolated Audit Fixture')
    git(where, 'config', 'user.email', 'audit@example.invalid')

def commit(where, title):
    git(where, 'add', '.')
    git(where, 'commit', '-m', title)

report = {'scope': 'temporary file:// Git repositories only; immutable production helper copy', 'cases': []}
with tempfile.TemporaryDirectory(prefix='checkout130-audit-fixture-') as temporary:
    root = Path(temporary)
    origin, seed = root / 'origin.git', root / 'seed'
    run('git', 'init', '--bare', str(origin))
    run('git', 'init', '-b', 'main', str(seed))
    identity(seed)
    git(seed, 'remote', 'add', 'origin', origin.as_uri())
    for n in range(3):
        (seed / 'source.txt').write_text(f'{n}\n')
        commit(seed, f'source version {n}')
    source_sha = git(seed, 'rev-parse', 'HEAD')
    source_title = git(seed, 'log', '--format=%s', '-1')
    git(seed, 'push', 'origin', 'main')
    git(seed, 'checkout', '--orphan', 'gh-pages')
    git(seed, 'rm', '-rf', '.')
    for name in ('game-0f', 'game-ffff', 'game-22'):
        (seed / f'{name}.pck').write_bytes(name.encode())
        commit(seed, f'publish {name}')
    page_sha = git(seed, 'rev-parse', 'HEAD')
    git(seed, 'push', 'origin', 'gh-pages')

    for mode in ('full_source', 'shallow_source'):
        source = root / mode
        args = ['git', 'clone', '--single-branch', '--branch', 'main']
        if mode == 'shallow_source':
            args += ['--depth', '1']
        run(*args, origin.as_uri(), str(source))
        assert git(source, 'rev-parse', 'HEAD') == source_sha
        assert git(source, 'log', '--format=%s', '-1') == source_title
        git(source, 'fetch', 'origin', 'gh-pages:refs/remotes/origin/gh-pages')
        pages = root / (mode + '_pages')
        git(source, 'worktree', 'add', str(pages), 'origin/gh-pages')
        assert git(pages, 'rev-parse', 'HEAD') == page_sha
        assert git(pages, 'rev-list', '--first-parent', '--count', 'HEAD') == '3'
        (pages / 'game-3e.pck').write_bytes(b'new staged build')
        result = run('python3', str(HELPER), 'game-3e', '2', cwd=pages)
        selected = result.stdout.splitlines()
        if mode == 'full_source':
            assert selected == ['game-0f', 'game-ffff']
            assert result.stderr == ''
        else:
            assert selected == []
            assert 'shallow bundle history; retaining all bundles' in result.stderr
        report['cases'].append({
            'mode': mode,
            'source_HEAD_and_latest_title_match': True,
            'pages_history_commit_count': 3,
            'pages_HEAD_matches_full_origin': True,
            'repository_is_shallow': git(pages, 'rev-parse', '--is-shallow-repository'),
            'existing_bundles': sorted(p.stem for p in pages.glob('game-*.pck')),
            'keep': 2,
            'selected_for_pruning': selected,
            'warning': result.stderr.strip(),
        })
        # Both missing-current and malformed retention are real nonzero cases.
        for current, keep in [('game-dead', '2'), ('game-3e', '-1')]:
            invalid = run('python3', str(HELPER), current, keep, cwd=pages, check=False)
            assert invalid.returncode == 1
            report['cases'].append({'mode': mode, 'current': current, 'keep': keep,
                                    'exit': invalid.returncode, 'safe_rejection': True})

    # A full Pages-only checkout is a positive control, not a production patch.
    isolated = root / 'isolated_full_pages'
    run('git', 'clone', '--single-branch', '--branch', 'gh-pages', origin.as_uri(), str(isolated))
    (isolated / 'game-3e.pck').write_bytes(b'new staged build')
    result = run('python3', str(HELPER), 'game-3e', '2', cwd=isolated)
    assert result.stdout.splitlines() == ['game-0f', 'game-ffff']
    assert git(isolated, 'rev-parse', '--is-shallow-repository') == 'false'
    assert git(isolated, 'branch', '-r').splitlines() == ['origin/gh-pages']
    report['cases'].append({'mode': 'isolated_full_pages_control',
                            'repository_is_shallow': False,
                            'selected_for_pruning': result.stdout.splitlines(),
                            'main_history_absent': True})

report['result'] = 'PASS: 7 cases; naive source depth=1 changes retention despite complete Pages history'
(HERE / 'shallow-retention-fixture.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
