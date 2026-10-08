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
                          stderr=subprocess.STDOUT, encoding='utf-8', check=True).stdout.strip()

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
    shutil.copytree(ROOT / 'web/boot', source / 'web/boot')
    (source / 'dist').mkdir()
    html = '''<html><head><meta charset="utf-8"></head><body><script>
const config = {"executable":"index","fileSizes":{"index.pck":3,"index.wasm":4}};
script.src = 'index.js';
import('./web/save/bridge.mjs'); import('./web/save/idbfs_source.mjs');
import('./web/boot/download_assets.mjs');
</script></body></html>'''
    (source / 'dist/index.html').write_text(html)
    for extension in ('js', 'wasm', 'pck', 'audio.worklet.js', 'audio.position.worklet.js'):
        (source / f'dist/index.{extension}').write_bytes(extension.encode())
    run('git', 'add', '.', cwd=source)
    run('git', 'commit', '-m', 'fixture source', cwd=source)
    run('git', 'push', 'origin', 'HEAD:gh-pages', cwd=source)
    env = dict(os.environ, KEEP_BUNDLES='4', TMPDIR=str(root))
    old_modules = None
    old_engine = None
    for iteration in range(3):
        if iteration:
            with (source / 'web/save/bridge.mjs').open('a') as stream:
                stream.write('\n// next source build fixture\n')
            (source / 'dist/index.pck').write_bytes(b'pck' + bytes([iteration]))
            if iteration == 2:
                (source / 'dist/index.audio.worklet.js').write_bytes(b'updated engine worklet')
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
        engine = manifest['engineAssets']['entry']
        cfg = json.loads(re.search(r'const config = (\{.*?\});', page)[1])
        assert cfg['executable'] == engine and cfg['mainPack'] == f'game-{short}.pck'
        assert set(cfg['fileSizes']) == {f'{engine}.wasm', f'game-{short}.pck'}
        assert cfg['fileHashes'] == {name: hashlib.sha256((checkout / name).read_bytes()).hexdigest() for name in cfg['fileSizes']}
        assert f"script.src = '{engine}.js'" in page
        for name, digest in manifest['engineAssets']['sha256'].items():
            assert hashlib.sha256((checkout / name).read_bytes()).hexdigest() == digest
        if old_engine:
            assert (engine == old_engine) == (iteration == 1), 'code/PCK changes reuse engine; worklet changes invalidate it'
            assert (checkout / f'{old_engine}.wasm').is_file(), 'retain old engine URLs'
        old_engine = engine
        loader = manifest['loaderModules']
        assert loader['entry'] == f'boot-{short}'
        assert f"./boot-{short}/download_assets.mjs" in page
        for name, digest in loader['sha256'].items():
            assert hashlib.sha256((checkout / loader['entry'] / name).read_bytes()).hexdigest() == digest
        assert (checkout / f'game-{short}.pck').read_bytes() == (source / 'dist/index.pck').read_bytes()
        assert (checkout / f'game-{short}.wasm').read_bytes() == b'wasm', 'legacy URL still works'
        if old_modules:
            directory, files = old_modules
            for name, content in files.items():
                assert (checkout / directory / name).read_bytes() == content
        old_modules = storage['entry'], expected
    print('PASS: real publisher, local bare remote, three builds, stable/changed engine URLs, HTML/PCK/worklets, exact loader/storage module bytes/SHA256 and retained old URLs')
