"""Download complete public/fixed Pages files and compare their actual bytes."""
import concurrent.futures, datetime, hashlib, json, pathlib, re, subprocess, sys, urllib.request

source, pages = sys.argv[1:3]
out = pathlib.Path('C:/Users/Zengm/AppData/Local/Temp/youjia-round-20261017-0130/public-check')
out.mkdir(exist_ok=True)
bases = {'public': 'https://narutojzm1-dot.github.io/youjia/',
         'fixed': f'https://raw.githubusercontent.com/narutojzm1-dot/youjia/{pages}/'}
records = []
expected_hashes = {}

def fetch(phase, name):
    url = bases[phase] + name
    target = out / phase / name
    target.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={'User-Agent': 'youjia-lead-release-audit', 'Cache-Control': 'no-cache'})
    reusable = target.exists() and name in expected_hashes and hashlib.sha256(target.read_bytes()).hexdigest() == expected_hashes[name]
    if reusable:
        headers = {'reused-verified-complete-download': 'true'}
    else:
        try:
            with urllib.request.urlopen(req, timeout=45) as r, target.open('wb') as f:
                headers = dict(r.headers)
                while True:
                    chunk = r.read(1024 * 1024)
                    if not chunk: break
                    f.write(chunk)
        except Exception as error:
            print('download retry via curl:', phase, name, type(error).__name__, flush=True)
            p = subprocess.run(['curl.exe','-fLsS','--connect-timeout','15','--max-time','120','--retry','1','--retry-delay','2','-H','Cache-Control: no-cache',url,'-o',str(target)],capture_output=True,timeout=260)
            if p.returncode: raise RuntimeError(p.stderr.decode(errors='replace')) from error
            headers = {'download-client':'curl fallback with default TLS verification'}
    data = target.read_bytes()
    rec = {'phase': phase, 'file': name, 'url': url, 'bytes': len(data),
           'sha256': hashlib.sha256(data).hexdigest(),
           'git_blob': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest(),
           'headers': {k:v for k,v in headers.items() if k.lower() in ['etag','content-length','content-type','last-modified','content-encoding','reused-verified-complete-download']}}
    records.append(rec)
    print(json.dumps({k:rec[k] for k in ['phase','file','bytes','sha256']}), flush=True)
    return data

with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    futures = {(phase, name):pool.submit(fetch, phase, name) for phase in bases for name in ['game-release.json','index.html']}
    first = {key:f.result() for key,f in futures.items()}
assert first['public','game-release.json'] == first['fixed','game-release.json'], 'manifest mismatch'
assert first['public','index.html'] == first['fixed','index.html'], 'HTML mismatch'
manifest = json.loads(first['public','game-release.json'])
assert manifest['sourceCommit'] == source and manifest['entry'] == 'game-' + source[:7], 'unexpected actual public build'
html = first['public','index.html'].decode('utf-8')
assert f'data-build="{manifest["entry"]}"' in html
cfg = json.loads(re.search(r'const config = ({.*?});',html).group(1))
pack = manifest['entry'] + '.pck'
assert cfg['mainPack'] == pack
assets = {pack:cfg['fileHashes'][pack]}
for group in ['storageModules','loaderModules','engineAssets']:
    block = manifest[group]
    for name, digest in block['sha256'].items():
        filename = name if group == 'engineAssets' else block['entry'] + '/' + name
        assets[filename] = digest
expected_hashes = dict(assets)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    futures = {(phase,name):pool.submit(fetch,phase,name) for name in assets for phase in bases}
    for (phase,name), future in futures.items():
        data = future.result()
        assert hashlib.sha256(data).hexdigest() == assets[name], phase + '/' + name + ' declared hash mismatch'
        if name == pack: assert len(data) == cfg['fileSizes'][pack], 'PCK length mismatch'
for name in assets:
    a = next(r for r in records if r['phase']=='public' and r['file']==name)
    b = next(r for r in records if r['phase']=='fixed' and r['file']==name)
    assert (a['bytes'],a['sha256'],a['git_blob']) == (b['bytes'],b['sha256'],b['git_blob']), name + ' endpoint mismatch'
result = {'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'source': source,
          'pages_commit': pages, 'manifest': manifest, 'html_config': cfg, 'files': records,
          'complete_pck_download_both_endpoints': True, 'checks': 'manifest identity, HTML identity/config, all declared modules/engine bytes, actual full PCK hash and length'}
(out/'verification.json').write_bytes(json.dumps(result,ensure_ascii=False,indent=2).encode('utf-8'))
print('UI704_PUBLIC_BYTES_PASS', len(records), flush=True)
