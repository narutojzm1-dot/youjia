# PR336 export4 local controlled photo transaction abort

Local export4 served at http://127.0.0.1:8140/, fresh Chromium context1280×720. Actual natural mouse title entry and sheep interaction. After first-frame and entry only, test-only IDBObjectStore.put patch aborts exactly one records/current transaction whose candidate album is nonempty. Initial blank save is untouched. No game-state injection; this is controlled actual transaction abort, not physical power failure.

records.json confirms the fault candidate contains sheep_pet_gentle. Unknown leaves current generation1 album[] and prepared intent. First actual retry-button click resolves to unchanged parent generation1 album[] with intent removed. Second actual click queues retry. Per-sample readonly IDB reads and adjacent screenshots:

| Sample | Current generation | Album | Visual evidence |
| --- | --- | --- | --- |
| 00 | 1 | empty | retry-00 |
| 01–02 | 2 | empty | retry-01 viewed: paper pending panel stays, button grey disabled |
| 03–04 | 3 | empty | retry-03/04 viewed: pending panel remains and button disabled |
| 05–09 | 4 | sheep_pet_gentle | retry-05 viewed: panel gone, saved-photo notice present |

The delay schedule includes early0/250/250/500/1000/1500ms waits (cumulative nominal3.5s at sample05), then later observations; actual readonly calls/screenshots add wall time, so these are ordered observations, not claimed frame-exact timestamps. Crucially generations2 and3 were actually observed without the photograph and the panel stayed visible. After actual close/new page/open album, generation4 and the photograph remain; reopened.png visually inspected. pageerrors=[]; exactly one injected abort. Final snapshot has no pending intent.

unknown.png viewed: new paper styling and two-line message display correctly. Evidence supports sampled pending visibility until photo persistence and no premature clearing at intermediary writes; it does not claim exhaustive per-frame coverage or physical crash safety. No production source changed by this task.
