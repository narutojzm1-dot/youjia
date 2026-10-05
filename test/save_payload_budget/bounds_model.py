#!/usr/bin/env python3
"""#294: escape/double-wrap amplification, dense album and archive size model.

Small samples go through the real pinned Host (pure functions, one real import
into a test-namespace IndexedDB store). Candidate-sized samples are measured
only with host_replica.mjs, after the replica matches the real Host exactly.
"""
import argparse
import functools
import http.server
import json
import math
import os
import pathlib
import shutil
import sys
import tempfile
import threading

from playwright.sync_api import sync_playwright

S_CANDIDATE = 1572864   # #294 experimental per-source raw candidate (1.5 MiB)
C_CANDIDATE = 3670016   # #294 experimental combined candidate (3.5 MiB)
P_CANDIDATE = 1048576   # #294 experimental later-save payload candidate (1 MiB)
ARCHIVE_COUNTS = [0, 1, 8, 32]
TINY_PAYLOAD = '{"version":5}'
PAIRS = ['ascii_ascii', 'quote_quote', 'backslash_backslash', 'newline_newline', 'tab_tab', 'cjk_cjk',
         'u2028_u2028', 'control_control', 'quote_ascii', 'ascii_control']
EXPECTED = ['natural_full', 'dense_full'] + [f'{size}_{p}' for p in PAIRS for size in ('big', 'small')]

LOAD = """async () => {
  window.R = await import('./host_replica.mjs');
  window.HOST = {decode: await import('./source_decode.mjs'), legacy: await import('./legacy_v5.mjs')};
  window.files = {};
}"""

# Bytes from disk -> fatal UTF-8 text, exactly as source_decode does.
FETCH = """async (names) => {
  for (const n of names) {
    const bytes = new Uint8Array(await (await fetch('samples/' + n)).arrayBuffer());
    window.files[n] = {bytes, text: R.decode(bytes)};
  }
}"""

OFFLINE = """(s) => {
  const p = files[s.primary], b = files[s.backup];
  const out = {classify: {primary: R.classify(p.text), backup: R.classify(b.text)},
    base64_chars: {primary: R.base64(p.bytes).length, backup: R.base64(b.bytes).length},
    snapshot_arg_chars: R.snapshotArg(p.bytes, b.bytes).length};
  const w = R.legacyPayload(p.text, b.text);
  if (w.error) out.wrapper = {error: w.error};
  else out.wrapper = {selected: w.selected, bytes: R.utf8(w.payload), chars: w.payload.length};
  return out;
}"""

REAL_PURE = """(snap) => {
  try {
    const payload = HOST.legacy.prepareLegacyV5(HOST.decode.decodeSourceSnapshot(snap));
    return {selected: JSON.parse(payload).selected, bytes: R.utf8(payload)};
  } catch (e) { return {error: String(e)}; }
}"""

CALL = """() => { window.__call = (m, ...a) => new Promise(r => window.YoujiaRecoveryHostBridge[m](...a, s => r(JSON.parse(s)))); }"""

# Rebuild real records with the replica from the same payload texts and
# generations, then compare every size metric.
MODEL_CHECK = """async (real) => {
  const root = await R.envelope(real.current.payload_bytes);
  const cand = await R.envelope(real.intent.candidate.payload_bytes, root);
  const archived = await R.envelope(real.archive[0].candidate.payload_bytes, root);
  const model = {current: root, intent: R.intent('prepared', root, cand),
    archive0: {...R.intent('prepared', root, archived), state: 'rejected'}};
  const actual = {current: real.current, intent: real.intent, archive0: real.archive[0]};
  const out = {};
  for (const k of Object.keys(model)) out[k] = {real: R.metrics(actual[k]), model: R.metrics(model[k]),
    real_keys: Object.keys(actual[k]).sort().join(','), model_keys: Object.keys(model[k]).sort().join(',')};
  out.archive_has_parent_and_candidate = !!(real.archive[0].parent && real.archive[0].candidate &&
    real.archive[0].parent.commit_id === real.current.commit_id);
  return out;
}"""

SCENARIO = """async ({root, candidate, counts}) => {
  const rootText = typeof root === 'string' ? root : R.legacyPayload(files[root.primary].text, files[root.backup].text).payload;
  const candText = files[candidate].text;
  const env = await R.envelope(rootText), cand = await R.envelope(candText, env);
  const current = R.metrics(env), intent = R.metrics(R.intent('prepared', env, cand));
  const entry = R.metrics({...R.intent('prepared', env, cand), state: 'rejected'});
  const sum = n => Object.fromEntries(['json', 'strings', 'v8'].map(k => [k, current[k] + intent[k] + n * entry[k]]));
  return {root_payload_bytes: R.utf8(rootText), candidate_payload_bytes: R.utf8(candText),
    record: {current, intent, archive_entry: entry},
    totals: Object.fromEntries(counts.map(n => [n, sum(n)]))};
}"""


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def browser_path():
    for candidate in (os.environ.get('CHROME'), '/usr/bin/chromium', shutil.which('google-chrome')):
        if candidate and pathlib.Path(candidate).exists():
            return candidate
    raise SystemExit('no Chromium/Chrome found; set CHROME')


class Run:
    def __init__(self, samples, host, host_sha, repo_head):
        self.dir = pathlib.Path(samples)
        self.host = pathlib.Path(host)
        self.meta = json.loads((self.dir / 'bounds.json').read_text())
        self.by_name = {s['name']: s for s in self.meta['samples']}
        self.checks = []
        self.out = {'host_sha': host_sha, 'repo_head': repo_head, 'godot': self.meta['godot'],
                    'candidates': {'S_per_source': S_CANDIDATE, 'C_combined': C_CANDIDATE, 'P_later_payload': P_CANDIDATE},
                    'samples': {}, 'replica_validation': {}, 'archive_model_check': {}, 'archive_scenarios': {},
                    'checks': self.checks}

    def check(self, cid, ok, detail=''):
        self.checks.append({'id': cid, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
        print(f"[{'PASS' if ok else 'FAIL'}] {cid} {detail}", flush=True)

    def files_of(self, s):
        return {'primary': s['primary']['file'], 'backup': s['backup']['file']}

    def offline(self, page, name):
        s = self.by_name[name]
        r = page.evaluate(OFFLINE, self.files_of(s))
        raw_sum = s['primary']['bytes'] + s['backup']['bytes']
        r.update({'files': {k: {f: s[k][f] for f in ('bytes', 'chars', 'sha256', 'godot_json_parse_ok')} for k in ('primary', 'backup')},
                  'raw_sum_bytes': raw_sum, 'source': s['source'], 'synthetic': s['synthetic'], 'method': 'model (replica, offline)'})
        if 'bytes' in r['wrapper']:
            r['wrapper']['ratio_to_raw_sum'] = round(r['wrapper']['bytes'] / raw_sum, 4)
        r['within'] = {'S_each': max(s['primary']['bytes'], s['backup']['bytes']) <= S_CANDIDATE,
                       'C_combined': r['wrapper'].get('bytes', math.inf) <= C_CANDIDATE}
        return r

    def validate_small(self, page, pair):
        name = f'small_{pair}'
        s = self.by_name[name]
        snap_text = (self.dir / s['snapshot']).read_text()
        real = page.evaluate(REAL_PURE, json.loads(snap_text))
        model = self.offline(page, name)
        self.out['replica_validation'][pair] = {'real_host': real, 'replica': model['wrapper'],
                                                'godot_snapshot_chars': len(snap_text), 'replica_snapshot_chars': model['snapshot_arg_chars'],
                                                'classify': model['classify']}
        if 'error' in real:
            ok = 'error' in model['wrapper'] and model['wrapper']['error'] in real['error']
        else:
            ok = real == {'selected': model['wrapper'].get('selected'), 'bytes': model['wrapper'].get('bytes')}
        self.check(f'replica_matches_host:{pair}', ok, f"host {real} replica {model['wrapper']}")
        self.check(f'snapshot_arg_matches_godot:{pair}', len(snap_text) == model['snapshot_arg_chars'],
                   f"{len(snap_text)} vs {model['snapshot_arg_chars']}")

    def archive_real(self, ctx, base):
        """Real current + prepared intent + 1 archive entry in a test store, then model check."""
        snap = (self.dir / self.by_name['small_quote_quote']['snapshot']).read_text()
        name = 'youjia-recovery-test-bounds-archive'
        a = ctx.new_page(); a.goto(base + 'budget.html'); a.evaluate(CALL)
        seed = a.evaluate("""async ({name, snap, tiny}) => {
          await import('./bridge.mjs');
          await __call('open', name);
          const init = await __call('initializeLegacy', snap);
          window.YoujiaRecoveryProbe.arm('intent_prepared_complete');
          const prep = await __call('prepare', tiny, init.current_token);
          __call('submit', prep.request_id, '1');
          for (let i = 0; i < 100 && !window.YoujiaRecoveryProbe.paused; i++) await new Promise(r => setTimeout(r, 20));
          return {init: init.verdict, payload_bytes: init.current_payload ? new TextEncoder().encode(init.current_payload).length : null,
            paused: window.YoujiaRecoveryProbe.paused?.name || null};
        }""", {'name': name, 'snap': snap, 'tiny': TINY_PAYLOAD})
        a.close()
        c = ctx.new_page(); c.goto(base + 'budget.html'); c.evaluate(CALL)
        reopened = c.evaluate("""async ({name, tiny}) => {
          await import('./bridge.mjs');
          const P = window.YoujiaRecoveryProbe;
          const opened = await __call('open', name);
          P.arm('intent_prepared_complete');
          const prep = await __call('prepare', tiny + ' ', opened.current_token);
          __call('submit', prep.request_id, '2');
          for (let i = 0; i < 100 && !P.paused; i++) await new Promise(r => setTimeout(r, 20));
          return {opened: opened.verdict, paused: P.paused?.name || null};
        }""", {'name': name, 'tiny': TINY_PAYLOAD})
        d = ctx.new_page(); d.goto(base + 'budget.html'); d.evaluate(LOAD)
        real = d.evaluate("""async (name) => {
          const {openStore} = await import('./store.mjs');
          const s = await openStore(name); const v = await s.snapshot(); s.close(); return v;
        }""", name)
        check = d.evaluate(MODEL_CHECK, real)
        d.close(); c.close()
        e = ctx.new_page(); e.goto(base + 'budget.html'); e.evaluate(CALL)
        e.evaluate("""async (name) => { await import('./bridge.mjs'); await __call('open', name); await window.YoujiaRecoveryProbe.cleanup(); }""", name)
        e.close()
        replica_bytes = self.out['replica_validation']['quote_quote']['replica'].get('bytes')
        self.out['archive_model_check'] = {'seed': seed, 'reopened': reopened, 'present': real['present'],
                                           'archive_len': len(real.get('archive') or []), 'records': check}
        self.check('real_import_matches_replica', seed['init'] == 'clean' and seed['payload_bytes'] == replica_bytes,
                   f"real current payload {seed['payload_bytes']} B, replica {replica_bytes} B")
        self.check('real_store_has_current_intent_archive', real['present'] == {'current': True, 'intent': True, 'archive': True}
                   and reopened['opened'] == 'restored_parent_intent_rejected' and len(real['archive']) == 1
                   and real['intent']['state'] == 'prepared', json.dumps(real['present']))
        self.check('archive_entry_carries_parent_and_candidate', check['archive_has_parent_and_candidate'])
        for k in ('current', 'intent', 'archive0'):
            r = check[k]
            self.check(f'archive_model_matches_real:{k}', r['real'] == r['model'] and r['real_keys'] == r['model_keys'],
                       f"real {r['real']} model {r['model']}")

    def run(self, out_path):
        site = pathlib.Path(tempfile.mkdtemp(prefix='youjia-bounds-site-'))
        profile = pathlib.Path(tempfile.mkdtemp(prefix='youjia-bounds-profile-'))
        for f in ('store.mjs', 'legacy_v5.mjs', 'source_decode.mjs', 'bridge.mjs'):
            shutil.copy(self.host / f, site / f)
        shutil.copy(pathlib.Path(__file__).with_name('host_replica.mjs'), site / 'host_replica.mjs')
        (site / 'samples').symlink_to(self.dir.resolve())
        (site / 'budget.html').write_text('<!doctype html><meta charset="utf-8"><title>bounds</title>\n'
                                          + (self.host / 'head.html').read_text(), encoding='utf-8')
        server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(site)))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        base = f'http://127.0.0.1:{server.server_address[1]}/'
        got = [s['name'] for s in self.meta['samples']]
        self.check('generator_errors_empty', not self.meta['errors'], '; '.join(self.meta['errors']))
        self.check('sample_set_complete', got == EXPECTED, f'{len(got)}/{len(EXPECTED)}')
        try:
            with sync_playwright() as pw:
                ctx = pw.chromium.launch_persistent_context(str(profile), executable_path=browser_path(), headless=True)
                self.out['browser'] = ctx.browser.version if ctx.browser else 'chromium'
                page = ctx.new_page(); page.goto(base + 'budget.html'); page.evaluate(LOAD)
                names = [f for s in self.meta['samples'] for f in self.files_of(s).values()]
                page.evaluate(FETCH, names)
                for pair in PAIRS:
                    self.validate_small(page, pair)
                for name in got:
                    if not name.startswith('small_'):
                        self.out['samples'][name] = self.offline(page, name)
                self.dense_checks()
                self.archive_real(ctx, base)
                scenarios = {
                    'natural_full': ({'primary': 'natural_full.primary.json', 'backup': 'natural_full.backup.json'}, 'natural_full.primary.json'),
                    'dense_full': ({'primary': 'dense_full.primary.json', 'backup': 'dense_full.backup.json'}, 'dense_full.primary.json'),
                    'candidate_ascii_1_5MiB': ({'primary': 'big_ascii_ascii.primary.json', 'backup': 'big_ascii_ascii.backup.json'}, 'big_ascii_ascii.primary.json'),
                    'candidate_cjk_1_5MiB': ({'primary': 'big_cjk_cjk.primary.json', 'backup': 'big_cjk_cjk.backup.json'}, 'big_cjk_cjk.primary.json'),
                }
                for key, (root, cand) in scenarios.items():
                    self.out['archive_scenarios'][key] = page.evaluate(SCENARIO, {'root': root, 'candidate': cand, 'counts': ARCHIVE_COUNTS})
                    self.out['archive_scenarios'][key]['method'] = 'model (replica, offline; never written to IndexedDB)'
                page.close()
                ctx.close()
        finally:
            server.shutdown()
            shutil.rmtree(profile, ignore_errors=True)
            shutil.rmtree(site, ignore_errors=True)
        self.findings()
        failed = [c for c in self.checks if c['status'] == 'FAIL']
        self.out['summary'] = {'checks': len(self.checks), 'failed': len(failed), 'failed_ids': [c['id'] for c in failed]}
        pathlib.Path(out_path).write_text(json.dumps(self.out, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
        print(f"[save-budget-bounds] {len(self.checks) - len(failed)}/{len(self.checks)} checks PASS, {len(failed)} FAIL")
        return 1 if failed else 0

    def dense_checks(self):
        d = self.by_name['dense_full']
        items = d.get('projection_moment_items', [])
        self.check('dense_album_sanitize_legal', len(items) == 15 and all(n == 64 for n in items),
                   f'{len(items)} photos, items {sorted(set(items))}')
        n = self.by_name['natural_full']
        self.check('natural_full_matches_287', n['primary']['bytes'] == 266132 and n['backup']['bytes'] == 266132,
                   f"{n['primary']['bytes']}/{n['backup']['bytes']}")

    def findings(self):
        big = {k: v for k, v in self.out['samples'].items() if k.startswith('big_')}
        self.out['counterexamples_S_ok_C_exceeded'] = sorted(
            k for k, v in big.items() if v['within']['S_each'] and 'bytes' in v['wrapper'] and not v['within']['C_combined'])
        ratios = {k: v['wrapper'].get('ratio_to_raw_sum') for k, v in big.items()}
        self.out['wrapper_ratio_by_pair'] = ratios
        arg = max(v['snapshot_arg_chars'] for v in big.values())
        overhead = len(json.dumps({'backup': {'base64': '', 'status': 'present'},
                                   'primary': {'base64': '', 'status': 'present'}}, separators=(',', ':')))
        derived = 2 * 4 * math.ceil(S_CANDIDATE / 3) + overhead
        self.out['derived'] = {'H_head_arg_chars_for_S': derived, 'snapshot_json_overhead_chars': overhead,
                               'max_observed_snapshot_arg_chars_at_S': arg}
        self.check('head_arg_formula_matches_observed', derived == arg, f'{derived} vs {arg}')


def main():
    ap = argparse.ArgumentParser()
    for a in ('--samples', '--host', '--host-sha', '--repo-head', '--out'):
        ap.add_argument(a, required=True)
    a = ap.parse_args()
    sys.exit(Run(a.samples, a.host, a.host_sha, a.repo_head).run(a.out))


if __name__ == '__main__':
    main()
