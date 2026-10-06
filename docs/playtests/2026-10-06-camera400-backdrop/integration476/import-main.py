from pathlib import Path
import datetime, hashlib, json, os, subprocess

repo = '/tmp/youjia-camera400-bounds'
main = os.environ['CAMERA400_INTEGRATION_MAIN']
records = {}
def git(*args, data=None):
    return subprocess.check_output(['git', '-C', repo, *args], input=data)
def exists(sha):
    return subprocess.run(['git', '-C', repo, 'cat-file', '-e', sha], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
def api(path):
    return json.loads(subprocess.check_output(['gh', 'api', 'repos/narutojzm1-dot/youjia/' + path]))
def commit(sha):
    if exists(sha):
        return
    doc = api('git/commits/' + sha)
    verification = doc.get('verification') or {}
    payload, signature = verification.get('payload'), verification.get('signature')
    if payload:
        if signature:
            header, body = payload.split('\n\n', 1)
            payload = header + '\ngpgsig ' + signature.replace('\n', '\n ') + '\n\n' + body
        candidates = [payload.encode()]
    else:
        def ident(role):
            value = doc[role]
            stamp = int(datetime.datetime.fromisoformat(value['date'].replace('Z', '+00:00')).timestamp())
            return f"{role} {value['name']} <{value['email']}> {stamp} +0000"
        payload = '\n'.join(['tree ' + doc['tree']['sha'], *['parent ' + p['sha'] for p in doc['parents']], ident('author'), ident('committer')]) + '\n\n' + doc['message']
        candidates = [payload.encode(), (payload + '\n').encode()]
    matching = [raw for raw in candidates if hashlib.sha1(b'commit ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == sha]
    assert len(matching) == 1, sha
    assert git('hash-object', '-w', '-t', 'commit', '--stdin', data=matching[0]).decode().strip() == sha
    records[sha] = {'tree': doc['tree']['sha'], 'parents': [p['sha'] for p in doc['parents']], 'exact_hash': True}
    for parent in doc['parents']:
        commit(parent['sha'])

assert api('git/ref/heads/main')['object']['sha'] == main
commit(main)
tree_sha = git('cat-file', 'commit', main).decode().splitlines()[0].split()[1]
walk = subprocess.run(['git', '-C', repo, 'ls-tree', '-r', main], capture_output=True)
if walk.returncode:
    response = api('git/trees/' + tree_sha + '?recursive=1')
    assert not response['truncated'] and response['sha'] == tree_sha
    groups, hashes = {'': []}, {'': tree_sha}
    for entry in response['tree']:
        parent, _, name = entry['path'].rpartition('/')
        groups.setdefault(parent, []).append({**entry, 'name': name})
        if entry['type'] == 'tree':
            groups.setdefault(entry['path'], [])
            hashes[entry['path']] = entry['sha']
    for parent in sorted(groups, key=lambda value: value.count('/') + bool(value), reverse=True):
        raw = b''.join((entry['mode'] + ' ' + entry['type'] + ' ' + entry['sha'] + '\t' + entry['name']).encode() + b'\0' for entry in groups[parent])
        assert git('mktree', '--missing', '-z', data=raw).decode().strip() == hashes[parent]
assert git('rev-parse', main + '^{tree}').decode().strip() == tree_sha
proof = {'main': main, 'tree': tree_sha, 'commits_materialized_exact': records, 'all_tree_entries_retained_without_blob_downloads': True}
Path('/tmp/camera400-bounds-476-main-objects.json').write_text(json.dumps(proof, indent=2) + '\n')
print(json.dumps({'main': main, 'tree': tree_sha, 'new_commits': len(records)}))
