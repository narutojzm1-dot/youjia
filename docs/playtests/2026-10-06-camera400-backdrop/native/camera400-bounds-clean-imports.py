from pathlib import Path
import datetime, hashlib, json, shutil, subprocess

repo = Path('/tmp/youjia-camera400-bounds')
evidence = Path('/tmp/camera400-bounds-evidence')
assert (evidence / 'full-v2/outer.exit').read_text().strip() == '0'
live = []
for line in subprocess.check_output(['ps', '-eo', 'pid,stat,comm,args'], text=True).splitlines()[1:]:
    fields = line.split(None, 3)
    if len(fields) == 4 and not fields[1].startswith('Z') and ('Godot' in fields[2] or fields[2] in {'chromium', 'chrome', 'firefox'}):
        live.append(line)
assert not live, live
archive = evidence / 'generated-metadata'
archive.mkdir(exist_ok=False)
allowed_imports = {
    'assets/holiday/characters/cast_v2/goose_riding_up.png.import',
    'assets/holiday/environment/cloud_band_morning.png.import',
    'assets/holiday/environment/cloud_band_overcast.png.import',
    'assets/holiday/environment/cloud_band_sunny.png.import',
    'assets/holiday/environment/cloud_band_sunset.png.import',
}
status = subprocess.check_output(['git', '-C', str(repo), 'status', '--porcelain'], text=True).splitlines()
assert all((line.startswith(' M ') and line[3:] in allowed_imports) or (line.startswith('?? ') and line.endswith('.gd.uid')) for line in status), status
(archive / 'before.json').write_text(json.dumps(status, indent=2) + '\n')
(archive / 'import.diff').write_bytes(subprocess.check_output(['git', '-C', str(repo), 'diff', '--', *sorted(allowed_imports)]))
uids = []
for line in status:
    if not line.startswith('?? '):
        continue
    relative = line[3:]
    path = repo / relative
    raw = path.read_bytes()
    target = archive / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(raw)
    uids.append({'path': relative, 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
    path.unlink()
subprocess.run(['git', '-C', str(repo), 'restore', '--source=HEAD', '--worktree', '--', *sorted(allowed_imports)], check=True)
after = subprocess.check_output(['git', '-C', str(repo), 'status', '--porcelain'], text=True)
assert not after, after
cache = Path('/dev/shm/camera400-bounds-import')
assert (repo / '.godot').is_symlink() and (repo / '.godot').resolve() == cache
cache_files = [p for p in cache.rglob('*') if p.is_file()]
cache_bytes = sum(p.stat().st_size for p in cache_files)
shutil.rmtree(cache)
cache.mkdir()
report = {
    'closed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'live_engine_browser': live, 'restored_only': sorted(allowed_imports), 'archived_untracked_uids': uids,
    'git_status_after': after, 'ignored_cache_removed': str(cache), 'ignored_cache_bytes_removed': cache_bytes,
    'export_logs_source_preserved': True,
}
(archive / 'cleanup.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
