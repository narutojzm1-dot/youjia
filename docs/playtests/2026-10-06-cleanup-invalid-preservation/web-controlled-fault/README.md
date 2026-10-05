# Cloud427 + Leader cleanup-preservation candidate: controlled Web storage failure

Independent QA review304, 2026-10-05 UTC. Local candidate, **controlled IndexedDB failure**, not ordinary production failure, physical power loss or public release. Browser ended normally (exit0).

## Candidate identity

http://127.0.0.1:8202/ ; runtime `47bb594006b4236d88e145969c2f5d1ca4118405`, actual HTML `game-47bb594`. Both pages download actual PCK 27,088,028 bytes, SHA256 `0833fcc888dcf15a74d1ca600fe9ce8c0fb44c01d9cd45723f8faad95e187543`. Four git boundary checks retain actual HEAD/docs-only delta in result.json. Separate first/last local stamped manifests match full runtime; these are candidate metadata, not a public deployment.

## Fault boundary and ordinary actions

Fresh Chromium context1280×720/DPR2, ordinary mouse title→yard path→gate stop, E observation and T take; naturally offered one feather. Ordinary return button. No business state/seed/location/time/save injection.

The sole fault wraps the real IDBObjectStore.put and throws one UnknownError DOMException ONLY at key intent/state prepared when parent already has nonempty keepsakes, positive awarded serial and session, candidate clears session, and serial/keepsakes stay equal. All other puts call the original implementation. Host prepare/submit/resolve/ack calls/replies are transparently recorded without rewriting arguments or replies. New page explicitly disables the fault. Raw audit records contain the exact envelopes, request/write IDs, actual writes, transaction events and receipt wires. Read-only DB snapshots are technical evidence, not a player-facing UI substitute.

## Observed limited PASS

- 01-offer and02-taken original UI: natural feather, basket feather.
- write5/request `7be63c25bf664c91989f04f26aa965c2` confirmed awarded feather1 and ack cleared.
- cleanup write6/request `25063a908f964c5bbf446eb797a70682` hit the sole precise fault; submit returned WRITE_UNKNOWN_RESOLVE_REQUIRED; resolve returned rejected with trusted parent and terminated old write. 04-settled-fault/05-pre-retry show the real “保存暂时无法继续 / 再确认一次” panel. Current generation6 retains feather1 and the awarded pending session.
- Exactly one ordinary click on “再确认一次”. Bounded replacement write7/request `edfd5122c71142f999033b49a52f1058` confirmed and acknowledge cleared. 06-after-one-retry original screenshot shows the same-page failure panel gone. Current generation7 has session:null, feather1; no duplicate award.
- Real page.close followed by new page in the same context, explicitly fault-disabled, normal title entry. 07-real-reopen shows yard without failure panel. Read-only current envelope is exactly equal to06; generation7, feather1, session:null. New-page audit faults0, first-page faults1.

Initial03-after-fault is deliberately preserved: at that early sampling instant the ordinary earlier write4 had not finished acknowledging, so cleanup had not yet been attempted and faults0. It is not counted as a fault test failure or successful recovery. The later04/05 show actual injected failure. No screenshot or earlier evidence was overwritten.

All7PNG originals retained. errors=[] and exit0. comparison.json includes complete decoded receipts and exact current-envelope comparison. This test proves only this precise single cleanup failure/replacement path. It does not prove INVALID preservation, which is covered by separate Native51 tests, nor every retry race, multiple items, Cloud427 ordinary QA, physical phone, browser-process restart or durability under power loss. Generic unused media/card helpers in driver were not called. No production/runtime code was changed by QA.
