"""#150 R2/R3 真实浏览器验收驱动（#239，CURSOR-CLOUD）。

只做测试侧：持久化 browser context 下关页/开页、双页锁竞争、故障注入与采证。
存储实现与屏障由 R1 候选（CODEX-LEAD）通过 window.YoujiaRecoveryProbe 提供；
缺少候选或屏障时对应场景报 BLOCKED，绝不用假回执凑 PASS。
退出码：0 全部 PASS；1 有 FAIL；2 无 FAIL 但有 BLOCKED。
"""
import argparse, functools, hashlib, http.server, json, os, pathlib, shutil, subprocess, sys, tempfile, threading, time, uuid
from playwright.sync_api import sync_playwright

PROBE_SCHEMA = 'youjia.recovery-probe/v1'
STORE_PREFIX = 'youjia-recovery-test-'
BARRIER_PREPARED = 'intent_prepared_complete'
BARRIER_COMMITTED = 'candidate_committed_before_receipt'
NO_LOCKS_SCRIPT = 'try { delete Navigator.prototype.locks; } catch (e) {}'
WAIT_MS = int(os.environ.get('RECOVERY_WAIT_MS', '60000'))
HERE = pathlib.Path(__file__).resolve().parent


class Blocked(Exception):
    pass


class Scenario:
    def __init__(self, name):
        self.name, self.checks, self.failures, self.evidence = name, 0, [], {}
        self.store = STORE_PREFIX + uuid.uuid4().hex

    def check(self, ok, label):
        if ok:
            self.checks += 1
        else:
            self.failures.append(label)
        return ok


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def serve(root):
    handler = functools.partial(QuietHandler, directory=str(root))
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def browser_path():
    for candidate in (os.environ.get('CHROME'), '/usr/bin/chromium', '/usr/bin/google-chrome'):
        if candidate and pathlib.Path(candidate).exists():
            return candidate
    raise SystemExit('no Chromium/Chrome found; set CHROME')


def wait_value(page, expression, timeout=WAIT_MS):
    page.wait_for_function(expression, timeout=timeout)
    return page.evaluate(expression)


# ---------- 驱动自检：只证明 context/锁/能力探测可靠，不是 R2/R3 ----------

def selfcheck(context, base):
    s = Scenario('driver_selfcheck')
    url = lambda op, extra='': f'{base}/selfcheck/index.html?recovery_store={s.store}&op={op}{extra}'
    token = uuid.uuid4().hex
    page = context.new_page()
    page.goto(url('write', f'&token={token}'))
    s.check(wait_value(page, 'window.selfcheck') == {'written': token}, 'write record')
    page.close()
    page = context.new_page()
    page.goto(url('read'))
    s.check(wait_value(page, 'window.selfcheck') == {'token': token}, 'record survives page close in same context')
    page.close()

    holder = context.new_page()
    holder.goto(url('hold'))
    s.check(wait_value(holder, 'window.selfcheck') == {'held': True}, 'page A holds exclusive lock')
    other = context.new_page()
    other.goto(url('try'))
    wait_value(other, 'window.selfcheck')
    s.check(other.evaluate('window.tryLock()') is False, 'page B cannot take lock while A holds it')
    holder.close()
    acquired = False
    deadline = time.time() + WAIT_MS / 1000
    while time.time() < deadline and not acquired:
        acquired = other.evaluate('window.tryLock()') is True
        if not acquired:
            time.sleep(0.1)
    s.check(acquired, 'closing page A releases lock for page B')
    other.close()

    page = context.new_page()
    page.goto(url('caps'))
    s.check(wait_value(page, 'window.selfcheck').get('web_locks') is True, 'web locks present by default')
    page.close()
    page = context.new_page()
    page.add_init_script(NO_LOCKS_SCRIPT)
    page.goto(url('caps'))
    s.check(wait_value(page, 'window.selfcheck').get('web_locks') is False, 'init script removes web locks')
    page.close()

    page = context.new_page()
    page.goto(url('cleanup'))
    s.check(wait_value(page, 'window.selfcheck') == {'removed': True}, 'fixture store removed')
    page.close()
    page = context.new_page()
    page.goto(url('read'))
    s.check(wait_value(page, 'window.selfcheck') == {'token': None}, 'removed store reads empty')
    page.goto(url('cleanup'))
    wait_value(page, 'window.selfcheck')
    page.close()
    page = context.new_page()
    page.goto(f'{base}/selfcheck/index.html?recovery_store=player-save&op=read')
    s.check(wait_value(page, 'window.selfcheck') == {'error': 'store prefix rejected'}, 'non-test store name rejected')
    page.close()
    return s


# ---------- R1 候选场景 ----------

class Candidate:
    def __init__(self, context, base, scenario):
        self.context, self.base, self.s = context, base, scenario

    def open(self, no_locks=False, writable=True):
        page = self.context.new_page()
        if no_locks:
            page.add_init_script(NO_LOCKS_SCRIPT)
        errors = []
        page.on('pageerror', lambda e: errors.append(str(e)))
        page.goto(f'{self.base}/index.html?recovery_store={self.s.store}')
        state_js = ('({probe: !!window.YoujiaRecoveryProbe, fixture: !!window.YoujiaRecoveryFixture, '
                    'started: !!(window.YoujiaRecoveryFixture && window.YoujiaRecoveryFixture.started), '
                    'reason: window.YoujiaRecoveryFixture && window.YoujiaRecoveryFixture.blocked_reason})')
        ## 第一级：Probe 已挂载且 Godot 夹具已启动。等锁的 B 页、无锁页只需要这一级。
        try:
            page.wait_for_function('window.YoujiaRecoveryProbe && window.YoujiaRecoveryFixture && window.YoujiaRecoveryFixture.started', timeout=WAIT_MS)
        except Exception:
            state = page.evaluate(state_js)
            page.close()
            if state['probe'] and state['fixture']:
                ## 候选已就位而本仓库的夹具没启动：属于夹具自身失败，不归咎于缺依赖。
                raise AssertionError('fixture loaded but Godot never started it')
            raise Blocked(f"probe={'yes' if state['probe'] else 'missing'}; fixture="
                          f"{'missing' if not state['fixture'] else 'not started'}")
        state = page.evaluate(state_js)
        if str(state['reason']).startswith('host bridge missing'):
            page.close()
            raise Blocked(f"probe={'yes' if state['probe'] else 'missing'}; fixture=not ready: {state['reason']}")
        schema = page.evaluate('window.YoujiaRecoveryProbe.schema')
        if schema != PROBE_SCHEMA:
            page.close()
            raise Blocked(f'probe schema {schema!r} != {PROBE_SCHEMA}')
        page.errors = errors
        ## 第二级：可写。桥接已在时仍不可写属于被测行为问题，记 FAIL 而不是 BLOCKED。
        if writable:
            try:
                page.wait_for_function('window.YoujiaRecoveryFixture.ready', timeout=WAIT_MS)
            except Exception:
                reason = page.evaluate('window.YoujiaRecoveryFixture.blocked_reason')
                page.close()
                raise AssertionError(f'fixture never became writable: {reason}')
        return page

    @staticmethod
    def call(page, expression):
        return page.evaluate(f'async () => await ({expression})')

    def require_barrier(self, page, name):
        caps = self.call(page, 'window.YoujiaRecoveryProbe.capabilities()')
        if name not in (caps or {}).get('barriers', []):
            raise Blocked(f'barrier {name} not provided by R1 candidate')

    def require_injection(self, page, name):
        caps = self.call(page, 'window.YoujiaRecoveryProbe.capabilities()')
        if name not in (caps or {}).get('injections', []):
            raise Blocked(f'injection {name} not provided by R1 candidate')

    def recovery(self, page):
        page.wait_for_function('window.YoujiaRecoveryProbe.recovery && window.YoujiaRecoveryProbe.recovery()', timeout=WAIT_MS)
        return self.call(page, 'window.YoujiaRecoveryProbe.recovery()')

    def snapshot(self, page):
        return self.call(page, 'window.YoujiaRecoveryProbe.snapshot()')

    def business(self, page):
        return self.call(page, 'window.YoujiaRecoveryFixture.business()')

    def grant(self, page, serial):
        return self.call(page, f'window.YoujiaRecoveryFixture.grant({int(serial)})')

    def settled(self, page, serial):
        page.wait_for_function(f'(() => {{ const b = window.YoujiaRecoveryFixture.business(); return b && !b.pending && b.watermark >= {int(serial)}; }})()', timeout=WAIT_MS)
        return self.business(page)

    def pause_at(self, page, barrier, serial):
        self.require_barrier(page, barrier)
        self.call(page, f'window.YoujiaRecoveryProbe.arm({json.dumps(barrier)})')
        self.grant(page, serial)
        page.wait_for_function(f'(window.YoujiaRecoveryProbe.paused || {{}}).name === {json.dumps(barrier)}', timeout=WAIT_MS)
        return page.evaluate('window.YoujiaRecoveryProbe.paused')

    def cleanup(self, page):
        ## 参与页仍连着库时删除会被 onblocked 拦下；先关闭参与页，再用自检页按测试库名删除。
        if not page.is_closed():
            page.close()
        cleaner = self.context.new_page()
        cleaner.goto(f'{self.base}/selfcheck/index.html?recovery_store={self.s.store}&op=cleanup')
        self.s.check(wait_value(cleaner, 'window.selfcheck') == {'removed': True}, 'fixture store removed after pages closed')
        cleaner.close()


def grants_of(business, serial):
    return list((business or {}).get('grants', [])).count(serial)


def business_of(record):
    ## 业务水位与授予列表只以可信 current 封套的 payload 为准（R1 store.mjs 不解释业务）。
    try:
        return json.loads(((record or {}).get('current') or {}).get('payload_bytes') or 'null')
    except ValueError:
        return None


def archived_rejected(record, request_id):
    return any(a.get('request_id') == request_id and a.get('state') == 'rejected'
               for a in ((record or {}).get('archive') or []))


def r2_close_after_prepared(c):
    s = c.s
    page = c.open()
    before = c.snapshot(page)
    paused = c.pause_at(page, BARRIER_PREPARED, 1)
    at_close = c.snapshot(page)
    s.evidence.update(before=before, paused=paused, at_close=at_close)
    page.close()
    page = c.open()
    rec = c.recovery(page)
    s.evidence['recovery'] = rec
    s.check(rec.get('verdict') == 'restored_parent_intent_rejected', 'new page restores trusted parent')
    s.check(rec.get('current', {}).get('commit_id') == before.get('current', {}).get('commit_id'), 'current is the parent commit')
    s.check(rec.get('intent') is None, 'active intent slot cleared')
    s.check(archived_rejected(rec, paused.get('request_id')), 'prepared intent archived as rejected')
    s.check((business_of(rec) or {}).get('watermark') == (business_of(before) or {}).get('watermark'), 'watermark unchanged')
    c.grant(page, 1)
    c.settled(page, 1)
    s.evidence['after_retry'] = c.snapshot(page)
    s.check(grants_of(business_of(s.evidence['after_retry']), 1) == 1, 'retry of same serial grants exactly once')
    s.check(s.evidence['after_retry'].get('current', {}).get('request_id') != paused.get('request_id'), 'retry used a new request_id')
    s.evidence['events'] = c.call(page, 'window.YoujiaRecoveryProbe.events()')
    s.check(not page.errors, 'no page errors')
    c.cleanup(page)


def r2_close_after_commit(c):
    s = c.s
    page = c.open()
    before = c.snapshot(page)
    paused = c.pause_at(page, BARRIER_COMMITTED, 1)
    at_close = c.snapshot(page)
    s.evidence.update(before=before, paused=paused, at_close=at_close)
    page.close()
    page = c.open()
    rec = c.recovery(page)
    s.evidence['recovery'] = rec
    s.check(rec.get('verdict') == 'restored_candidate', 'new page restores committed candidate')
    s.check(rec.get('current', {}).get('request_id') == paused.get('request_id'), 'current carries paused request_id')
    s.check((business_of(rec) or {}).get('watermark') == 1, 'watermark includes serial 1')
    s.check(grants_of(business_of(rec), 1) == 1, 'serial 1 granted once after reload')
    c.grant(page, 1)
    c.settled(page, 1)
    s.evidence['after_repeat'] = c.snapshot(page)
    s.check(grants_of(business_of(s.evidence['after_repeat']), 1) == 1, 'repeat of committed serial does not grant again')
    s.check(s.evidence['after_repeat'].get('current') == rec.get('current'), 'repeat of committed serial writes nothing')
    s.evidence['events'] = c.call(page, 'window.YoujiaRecoveryProbe.events()')
    s.check(not page.errors, 'no page errors')
    c.cleanup(page)


def r3_lock_contention(c):
    s = c.s
    a = c.open()
    paused = c.pause_at(a, BARRIER_PREPARED, 1)
    b = c.open(writable=False)
    time.sleep(2)
    b_events = c.call(b, 'window.YoujiaRecoveryProbe.events()')
    s.check(not any(e.get('type') == 'lock_acquired' for e in b_events), 'page B does not acquire lock while A holds it')
    s.check(not any(e.get('type') == 'txn_complete' for e in b_events), 'page B performs no write while A holds lock')
    s.evidence.update(paused=paused, b_events_while_a=b_events)
    a.close()
    rec = c.recovery(b)
    s.evidence['recovery'] = rec
    s.check(rec.get('verdict') == 'restored_parent_intent_rejected', 'B recovers persisted intent after A closes')
    s.check(any(e.get('type') == 'lock_acquired' for e in c.call(b, 'window.YoujiaRecoveryProbe.events()')), 'B acquires lock after A closes')
    c.cleanup(b)


def r3_no_web_locks(c):
    ## 无锁页不开库（store.mjs 在开库前拒绝），库前后记录由正常页读取。
    s = c.s
    normal = c.open()
    c.recovery(normal)
    before = c.snapshot(normal)
    normal.close()
    page = c.open(no_locks=True, writable=False)
    rec = c.recovery(page)
    s.evidence.update(before=before, recovery=rec)
    s.check(rec.get('verdict') == 'no_web_locks', 'missing Web Locks is reported explicitly')
    c.grant(page, 1)
    time.sleep(2)
    events = c.call(page, 'window.YoujiaRecoveryProbe.events()')
    s.evidence['events'] = events
    s.check(not any(e.get('type') == 'txn_complete' for e in events), 'no write without Web Locks')
    s.check(not c.business(page).get('confirmed_serials'), 'nothing reported saved without Web Locks')
    page.close()
    normal = c.open()
    after = c.snapshot(normal)
    s.evidence['after'] = after
    s.check(after == before, 'stored records unchanged')
    c.cleanup(normal)


def receipt_fault(injection, options):
    def run(c):
        s = c.s
        page = c.open()
        c.require_injection(page, injection)
        before = c.snapshot(page)
        c.call(page, f'window.YoujiaRecoveryProbe.inject({json.dumps(options)})')
        c.grant(page, 1)
        time.sleep(3)
        mid = c.snapshot(page)
        business = c.business(page)
        s.evidence.update(before=before, injected=options, after_fault=mid, business_after_fault=business)
        if injection.startswith('abort_'):
            s.check(mid.get('current') == before.get('current'), 'aborted transaction leaves current unchanged')
            s.check(grants_of(business, 1) == 0, 'abort grants nothing')
            s.check(not business.get('confirmed_serials'), 'abort is not reported as saved')
        else:
            s.check(grants_of(business_of(mid), 1) <= 1, 'stored grants never duplicated')
            if injection in ('drop_receipt', 'wrong_receipt_identity'):
                s.check(business.get('pending') is True, 'business stays pending without a valid receipt')
            if injection in ('duplicate_receipt', 'delay_receipt'):
                business = c.settled(page, 1)
                s.check(grants_of(business, 1) == 1, 'duplicate/late receipt grants once')
        page.close()
        page = c.open()
        rec = c.recovery(page)
        s.evidence['recovery'] = rec
        s.check(grants_of(business_of(rec), 1) <= 1, 'reload never duplicates grant')
        s.evidence['events'] = c.call(page, 'window.YoujiaRecoveryProbe.events()')
        c.cleanup(page)
    return run


def r3_resolve_failure_cap(c):
    ## 模拟错误：先用 Probe 让 commit 事务真实 abort、submit 失败，再在测试侧把公开的 bridge.resolve
    ## 换成持续报错。这是人为传输故障，不是浏览器存储损坏；新开的页不带替换。
    s = c.s
    page = c.open()
    c.require_injection(page, 'abort_commit')
    before = c.snapshot(page)
    c.call(page, '''(async () => {
        const m = await import('./bridge.mjs');
        window.__resolveCalls = 0;
        m.bridge.resolve = async () => { window.__resolveCalls++; throw new Error('simulated persistent resolve failure'); };
        window.YoujiaRecoveryProbe.inject({abort_stage: 'commit'});
        window.YoujiaRecoveryFixture.grant(1);
    })()''')
    page.wait_for_function("window.YoujiaRecoveryFixture.business().blocked_reason.startsWith('resolve failed')", timeout=WAIT_MS)
    calls = page.evaluate('window.__resolveCalls')
    time.sleep(1.5)
    calls_later = page.evaluate('window.__resolveCalls')
    business = c.business(page)
    mid = c.snapshot(page)
    c.grant(page, 2)
    time.sleep(0.5)
    held = c.business(page)
    s.evidence.update(before=before, resolve_calls=calls, resolve_calls_later=calls_later,
                      business_after_fault=business, after_fault=mid, business_after_refused_grant=held)
    s.check(calls == 5 and calls_later == 5, 'resolve called at most 5 times, then stops')
    s.check(business.get('pending') is True and business.get('ready') is False, 'business stays unknown and not writable')
    s.check(not business.get('confirmed_serials') and business.get('watermark') == 0, 'nothing confirmed or granted')
    s.check(mid.get('current') == before.get('current'), 'aborted commit leaves current unchanged')
    s.check(2 in held.get('refused', []) and page.evaluate('window.__resolveCalls') == 5, 'later grant refused without new resolve calls')
    page.close()
    page = c.open()
    rec = c.recovery(page)
    s.evidence['recovery'] = rec
    s.check(rec.get('verdict') == 'restored_parent_intent_rejected', 'reopen restores parent and rejects the intent')
    s.check(business_of(rec) == {'watermark': 0, 'grants': []}, 'reopened payload has no grant')
    c.grant(page, 1)
    business = c.settled(page, 1)
    after = c.snapshot(page)
    s.evidence.update(business_after_reopen=business, after_reopen=after)
    s.check(business_of(after) == {'watermark': 1, 'grants': [1]}, 'writable again after reopen, grant commits once')
    s.check(not page.errors, 'no page errors')
    c.cleanup(page)


def r3_ack_txn_abort(c):
    ## 真实事务失败：拦截 IDBObjectStore.delete('intent') 并 abort 该事务，不伪造成功结果。
    s = c.s
    page = c.open()
    before = c.snapshot(page)
    c.call(page, '''(() => {
        window.__intentDeletes = 0;
        const original = IDBObjectStore.prototype.delete;
        IDBObjectStore.prototype.delete = function (key) {
            const request = original.call(this, key);
            if (key === 'intent') { window.__intentDeletes++; this.transaction.abort(); }
            return request;
        };
        window.YoujiaRecoveryFixture.grant(1);
    })()''')
    page.wait_for_function("window.YoujiaRecoveryFixture.business().blocked_reason.startsWith('acknowledge failed')", timeout=WAIT_MS)
    business = c.business(page)
    mid = c.snapshot(page)
    c.grant(page, 2)
    time.sleep(0.5)
    held = c.business(page)
    held_store = c.snapshot(page)
    s.evidence.update(before=before, intent_deletes=page.evaluate('window.__intentDeletes'), business_after_fault=business,
                      after_fault=mid, business_after_refused_grant=held, after_refused_grant=held_store)
    s.check(page.evaluate('window.__intentDeletes') >= 1, 'acknowledge transaction was really aborted')
    s.check(business.get('confirmed_serials') == [1] and business.get('watermark') == 1, 'confirmed grant is not rolled back')
    s.check(business.get('pending') is False and business.get('ready') is False, 'business settled but not writable')
    s.check(business_of(mid) == {'watermark': 1, 'grants': [1]} and mid.get('present', {}).get('intent'), 'current committed and intent still present')
    s.check(held.get('refused') == [2] and held_store == mid, 'later grant refused and storage unchanged')
    page.close()
    page = c.open()
    rec = c.recovery(page)
    reopened = c.snapshot(page)
    s.evidence.update(recovery=rec, after_reopen=reopened)
    s.check(business_of(rec) == {'watermark': 1, 'grants': [1]}, 'reopen keeps grant 1 exactly once')
    s.check(not reopened.get('present', {}).get('intent'), 'intent cleared after reopen')
    c.grant(page, 2)
    business = c.settled(page, 2)
    after = c.snapshot(page)
    s.evidence.update(business_after_reopen=business, after_second_grant=after)
    s.check(business_of(after) == {'watermark': 2, 'grants': [1, 2]}, 'writable again after reopen, grant 2 commits once')
    s.check(not page.errors, 'no page errors')
    c.cleanup(page)


def r2_same_frame_double_grant(c):
    ## 同一次 evaluate 内连续两次 grant：第二次在第一次收尾前必须被拒绝，且不得污染第一次的确认。
    s = c.s
    page = c.open()
    c.call(page, 'window.YoujiaRecoveryFixture.grant(1), window.YoujiaRecoveryFixture.grant(2)')
    business = c.settled(page, 1)
    ## 业务在 acknowledge 完成后才收尾，因此 pending 为假时意图必须已清理。
    stored = c.snapshot(page)
    s.evidence.update(business=business, stored=stored)
    s.check(business.get('watermark') == 1 and business.get('grants') == [1], 'business shows watermark 1 / grants [1]')
    s.check(business.get('confirmed_serials') == [1], 'only serial 1 confirmed')
    s.check(0 not in business.get('confirmed_serials', []), 'serial 0 never confirmed')
    s.check(business.get('refused') == [2], 'serial 2 refused while serial 1 in flight')
    s.check(business_of(stored) == {'watermark': 1, 'grants': [1]}, 'stored payload matches business')
    s.check(not stored.get('present', {}).get('intent'), 'intent slot cleared after acknowledge')
    c.grant(page, 2)
    business = c.settled(page, 2)
    after = c.snapshot(page)
    s.evidence.update(business_after_second=business, stored_after_second=after)
    s.check(business.get('refused') == [2] and business.get('confirmed_serials') == [1, 2], 'grant right after settle is accepted, not refused')
    s.check(business.get('grants') == [1, 2] and business_of(after) == {'watermark': 2, 'grants': [1, 2]}, 'later grant 2 commits once and matches storage')
    s.check(not page.errors, 'no page errors')
    c.cleanup(page)


SCENARIOS = [
    ('R2-a_close_after_intent_prepared', r2_close_after_prepared),
    ('R2-b_close_after_candidate_committed', r2_close_after_commit),
    ('R2-c_same_frame_double_grant', r2_same_frame_double_grant),
    ('R3-a_two_page_lock', r3_lock_contention),
    ('R3-b_no_web_locks', r3_no_web_locks),
    ('R3-c_drop_receipt', receipt_fault('drop_receipt', {'drop_receipt': True})),
    ('R3-c_wrong_receipt_identity', receipt_fault('wrong_receipt_identity', {'receipt_identity': 'wrong'})),
    ('R3-c_duplicate_receipt', receipt_fault('duplicate_receipt', {'duplicate_receipt': True})),
    ('R3-c_delay_receipt', receipt_fault('delay_receipt', {'delay_receipt_ms': 1500})),
    ('R3-c_abort_intent_txn', receipt_fault('abort_intent', {'abort_stage': 'intent'})),
    ('R3-c_abort_commit_txn', receipt_fault('abort_commit', {'abort_stage': 'commit'})),
    ('R3-d_resolve_failure_cap_simulated', r3_resolve_failure_cap),
    ('R3-d_ack_txn_abort', r3_ack_txn_abort),
]


def git_head():
    try:
        return subprocess.check_output(['git', '-C', str(HERE), 'rev-parse', 'HEAD'], text=True).strip()
    except Exception:
        return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--candidate', help='已导出的 R1 候选 Web 目录（含 index.html 与测试专用 Probe/Fixture）')
    parser.add_argument('--candidate-sha', help='被测 R1 候选完整 SHA')
    parser.add_argument('--out', required=True)
    args = parser.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    site = pathlib.Path(tempfile.mkdtemp(prefix='youjia-recovery-site-'))
    shutil.copytree(HERE / 'selfcheck', site / 'selfcheck')
    if args.candidate:
        for item in pathlib.Path(args.candidate).iterdir():
            target = site / item.name
            (shutil.copytree if item.is_dir() else shutil.copy2)(item, target)
    profile = pathlib.Path(tempfile.mkdtemp(prefix='youjia-recovery-profile-'))
    server = serve(site)
    base = f'http://127.0.0.1:{server.server_port}'
    results = []
    try:
        with sync_playwright() as p:
            context = p.chromium.launch_persistent_context(
                str(profile), executable_path=browser_path(), headless=True,
                args=['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
            version = context.browser.version if context.browser else None
            for name, fn in [('driver_selfcheck', None)] + SCENARIOS:
                started = time.time()
                if fn is None:
                    s = selfcheck(context, base)
                    status = 'PASS' if not s.failures else 'FAIL'
                    reason = 'driver capability only; not R2/R3'
                elif not args.candidate:
                    s, status, reason = Scenario(name), 'BLOCKED', 'no R1 candidate export (R1 未接线)'
                else:
                    s = Scenario(name)
                    try:
                        fn(Candidate(context, base, s))
                        status, reason = ('PASS' if not s.failures else 'FAIL'), None
                    except Blocked as e:
                        status, reason = 'BLOCKED', str(e)
                    except Exception as e:
                        s.failures.append(f'driver exception: {e!r}')
                        status, reason = 'FAIL', None
                results.append({'scenario': name, 'status': status, 'reason': reason, 'checks': s.checks,
                                'failures': s.failures, 'store': s.store, 'seconds': round(time.time() - started, 2),
                                'evidence': s.evidence})
                print(f'{status:8} {name} checks={s.checks}' + (f' ({reason})' if reason else '') + ''.join(f'\n         - {f}' for f in s.failures))
            context.close()
    finally:
        server.shutdown()
        shutil.rmtree(profile, ignore_errors=True)
        shutil.rmtree(site, ignore_errors=True)
    pck = pathlib.Path(args.candidate or '/nonexistent') / 'index.pck'
    report = {
        'schema': 'youjia.recovery-web-acceptance/v1',
        'driver_sha': git_head(),
        'candidate_sha': args.candidate_sha,
        'candidate_pck_sha256': hashlib.sha256(pck.read_bytes()).hexdigest() if pck.exists() else None,
        'browser': version,
        'playwright': __import__('importlib.metadata').metadata.version('playwright'),
        'results': results,
    }
    (out / 'result.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))
    statuses = {r['status'] for r in results}
    print(f'Evidence: {out / "result.json"}')
    sys.exit(1 if 'FAIL' in statuses else 2 if 'BLOCKED' in statuses else 0)


if __name__ == '__main__':
    main()
