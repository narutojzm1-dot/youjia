# Shared cleanup contract: ordinary candidate Web smoke

Runtime: `2b79d6538dab1e35a8dff6161b0104bce434196f`. Local formal no-observer export at `http://127.0.0.1:8194/`; this is not public release evidence.

Actual streamed `index.pck` SHA256: `3c4a9c2aeb17c80aa56f744ccaed517f7045bc6674255b66b027e1a5bf557e19`, matching supplied candidate. Chromium headless software WebGL, fresh isolated context, 1280×720; not a physical device.

## Observed

All six original PNGs were directly inspected. Normal title entry displays yard; normal album button displays empty journal, Escape closes it. The action labelled `walk` in raw driver clicked an animal vicinity: subsequent read-only storage contains naturally generated `sheep_pet_gentle` photo, and confirmation screenshot shows sheep target. Thus it is ordinary input, but is not claimed as an isolated movement-only test.

Pause → return-to-title confirmation → actual accept shows title. Re-entering shows the yard. Then an actual `page.close()` and new page in the same browser context again normally enter the yard. No page/console errors were captured (`result.json`: errors=[]).

Read-only IndexedDB selection: before return, current generation 2 contains sheep photo and a pending intent; after title current generation 3 contains the same photo and elapsed day time 9.3448, with intent absent. Continued and reopened snapshots exactly equal that full generation-3 envelope. `db.json` preserves all read-back records; `fullDBselected.json` preserves full selected envelopes and payload hashes. Photo remains in storage; a post-reopen album rendering was not separately checked.

## Limits and provenance

No business state, random seed, player position, save payload, or game API was injected. The only page init listener observes first-frame readiness; IndexedDB transactions are read-only. No artificial fault, cleanup UI/domain action or recovery scenario was exercised. Cloud has not integrated the new cleanup API, so this proves startup/export and ordinary existing save/title/reopen smoke only, not cleanup-domain end-to-end acceptance, reset behavior, touch, physical devices, or migration.

`run.py` is the executed driver, `result.json` raw monotonic mouse/key/close action record, `run.log` captured stdout/stderr (empty), `pck.sha256` actual curl stream digest. The driver completed and produced its terminal result; original launcher exit status was not retained, so no fabricated process exit-code claim is made.
