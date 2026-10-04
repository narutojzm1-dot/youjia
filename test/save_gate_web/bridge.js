// Isolated same-page experiment. Not a production Host or multi-tab lock.
window.GateProbe = {
  db: null, busy: false, failed: false, name: 'youjia-gate-test-' + crypto.randomUUID(), events: [],
  fail(message) { this.failed = true; window.gateError = message; },
  async run(raw, abort, callback) {
    if (this.busy) { this.fail('competing host write'); return; }
    this.busy = true;
    try {
      const request = JSON.parse(raw);
      if (!this.db) {
        this.db = await new Promise((ok, no) => {
          const r = indexedDB.open(this.name, 1);
          r.onupgradeneeded = () => r.result.createObjectStore('records');
          r.onsuccess = () => ok(r.result); r.onerror = () => no(r.error);
        });
        await this.write({token: 'parent-0', bytes: '{"value":"parent"}'}, false);
      }
      const parent = await this.read();
      if (parent.token !== request.parent_token) throw Error('parent mismatch');
      const candidate = {token: request.candidate_token, bytes: JSON.stringify(request.payload)};
      const terminal = await this.write(candidate, abort);
      const observed = await this.read();
      const expected = abort ? parent : candidate;
      if (JSON.stringify(observed) !== JSON.stringify(expected)) throw Error('exact record mismatch');
      this.events.push(terminal);
      const receipt = JSON.stringify({schema: 'youjia.save-receipt/v1', write_id: request.write_id,
        candidate_token: request.candidate_token, parent_token: request.parent_token,
        observed_token: observed.token, old_write_terminated: true});
      // Delay delivery after real transaction end; Gate still owns pending write.
      setTimeout(() => { this.busy = false; callback(receipt); }, 50);
    } catch (e) { this.fail(String(e)); } // unknown stays owned; never synthesize a success
  },
  write(value, abort) {
    return new Promise((ok, no) => {
      const t = this.db.transaction('records', 'readwrite');
      const r = t.objectStore('records').put(value, 'current');
      r.onsuccess = () => { if (abort) t.abort(); };
      t.oncomplete = () => abort ? no(Error('abort unexpectedly committed')) : ok('complete');
      t.onabort = () => abort ? ok('abort') : no(t.error || Error('unexpected abort'));
    });
  },
  read() {
    return new Promise((ok, no) => {
      let value; const t = this.db.transaction('records', 'readonly');
      const r = t.objectStore('records').get('current'); r.onsuccess = () => value = r.result;
      t.oncomplete = () => ok(value); t.onabort = () => no(t.error);
    });
  },
  async done(checks) {
    this.db.close();
    const r = indexedDB.deleteDatabase(this.name);
    r.onerror = () => this.fail('cleanup failed'); r.onblocked = () => this.fail('cleanup blocked');
    r.onsuccess = () => { if (!this.failed) window.gateResult = {checks, events: this.events, removed: true}; };
  }
};
