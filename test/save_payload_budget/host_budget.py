#!/usr/bin/env python3
"""#287 browser half: feed generated save samples through the pinned R1 Host.

Uses a disposable Chromium profile and test-namespace IndexedDB stores only.
Host modules are served verbatim from the directory extracted by run.sh.
"""
import argparse
import base64
import functools
import hashlib
import http.server
import json
import os
import pathlib
import shutil
import sys
import tempfile
import threading

from playwright.sync_api import sync_playwright

LIMIT = 65536
HEAD_LIMIT = 180000
TINY_PAYLOAD = '{"version":5}'

PURE = """async (snap) => {
  const {decodeSourceSnapshot} = await import('./source_decode.mjs');
  const {prepareLegacyV5} = await import('./legacy_v5.mjs');
  const enc = new TextEncoder();
  const sha = async s => [...new Uint8Array(await crypto.subtle.digest('SHA-256', enc.encode(s)))]
    .map(v => v.toString(16).padStart(2, '0')).join('');
  let stage = 'decodeSourceSnapshot', decoded;
  try {
    decoded = decodeSourceSnapshot(snap);
    stage = 'prepareLegacyV5';
    const payload = prepareLegacyV5(decoded);
    const parsed = JSON.parse(payload);
    const kept = {};
    for (const role of ['primary', 'backup']) {
      const s = parsed.sources[role];
      kept[role] = s.status === 'absent' ? 'absent' : await sha(s.text);
    }
    return {ok: true, selected: parsed.selected, payload_bytes: enc.encode(payload).length,
      payload_chars: payload.length, payload_sha256: await sha(payload), raw_text_sha256: kept};
  } catch (e) { return {ok: false, stage, error: String(e)}; }
}"""

# Same combined-object formula as legacy_v5.mjs with its fixture caps removed.
# Analysis only: shows how large a preserved dual-raw import would really be.
UNCAPPED = """(texts) => {
  const src = t => t === null ? {status: 'absent'} : {status: 'present', text: t};
  const payload = JSON.stringify({schema: 'youjia.legacy-v5-import/v1', selected: 'primary',
    sources: {primary: src(texts.primary), backup: src(texts.backup)}});
  return {bytes: new TextEncoder().encode(payload).length, chars: payload.length};
}"""

REAL = """async ({name, raw}) => {
  await import('./bridge.mjs');
  const H = window.YoujiaRecoveryHostBridge, P = window.YoujiaRecoveryProbe;
  const call = (m, ...a) => new Promise(r => H[m](...a, s => r(JSON.parse(s))));
  const est = async () => { try { const e = await navigator.storage.estimate(); return {usage: e.usage, quota: e.quota}; } catch (e) { return {error: String(e)}; } };
  const opened = await call('open', name);
  const before = await P.snapshot(), est0 = await est();
  const res = await call('initializeLegacy', raw);
  const after = await P.snapshot(), est1 = await est();
  const summary = s => ({present: s.present, payload_bytes: s.current ? new TextEncoder().encode(s.current.payload_bytes).length : null,
    payload_sha256: s.current ? s.current.payload_sha256 : null});
  let kept = null;
  if (res.current_payload) {
    const p = JSON.parse(res.current_payload), enc = new TextEncoder();
    kept = {};
    for (const role of ['primary', 'backup']) {
      const s = p.sources[role];
      kept[role] = s.status === 'absent' ? 'absent' : [...new Uint8Array(await crypto.subtle.digest('SHA-256', enc.encode(s.text)))].map(v => v.toString(16).padStart(2, '0')).join('');
    }
  }
  return {opened: opened.verdict, result: res.error ? {error: res.error} : {verdict: res.verdict},
    raw_text_sha256: kept, unchanged: JSON.stringify(before) === JSON.stringify(after),
    before: summary(before), after: summary(after), storage_estimate: {before: est0, after: est1}};
}"""


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def browser_path():
    for candidate in (os.environ.get('CHROME'), '/usr/bin/chromium', shutil.which('google-chrome')):
        if candidate and pathlib.Path(candidate).exists():
            return candidate
    raise SystemExit('no Chromium/Chrome found; set CHROME')


def sha256(b):
    return hashlib.sha256(b).hexdigest()


class Run:
    def __init__(self, samples_dir, host_dir, host_sha, repo_head):
        self.dir = pathlib.Path(samples_dir)
        self.host = pathlib.Path(host_dir)
        self.meta = json.loads((self.dir / 'samples.json').read_text())
        self.checks = []
        self.results = {'host_sha': host_sha, 'repo_head': repo_head, 'godot': self.meta['godot'],
                        'rules': self.meta['rules'], 'generator_errors': self.meta['errors'],
                        'samples': [], 'state_preservation': {}, 'checks': self.checks}
        self.counter = 0

    def check(self, cid, ok, detail='', shas=None):
        entry = {'id': cid, 'status': 'PASS' if ok else 'FAIL', 'detail': detail}
        if not ok and shas:
            entry['sample_sha256'] = shas
        self.checks.append(entry)
        print(f"[{entry['status']}] {cid} {detail}", flush=True)

    def store_name(self, tag):
        self.counter += 1
        tag = ''.join(c if c.isascii() and c.isalnum() else '-' for c in tag)
        return f'youjia-recovery-test-budget-{self.counter}-{tag}'[:121].rstrip('-')

    def files(self, sample):
        out = {}
        for role in ('primary', 'backup'):
            info = sample[role]
            out[role] = (self.dir / info['file']).read_bytes() if info['status'] == 'present' else None
        return out

    def bypass_snapshot(self, raw):
        return {role: ({'status': 'absent'} if b is None else
                       {'status': 'present', 'base64': base64.b64encode(b).decode()})
                for role, b in raw.items()}

    def real(self, ctx, base, tag, snapshot_text):
        page = ctx.new_page()
        try:
            page.goto(base + 'budget.html')
            name = self.store_name(tag)
            r = page.evaluate(REAL, {'name': name, 'raw': snapshot_text})
            r['store'] = name
            page.evaluate("async () => { await import('./bridge.mjs'); await window.YoujiaRecoveryProbe.cleanup(); }")
            return r
        finally:
            page.close()

    def sample(self, ctx, base, pure_page, s):
        raw = self.files(s)
        shas = {k: (None if v is None else sha256(v)) for k, v in raw.items()}
        for role, b in raw.items():
            if b is not None:
                self.check(f"{s['name']}:godot_sha_matches", shas[role] == s[role]['sha256'], role)
        snap_text = (self.dir / s['host_godot_capture']['file']).read_text()
        snap = json.loads(snap_text)
        texts = {k: (None if v is None else v.decode('utf-8')) for k, v in raw.items()}
        entry = {k: s[k] for k in ('name', 'kind', 'source', 'album', 'photo_count', 'primary', 'backup', 'host_godot_capture')}
        entry['raw_sum_bytes'] = sum(len(v) for v in raw.values() if v is not None)
        entry['uncapped_combined'] = pure_page.evaluate(UNCAPPED, texts)
        entry['host_pure'] = pure_page.evaluate(PURE, snap)
        entry['head_arg_chars'] = len(snap_text)
        entry['host_real'] = self.real(ctx, base, s['name'], snap_text)
        captured = all(v.get('status') != 'read_error' for v in snap.values())
        if not captured:
            bypass = self.bypass_snapshot(raw)
            bypass_text = json.dumps(bypass, separators=(',', ':'))
            entry['bypass_godot_cap'] = {'head_arg_chars': len(bypass_text),
                                         'host_pure': pure_page.evaluate(PURE, bypass),
                                         'host_real': self.real(ctx, base, s['name'] + '-bypass', bypass_text)}
        self.results['samples'].append(entry)
        self.assert_sample(entry, shas)

    def assert_sample(self, e, shas):
        n, real = e['name'], e['host_real']
        accepted = 'verdict' in real['result']
        # Safety: an accepted import keeps both raw files byte-identical; a
        # rejected one leaves the empty target completely untouched.
        if accepted:
            want = {k: ('absent' if v is None else v) for k, v in shas.items()}
            self.check(f'{n}:accepted_raw_preserved', real['raw_text_sha256'] == want and
                       real['result']['verdict'] == 'clean' and real['after']['payload_bytes'] == e['host_pure'].get('payload_bytes'),
                       f"payload {real['after']['payload_bytes']} bytes")
        else:
            self.check(f'{n}:rejected_before_write', real['unchanged'] and not any(real['after']['present'].values()),
                       real['result']['error'])
        for key in ('bypass_godot_cap',):
            if key in e:
                b = e[key]['host_real']
                self.check(f'{n}:bypass_rejected_before_write', 'error' in b['result'] and b['unchanged'] and
                           not any(b['after']['present'].values()), b['result'].get('error', 'ACCEPTED'))
        if e['kind'] == 'natural':
            self.check(f'{n}:natural_save_importable_by_current_host', accepted,
                       f"primary {e['primary'].get('bytes')} B + backup {e['backup'].get('bytes', 0)} B; "
                       f"uncapped combined {e['uncapped_combined']['bytes']} B; "
                       + (real['result'].get('error') or 'accepted'), shas)
        expected = {
            'stress_single_at_limit': ('reject', 'combined legacy fixture too large'),
            'stress_single_over_limit': ('reject', 'unreadable or oversized source'),
            'stress_dual_each_under_combined_over': ('reject', 'combined legacy fixture too large'),
            'stress_dual_fits': ('accept', ''),
            'stress_nonascii_single_chars_under_bytes_over': ('reject', 'unreadable or oversized source'),
            'stress_nonascii_dual': ('reject', 'combined legacy fixture too large'),
            'stress_future_rules_growth': ('reject', 'combined legacy fixture too large'),
            'stress_photomoment_dense_single': ('reject', 'unreadable or oversized source'),
        }.get(n)
        if expected:
            kind, text = expected
            ok = accepted if kind == 'accept' else (not accepted and text in real['result']['error'])
            self.check(f'{n}:host_limit_behaviour', ok, f"expected {kind} {text}".strip(), shas)
            if n.startswith('stress_') and 'primary' in e and e['primary'].get('status') == 'present':
                p = e['primary']
                self.check(f'{n}:projection_differs_from_raw', p['projection_pretty_bytes'] != p['bytes'],
                           f"raw {p['bytes']} B vs projection {p['projection_pretty_bytes']} B (compact {p['projection_compact_bytes']} B)")

    def preservation(self, ctx, base, by_name):
        """Existing current/archive/intent must survive oversized attempts."""
        small = (self.dir / by_name['natural_01_goose_horse_mount']['host_godot_capture']['file']).read_text()
        legacy_ok = (self.dir / by_name['stress_dual_each_under_combined_over']['host_godot_capture']['file']).read_text()
        big_game = (self.dir / by_name['natural_04_llama_sheep_cow_smirk']['primary']['file']).read_text()
        name = self.store_name('existing')
        out = {'store': name}
        helpers = """() => { window.__call = (m, ...a) => new Promise(r => window.YoujiaRecoveryHostBridge[m](...a, s => r(JSON.parse(s)))); }"""
        a = ctx.new_page(); a.goto(base + 'budget.html'); a.evaluate(helpers)
        out['seed'] = a.evaluate("""async ({name, small, tiny}) => {
          await import('./bridge.mjs');
          await __call('open', name);
          const init = await __call('initializeLegacy', small);
          window.YoujiaRecoveryProbe.arm('intent_prepared_complete');
          const prep = await __call('prepare', tiny, init.current_token);
          __call('submit', prep.request_id, '1');
          for (let i = 0; i < 100 && !window.YoujiaRecoveryProbe.paused; i++) await new Promise(r => setTimeout(r, 20));
          return {init: init.verdict, paused: window.YoujiaRecoveryProbe.paused?.name || null};
        }""", {'name': name, 'small': small, 'tiny': TINY_PAYLOAD})
        a.close()
        b = ctx.new_page(); b.goto(base + 'budget.html'); b.evaluate(helpers)
        out['current_and_archive'] = b.evaluate("""async ({name, legacy, big}) => {
          await import('./bridge.mjs');
          const P = window.YoujiaRecoveryProbe;
          const opened = await __call('open', name);
          const before = await P.snapshot();
          const legacy_attempt = await __call('initializeLegacy', legacy);
          const prepare_attempt = await __call('prepare', big, before.current.commit_id);
          const after = await P.snapshot();
          return {opened: opened.verdict, archive_len: (before.archive || []).length, present: before.present,
            legacy_attempt, prepare_attempt, big_bytes: new TextEncoder().encode(big).length,
            unchanged: JSON.stringify(before) === JSON.stringify(after)};
        }""", {'name': name, 'legacy': legacy_ok, 'big': big_game})
        b.close()
        c = ctx.new_page(); c.goto(base + 'budget.html'); c.evaluate(helpers)
        out['intent_seed'] = c.evaluate("""async ({name, tiny}) => {
          await import('./bridge.mjs');
          const P = window.YoujiaRecoveryProbe;
          const opened = await __call('open', name);
          P.arm('intent_prepared_complete');
          const prep = await __call('prepare', tiny, opened.current_token);
          __call('submit', prep.request_id, '2');
          for (let i = 0; i < 100 && !P.paused; i++) await new Promise(r => setTimeout(r, 20));
          return {opened: opened.verdict, paused: P.paused?.name || null};
        }""", {'name': name, 'tiny': TINY_PAYLOAD})
        d = ctx.new_page(); d.goto(base + 'budget.html')
        out['intent_present'] = d.evaluate("""async ({name, big}) => {
          const {openStore, envelope} = await import('./store.mjs');
          const s = await openStore(name);
          const before = await s.snapshot();
          let env_error = null, submit_error = null;
          try { await envelope(big, before.current); } catch (e) { env_error = String(e); }
          const forged = {...before.intent.candidate, payload_bytes: big};
          const t0 = performance.now();
          const timeout = new Promise(r => setTimeout(() => r('TIMEOUT waiting (lock?)'), 3000));
          submit_error = await Promise.race([s.submit(forged).then(() => 'ACCEPTED', e => String(e)), timeout]);
          const ms = performance.now() - t0;
          const after = await s.snapshot();
          s.close();
          return {intent_state: before.intent?.state, present: before.present, env_error, submit_error,
            submit_ms: Math.round(ms), unchanged: JSON.stringify(before) === JSON.stringify(after)};
        }""", {'name': name, 'big': big_game})
        d.close(); c.close()
        e = ctx.new_page(); e.goto(base + 'budget.html'); e.evaluate(helpers)
        out['cleanup'] = e.evaluate("""async (name) => { await import('./bridge.mjs'); const r = await __call('open', name);
          await window.YoujiaRecoveryProbe.cleanup(); return r.verdict; }""", name)
        e.close()
        self.results['state_preservation'] = out
        s, ca, ip = out['seed'], out['current_and_archive'], out['intent_present']
        self.check('existing:seed_archive', s['init'] == 'clean' and s['paused'] == 'intent_prepared_complete' and
                   ca['opened'] == 'restored_parent_intent_rejected' and ca['archive_len'] == 1, json.dumps(s))
        self.check('existing:legacy_import_refused_unchanged', 'legacy import requires empty recovery' in
                   ca['legacy_attempt'].get('error', '') and ca['unchanged'], ca['legacy_attempt'].get('error', 'ACCEPTED'))
        self.check('existing:oversized_game_prepare_refused_unchanged', 'bounded frozen JSON text required' in
                   ca['prepare_attempt'].get('error', '') and ca['unchanged'],
                   f"natural_04 primary {ca['big_bytes']} B: {ca['prepare_attempt'].get('error', 'ACCEPTED')}")
        self.check('existing:intent_preserved_oversized_rejected_without_lock',
                   out['intent_seed']['paused'] == 'intent_prepared_complete' and ip['intent_state'] == 'prepared' and
                   'bounded frozen JSON text required' in (ip['env_error'] or '') and
                   ip['submit_error'] == 'Error: invalid candidate' and ip['unchanged'],
                   f"submit {ip['submit_error']} in {ip['submit_ms']} ms")

    def run(self, out_path):
        site = pathlib.Path(tempfile.mkdtemp(prefix='youjia-budget-site-'))
        profile = pathlib.Path(tempfile.mkdtemp(prefix='youjia-budget-profile-'))
        for f in ('store.mjs', 'legacy_v5.mjs', 'source_decode.mjs', 'bridge.mjs'):
            shutil.copy(self.host / f, site / f)
        (site / 'budget.html').write_text('<!doctype html><meta charset="utf-8"><title>budget</title>\n'
                                          + (self.host / 'head.html').read_text(), encoding='utf-8')
        handler = functools.partial(QuietHandler, directory=str(site))
        server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        base = f'http://127.0.0.1:{server.server_address[1]}/'
        try:
            with sync_playwright() as pw:
                ctx = pw.chromium.launch_persistent_context(str(profile), executable_path=browser_path(), headless=True)
                self.results['browser'] = ctx.browser.version if ctx.browser else 'chromium'
                pure_page = ctx.new_page(); pure_page.goto(base + 'budget.html')
                for s in self.meta['samples']:
                    self.sample(ctx, base, pure_page, s)
                pure_page.close()
                by_name = {s['name']: s for s in self.meta['samples']}
                self.preservation(ctx, base, by_name)
                ctx.close()
        finally:
            server.shutdown()
            shutil.rmtree(profile, ignore_errors=True)
            shutil.rmtree(site, ignore_errors=True)
        for s in self.meta['samples']:
            for role in ('primary', 'backup'):
                if s[role]['status'] == 'present':
                    self.check(f"{s['name']}:source_file_untouched_{role}",
                               sha256((self.dir / s[role]['file']).read_bytes()) == s[role]['sha256'])
        self.check('generator_errors_empty', not self.meta['errors'], '; '.join(self.meta['errors']))
        failed = [c for c in self.checks if c['status'] == 'FAIL']
        self.results['summary'] = {'checks': len(self.checks), 'failed': len(failed),
                                   'failed_ids': [c['id'] for c in failed]}
        pathlib.Path(out_path).write_text(json.dumps(self.results, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
        print(f"[save-payload-budget] {len(self.checks) - len(failed)}/{len(self.checks)} checks PASS, {len(failed)} FAIL")
        return 1 if failed else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--samples', required=True)
    ap.add_argument('--host', required=True)
    ap.add_argument('--host-sha', required=True)
    ap.add_argument('--repo-head', required=True)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    sys.exit(Run(a.samples, a.host, a.host_sha, a.repo_head).run(a.out))


if __name__ == '__main__':
    main()
