# Production save Host slice A — #149 / #150

Agent-ID: CODEX-LEAD（内部实施子代理 host_budget_impl）。此为 CODEX-LEAD 内部协作，不接管外部 Assistant 的职责或认领。 This is an inactive production backend, not a published migration. Loading/export scripts and SaveStore integration belong to the coordinated next slice.

`web/save` extracts the independently reviewed R1 sealed implementation (84e2448e2b10f2006a5a771d63455f799c752247) into a fixed `youjia-save-host-v1` database. It has no public Probe, fault injection, barrier, database deletion or caller-selected namespace. Candidate budget remains 1.5 MiB source/write, 3.5 MiB imported payload, and 32 MiB retained records including permanent raw sources. This is not a production capacity freeze.

## Bootstrap and wire contract

Import `installSaveHost` from `web/save/bridge.mjs`; pass `{runtimeReady, captureLegacy}` once. The shell must immediately observe rejection when creating runtimeReady, retain its original rejection, install the bridge before Godot starts, and resolve runtimeReady only when actual engine startup succeeds. New engine startup must use `persistentPaths: []`. Readonly legacy capture is injected and happens only after readiness and page writer ownership. Existing old tabs are not stopped; they remain isolated writers to the old IDBFS database.

The frozen window.YoujiaSaveHost exposes only these asynchronous methods, with a final callback receiving one JSON string:

- `open(callback)`
- `initialize(default_payload, paths_json, callback)`; paths_json has exactly primaryPath and backupPath from actual Godot globalized paths.
- `prepare(payload, parent_token, write_id, callback)`
- `submit(request_id, write_id, callback)`
- `resolve(request_id, write_id, callback)`
- `acknowledge(request_id, write_id, callback)`
- `close(callback)`

Open has exactly schema (`youjia.host-open/v1`), status (empty/ready/blocked), code, current_payload, current_token, current_envelope. Empty carries empty strings and null envelope. A legacy import root exposes the validated import wrapper; business projection selects sources[selected].text without rewriting or discarding original text. Ordinary payloads are JSON objects with version 5.

Prepare returns exactly schema (`youjia.save-prepared/v1`), namespace, store_id, write_id, request_id, candidate_token, parent_token, payload_sha256, generation. Write IDs are canonical positive int64 decimal strings; request IDs are random 128-bit hex. Freeze the entire prepared identity before submitting.

Receipts have exactly schema (`youjia.save-receipt/v2`), namespace, store_id, write_id, request_id, candidate_token, parent_token, observed_token, payload_sha256, generation, outcome, transaction_state, readback_verified, old_write_terminated. Compare every identity field to prepare. Confirmed requires observed_token=candidate_token, complete transaction and both booleans true. Rejected is returned only by resolve after operation termination and verified parent recovery; observed_token=parent_token and transaction_state=terminated. Submission errors mean unknown outcome: resolve; never award or retry from a generic error. Acknowledgement requires confirmed outcome; next prepare requires acknowledgement or verified rejection.

Ack has exactly schema (`youjia.save-ack/v1`), namespace, request_id, write_id, status (cleared/already_clear). Error has exactly schema (`youjia.save-error/v1`), code, cause. Close has schema (`youjia.save-close/v1`), status=closed. Close refuses active work and never deletes durable state.

## Verification

Build requires Godot 4.7.2 with matching Web templates and the separately reviewed readonly reader at commit f376c447a3d17a0cabc66eadd7489fc643239da0 (`test/save_recovery_r1/idbfs_source.mjs`). The isolated test build copies it and changes only its budget import to this backend's identical production profile; it does not create another reader implementation.

```
OUT=/absolute/disposable/export GODOT=/path/to/godot CAPTURE_MODULE=/path/to/idbfs_source.mjs bash test/production_save_host/build.sh
python test/production_save_host/run.py --web /absolute/disposable/export/web --out /absolute/result.json
python test/production_save_host/suite.py --web /absolute/disposable/export/web --out /absolute/transaction-result.json
```

The Godot test writes actual user:// legacy files, waits for real IDBFS persistence, reloads without a persistent mount, imports original large-integer text, commits/acknowledges, checks permanent provenance, refuses a second writer and recovers from a new page. Supplementary browser tests abort actual native IndexedDB transactions from test code, covering intent and commit abort, unknown-to-resolved rejection, stale identity and write-after-rejection. No test abort API is shipped. A double-abort DOMException found through these tests is guarded while preserving authoritative terminal handlers.

Remaining integration: production shell imports/copies modules and the reader, production Godot strict decoder, asynchronous SaveStore business operations and UI confirmed/failed semantics. These tests do not claim those unrelated call sites are wired or the migration is published.
