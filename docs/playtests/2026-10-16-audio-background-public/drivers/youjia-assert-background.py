import json, pathlib, sys

path = pathlib.Path(sys.argv[1])
r = json.loads(path.read_text(encoding='utf-8-sig'))
assert r['driverExit'] == 0
proof = []
for c in r['cases']:
    assert c['complete'] and not c['errors']
    if 'manifest' in c:
        assert c['manifest']['sourceCommit'] == r['candidate']
    records = {x['label']: x for x in c['records']}
    active = records['active night']
    assert not active['hidden'] and active['diag']['state'] == 'running'
    assert active['diag']['starts'] == 2
    a, b = records['other tab foreground'], records['hidden sustained']
    for x in [a, b, records['own window minimized']]:
        assert x['hidden'] and x['visibility'] == 'hidden'
        assert x['diag']['state'] == 'suspended'
        assert x['diag']['starts'] == active['diag']['starts']
        assert any(e['name'] == 'visibilitychange' and e['hidden'] and e['trusted'] for e in x['events'])
    assert a['contextTimes'][-1]['state'] == b['contextTimes'][-1]['state'] == 'suspended'
    assert a['contextTimes'][-1]['t'] == b['contextTimes'][-1]['t'], 'background audio clock must stop'
    for label in ['foreground without new gesture', 'foreground trusted gesture', 'own window restored', 'trusted resume from suspension']:
        x = records[label]
        assert not x['hidden'] and x['diag']['state'] == 'running'
        assert x['diag']['starts'] == active['diag']['starts'], 'do not restart long sources'
        assert max(s['peak'] for s in x['samples']) > 0.00001, 'visible backend has actual software output'
    assert records['foreground trusted gesture']['contextTimes'][-1]['t'] > b['contextTimes'][-1]['t'] + 1
    assert records['controlled suspension']['diag']['state'] == 'suspended'
    proof.append({'label': c['label'], 'hidden_clock': a['contextTimes'][-1]['t'], 'same_clock_after_ms': b['t'] - a['t'], 'long_starts_before_after': [active['diag']['starts'], records['trusted resume from suspension']['diag']['starts']], 'page_errors': c['errors'], 'console': c['console']})
out = {'source': r['candidate'], 'raw': path.name, 'checks_passed': True, 'software_only': True, 'cases': proof}
path.with_name('semantic-verification.json').write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(out, ensure_ascii=False))
