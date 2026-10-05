"""Exercise the real publisher against disposable local-only Git repositories.
No exported game blobs or real Git remote are used. Run from repository root.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def run(*args, cwd, env=None):
    return subprocess.run(args, cwd=cwd, env=env, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, check=True).stdout.strip()

with tempfile.TemporaryDirectory(prefix='youjia-publish-fixture-') as temporary:
    root = Path(temporary)
    remote, source = root / 'remote.git', root / 'source'
    run('git', 'init', '--bare', str(remote), cwd=root)
    run('git', 'init', '-b', 'main', str(source), cwd=root)
    run('git', 'config', 'user.name', 'Local Fixture', cwd=source)
    run('git', 'config', 'user.email', 'fixture@example.invalid', cwd=source)
    run('git', 'remote', 'add', 'origin', str(remote), cwd=source)
    (source / 'tools').mkdir()
    # Copy tiny tooling only, including optional pruning helper dependencies.
    for tool in (ROOT / 'tools').iterdir():
        if tool.is_file() and tool.suffix in ('.sh', '.py'):
            shutil.copy(tool, source / 'tools' / tool.name)
    shutil.copytree(ROOT / 'web/save', source / 'web/save')
    (source / 'dist').mkdir()
    html = '''<html><head><meta charset="utf-8"></head><body><script>
const config = {"executable":"index","fileSizes":{"index.pck":3,"index.wasm":4}};
script.src = 'index.js';
import('./web/save/bridge.mjs'); import('./web/save/idbfs_source.mjs');
</script></body></html>'''
    (source / 'dist/index.html').write_text(html)
    for extension in ('js', 'wasm', 'pck'):
        (source / f'dist/index.{extension}').write_bytes(extension.encode())
    run('git', 'add', '.', cwd=source)
    run('git', 'commit', '-m', 'fixture source', cwd=source)
    run('git', 'push', 'origin', 'HEAD:gh-pages', cwd=source)
    env = dict(os.environ, KEEP_BUNDLES='4', TMPDIR=str(root))
    old_modules = None
    for iteration in range(2):
        if iteration:
            with (source / 'web/save/bridge.mjs').open('a') as stream:
                stream.write('\n// next source build fixture\n')
            run('git', 'add', '.', cwd=source)
            run('git', 'commit', '-m', 'second source', cwd=source)
        sha = run('git', 'rev-parse', 'HEAD', cwd=source)
        short = sha[:12]
        # Explicitly assert local-only origin before executing the actual script.
        assert Path(run('git', 'remote', 'get-url', 'origin', cwd=source)).resolve() == remote.resolve()
        run('bash', 'tools/publish_gh_pages.sh', short, cwd=source, env=env)
        checkout = root / f'published-{iteration}'
        run('git', 'clone', '--branch', 'gh-pages', str(remote), str(checkout), cwd=root)
        manifest = json.loads((checkout / 'game-release.json').read_text())
        assert manifest['sourceCommit'] == sha
        assert manifest['entry'] == f'game-{short}'
        storage = manifest['storageModules']
        assert storage['entry'] == f'save-{short}'
        published = checkout / storage['entry']
        expected = {p.name: p.read_bytes() for p in (source / 'web/save').glob('*.mjs')}
        assert set(storage['sha256']) == set(expected)
        assert {p.name for p in published.glob('*.mjs')} == set(expected)
        for name, content in expected.items():
            assert (published / name).read_bytes() == content
            assert storage['sha256'][name] == hashlib.sha256(content).hexdigest()
            for relative in re.findall(r"(?:from\s*|import\s*\()\s*['\"](\.[^'\"]+)['\"]", content.decode()):
                target = (published / relative).resolve()
                assert target.is_relative_to(published.resolve()), (name, relative)
                assert target.is_file(), (name, relative)
        page = (checkout / 'index.html').read_text()
        assert './web/save/' not in page
        for entry in ('bridge.mjs', 'idbfs_source.mjs'):
            assert f"./save-{short}/{entry}" in page
            assert (published / entry).is_file()
        assert f"script.src = 'game-{short}.js'" in page
        assert (checkout / f'game-{short}.pck').read_bytes() == b'pck'
        if old_modules:
            directory, files = old_modules
            for name, content in files.items():
                assert (checkout / directory / name).read_bytes() == content
        old_modules = storage['entry'], expected
    print('PASS: real publisher, local bare remote, two builds, HTML entries, exact module bytes/SHA256, relative imports and retained old module directory')
