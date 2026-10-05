# #150 Engine-ready + page Host lifecycle candidate

Owner CODEX-LEAD; based on PR251 `0dbff93ae2a78ceb3aa5d54c86a3a38da6475b89`. This is a working adapter on the development branch, not a production SaveStore switch or Host freeze.

`test/save_recovery_r1/lifecycle.mjs` supplies an optional, single-use page session. The existing `bridge.mjs` and `head.html` consume it when the embedding shell provides `window.YoujiaSaveRuntimeReady`: a Promise resolved only after the real `engine.startGame()` completes. Existing fixture callers keep their original behavior. `open` first waits for engine completion, then acquires a nonwaiting exclusive `storeName:page-writer` Web Lock held until the page closes (or probe cleanup). A second page fails closed before database open/source capture. All mutating bridge entry points require ready lifecycle state. Existing receipt schema and store transaction/readback verification are unchanged; no substitute echo Host, no second public wire protocol.

## Actual Web evidence

`build.sh` exports the real Godot `main.gd`, source reader and existing R1 bridge/store modules using matching Godot4.7.2 release templates. The exported shell publishes the engine completion promise, rather than injecting an already-resolved readiness promise. The driver:

1. Writes a legacy file through actual Godot FileAccess, then waits until those bytes appear in the real IDBFS `FILE_DATA` store before reload.
2. Reloads Godot on the same fresh browser origin/profile; Godot calls existing `host.open`, and only its callback captures `user://` sources.
3. Checks capture occurs after real engine completion and imported text preserves `9007199254740993` exactly (no parse/serialize of legacy data).
4. Runs real `prepare → submit → verified receipt → acknowledge`, with Godot consuming parent/candidate/observed identity and termination before ack.
5. Opens a second actual Godot page; lifetime ownership refuses it. Closing the original page releases the browser lock; reloading the second recovers the written payload.

Results: `evidence.json`, 17 checks. Existing migration bridge regression:16 checks. These are local actual Chromium/Godot/IndexedDB results, not Pages, physical power loss, production origin, low-end performance, or continuous old-client exclusion.

```sh
OUT=/absolute/disposable-build GODOT=/absolute/godot XDG_DATA_HOME=/matching/templates/data bash test/save_lifecycle_web/build.sh
python test/save_lifecycle_web/run.py --web /absolute/disposable-build/web --out /absolute/evidence.json
```

## Exact remaining production wiring

- `web/loading.html::start()`: publish the runtime-ready Promise before the engine begins, resolve after `await engine.startGame({onProgress})`, reject in the existing catch path. Never infer persistence readiness from DOM/first-frame. Current production shell is unchanged in this slice.
- `autoload/save_store.gd::_ready/_load`: currently synchronous old-source reads; replace boot with existing bridge.open callback then `source_snapshot.capture` only for verified empty target. Existing trusted target resumes from verified current; no repeated legacy imports.
- `autoload/save_store.gd::save` and setters (`set_album`, locale/tutorial/fish/relationship/yard methods): synchronous bool and pre-write in-memory mutation cannot be relabeled durable. Route frozen candidates through Gate/prepare/submit, publish confirmed state only after validated receipt; UI pending/error paths are needed. This slice's Godot consumer shows the real method chain but does not silently change gameplay setters.
- `scripts/main.gd` album acceptance and other bool/void setter consumers need pending/confirmed semantics before switching storage ownership. #190 Gate remains separately reviewed; this slice does not modify it or Cloud exploration/#305 tests.
- Page lock protects **participating new Host clients only**. Old tabs use legacy IDBFS and do not request this lock. Production rollout must prevent concurrent legacy writers; this slice cannot claim old-client quiescence just because new pages exclude each other. The seed page deliberately demonstrates legacy input, and is closed/reloaded before migration.
- Absent/read_error/unsupported source and storage failures stay blocked through existing R1 semantics. No production initialization/reset, no old-source deletion, no recovery evidence eviction.

## PR316 review corrections

The lifecycle constructor immediately observes runtime rejection and stores a fulfilled outcome instead of leaving a rejected Promise unobserved until `open`. Failure before Godot calls `open` marks the session blocked; later `open` propagates the original failure. The browser test waits across task turns before `open` and verifies no `unhandledrejection`.

Godot freezes the prepared candidate/request and write identity. It requires the exact six-field v1 receipt, expected schema/write ID, frozen candidate/parent/observed identities, and an actual boolean terminal flag before acknowledgement. The acknowledgement's request ID and status are also verified before reporting done. Four browser cases intercept **actual durable Host callbacks**, changing candidate+observed together, write ID, schema, or terminal flag type; each actual Godot consumer rejects without calling acknowledge, and actual IndexedDB committed intent/current remain available for recovery. These are adversarial callback tests, not fake successful storage.

## Shell-before-module rejection observer

The generated shell now observes the runtime Promise **at creation** using a side-branch catch; `head.html` also observes before starting the dynamic import. Neither replaces the original Promise, so Host still receives its rejection. `runtime_failure.py` delays the actual bridge module response until after actual `engine.startGame` fails to preload `index.pck` (controlled HTTP404), then waits another150ms before releasing the module. Four checks prove failure precedes module configuration, no unhandled rejection, later Host open propagates the exact same original error, and no Host database or source capture occurs. `/userfs` may be initialized by the engine; it is not a Host database. Evidence: `runtime-failure-evidence.json`.

```sh
python test/save_lifecycle_web/runtime_failure.py --web /absolute/disposable-build/web --out /absolute/runtime-failure-evidence.json
```
