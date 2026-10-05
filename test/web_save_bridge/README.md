# #149/#150 B1 production Godot Host bridge (inactive)

Agent-ID: CODEX-LEAD internal bridge slice. Base main `5f74afb1eaf521f0f2df9401138b248b560b04a4`. New production files are `scripts/persistence/web_save_host.gd` and `web_save_reply.gd`; no autoload, project, loading shell, SaveStore, Main or Cloud changes. This is not a launched save migration or a freeze of the entire Host/queue contract.

## Backend contract for B2 coordinator

Attach the Node before use. `request(method, args, expected={}) -> String` returns a **local bridge request ID**, distinct from Host request_id. Empty return means local refusal (read `last_request_error`), with no write accepted and no completed signal. Only one request is in flight. Completion is always deferred until after request returns:

`completed(local_request_id, method, {status, code, wire})`

- open: args `{}`; statuses ready / empty / blocked. wire preserves all six Host fields, including exact `current_payload`, `current_token` and verified full `current_envelope`. B2 owns business projection.
- initialize: `{payload: String, paths: {primaryPath: String, backupPath: String}}`; paths must come from production `ProjectSettings.globalize_path`, not player input. Same open result.
- prepare: `{payload: String, parent_token: String, write_id: String}`; status prepared. wire is the entire nine-field prepared identity. Bridge checks payload SHA, parent, known store and next int64 generation. Write IDs are canonical positive int64 decimal strings.
- submit / resolve / acknowledge: `{request_id: String, write_id: String}`, optionally expected=the **entire prepared wire dictionary**. Bridge always checks its own frozen prepared identity even when expected is empty. submit cannot be repeated; after timeout use resolve with the original identity. resolve requires a submitted flight; acknowledge requires confirmed.
- submit/resolve return confirmed or rejected only after all 14 receipt fields, complete identity, observed token, terminal transaction and bool flags match. Rejected requires terminated verified parent; a confirmed flight can never be reversed by a later parent receipt.
- acknowledge status acknowledged, only cleared/already_clear. Failure is ack_failed and does not roll back known confirmed current/token. Another prepare remains blocked until ack succeeds or verified rejection.
- close `{}` returns closed when Host permits it.

JS errors, malformed/foreign replies and timeout are **unknown** for submit/resolve, **ack_failed** for ack, **blocked** otherwise. They never manufacture a rejection or success. The coordinator must retain pending/confirmed semantics accordingly. Wire schema and namespace are fixed to the production contract; no public `trusted` boolean is consumed.

## Wire and callback boundaries

Decoder rejects extra/missing fields, numeric or malformed identities, non-bool proof flags, duplicate keys (including escaped duplicates), arrays/numeric tokens in the outer reply and trailing commas. Open envelopes v1/v2 have strict keys/types, payload UTF8 SHA256 and canonical big-endian uint64-length-prefixed field digest recomputed in Godot; root and child budgets are 3.5MiB/1.5MiB. The optional legacy seal SHA is part of the v2 digest, but this bridge does not reread/verify the separate permanent raw slot—that belongs to the JS Host.

Outer wire bound is 44MiB to accommodate JSON escaping and open's duplicate payload text; it is not a RAM/quota guarantee. Schema validation cannot authenticate a hostile same-origin JS program; the production bootstrap must load the reviewed fixed Host.

One Godot callback is routed through a JS registry. Per-request JS closures carry only router key/local ID. Timeout removes the pending match; late/duplicate callbacks cannot settle it or a later request. Node exit unregisters the callback, so retained JS closures safely no-op. Node exit does **not** claim to cancel an already-started IndexedDB write or release the JS Host lock; lifecycle/coordinator must close cleanly, or next page reload must recover. Timeouts use monotonic time and process while the tree is paused.

## Verification / reproduction

```
godot --headless --path . --script test/web_save_bridge/decoder_suite.gd
OUT=/absolute/disposable GODOT=/path/to/Godot4.7.2 \
 HOST_SOURCE=/workspace/youjia-production-host/web/save \
 XDG_DATA_HOME=/path/with/4.7.2-templates bash test/web_save_bridge/build.sh
TMPDIR=/workspace/browser-tmp python test/web_save_bridge/run.py \
 --web /absolute/disposable/web --out /absolute/result.json
```

The build copies the two exact production Godot scripts and the JS Host from independently delivered `f266e062edfb4cc2c8f0536e98ac3312efc9da7b` into a disposable minimal Godot project. No test module is imported into production. Its shell installs the actual production JS bridge, starts actual Godot with persistentPaths:[], and resolves runtimeReady from actual engine startup. Legacy capture is synthetic absent/v5 in this B1 fixture; **this does not repeat or replace the separately verified real IDBFS reader**.

Native adversarial suite: 45 checks across envelope hashes, strict field/type/identity checks, duplicate/late callbacks, deferred completion, timeout unknown, ack failure preserving confirmed state. Real Godot Web → production JS Host: 42 checks across fresh initialize, v2 sealed legacy initialize, prepare/submit/resolve/ack/close and reload exact payload for both, plus late JS callback after Node destruction. Browser evidence is `evidence.json`; no browser errors. Export/import logs must contain no SCRIPT ERROR/ERROR, not merely exit0.

Remaining integration gates: B2 coordinator composition, actual SaveStore/Main/Cloud async consumers, full-game boot and loading shell, simultaneous old/new live game behavior, user-facing blocked/unknown/recovery UI, target browsers beyond Chromium, independent final SHA review. Nothing here enables production persistence or asserts those gates complete.

## Additive readonly APIs (B1 follow-up)

The bridge now additionally requires the reviewed Host APIs at JS commit `1319bffb7ef69619d03a25ff9d8695e8928b032b`:

- `request("inspectLegacy", {paths: {primaryPath, backupPath}})`
- `request("exportRecovery", {paths: {primaryPath, backupPath}})`

Both require ready current state and no unacknowledged write; neither changes current, acknowledges writes nor merges legacy progress. Same deferred completion wrapper. Valid replies expose `status` as `same`, `changed`, `absent`, or `unavailable`; inspection wire is direct, export wire contains `inspection`, `current_envelope`, `legacy_sources`, `legacy_snapshot`. **Unavailable is an incomplete export, not a complete backup.** Invalid structure, identity, hashes, or timeout yields blocked. Callers can save the validated wire to a user-selected export, but must clearly label incomplete captures and the observation time. Separate old/new DB reads are not one cross-database transaction.

`web_save_legacy_reply.gd` validates exact nested fields; bounded integral numeric byte counts (only these new wire APIs allow JSON number tokens); enum consistency and aggregate status; raw source canonical base64, original-byte SHA and size; full current envelope; immutable seal canonical digest and envelope binding; baseline source fingerprints. Inspection token must equal the bridge's known current token, and export store identity must match. No seal plus any old present data is changed. Invalid UTF8 remains raw exportable. A valid read_error remains unavailable. Duplicate-key protection remains active at every object depth.

Native `legacy_suite.gd`: 22 additional adversarial checks, with original 45 checks still passing. Updated actual Godot Web fixture: 80 checks, including malformed base64/current hash/token/seal rejection and a real Host read_error response that is preserved as incomplete unavailable export; Chromium errors empty. The fixture's reader remains synthetic—the separate reviewed real IDBFS adapter coverage is not replaced. Final incremental evidence is `evidence.json`.
