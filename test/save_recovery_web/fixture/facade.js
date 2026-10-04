// #239 业务夹具的 JS 门面（CURSOR-CLOUD）：只转发给 Godot 场景并公开其状态，不读写存储。
window.YoujiaRecoveryFixture = {
  // started：Godot 夹具已运行并发布过状态；ready：可写。两者分开，等锁或无锁拒绝时 started 为真而 ready 为假。
  started: false,
  ready: false,
  blocked_reason: 'godot fixture not started',
  _state: null,
  _grant: null,
  _publish(raw) {
    this._state = JSON.parse(raw);
    this.started = true;
    this.ready = this._state.ready;
    this.blocked_reason = this._state.blocked_reason;
  },
  grant(serial) {
    if (!this._grant) throw Error('godot fixture not attached');
    this._grant(serial);
  },
  business() {
    return this._state && structuredClone(this._state);
  },
};
