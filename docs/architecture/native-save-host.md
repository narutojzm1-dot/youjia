# Native file Host candidate (#150)

CODEX-LEAD delegated native-only adapter. Not installed in production SaveStore/Main. Constructor `(primary, temporary, backup, files=null)` defaults to existing user paths; optional file object is for real file fault testing. `request(method,args,expected)` returns call ID immediately and emits deferred `completed(call_id,method,{status,code,wire})`. `open` emits six-field `youjia.host-open/v1`; getters expose initial projected snapshot, raw-bound token and ready/blocked state. Root must only initialize writing coordination after ready.

Prepared/receipt/ack use the coordinator's existing 9/14/5 field protocol and explicit `youjia-native-file-v1` namespace. Payload hash binds the supplied JSON text; candidate token binds actual `SaveFiles.commit` pretty JSON text. Parent token binds recovered original bytes, never a projection. Two absent files use explicit missing sentinel SHA256 and defaults without writing. Store ID stays random and stable for this adapter session; generation is a decimal string. Identical writes may legitimately have equal parent/candidate raw hashes; request/write identities still differ.

Unsupported-version/schema or unreadable sources block writing. When one source is valid and the other has malformed JSON/UTF8, the latter can be repaired only after its exact complete bytes are permanently sealed; later new corruption that differs from existing sealed evidence stays blocked. Existing integer versions 1 through 5 are accepted; new candidates remain version 5. Fractions and future versions block. No automatic repair or reset.

Prepare freezes data; submit executes SaveFiles.commit at most once. Failed or uncertain result remains unknown, refusing the next write. Resolve reads actual files: verified candidate confirms; verified original parent with synchronous write terminated rejects; unrelated/corrupt evidence stays unknown. Acknowledgement rechecks actual current and cannot undo prior confirmation. External changes before prepare or submit block rather than overwrite. Native synchronous file completion/readback is NOT an OS crash/fsync guarantee or interprocess exclusive lock.

Run isolated `test/native_save_host_suite.gd` with Godot4.7.2 and disposable XDG directories. Covers real writes, raw/pretty identity, deferred callbacks, repeat submit, failing file adapter, parent recovery, external modification, failed ack and corrupt/future source preservation. Existing SaveFiles and synchronous setters remain unchanged. Production queue/UI integration remains a separate reviewed slice.


## Existing native saves: preservation-first compatibility

Before accepting an existing v1–v5 source for writing, the adapter creates `<primary>.legacy-sources.json` once. It records explicit primary/backup absent/present states and original **bytes** as base64 (including whitespace, unknown fields and large-number lexemes), with a SHA256 over the serialized source pair. A temporary side file is flushed and read back, then renamed and validated. Existing sidecars are never overwritten. Any creation/validation failure blocks writes and leaves source files intact; it does not silently fall back to rolling `.bak` retention.

Migrated native candidates carry reserved `_youjia_native_legacy_sha256`, binding subsequent current files to that immutable source pair. Missing/malformed/mismatched evidence blocks on reload, prepare, submit and ack; it is never re-created from migrated data. Pre-migration files without a binding must still exactly match their sealed source pair. This reserved key cannot be used as an unrelated user extension. Checksums detect corruption, not hostile re-signing. Same-process source inspection is not interprocess locking; OS-level directory fsync/power-loss guarantees remain unclaimed.

Initial snapshot keeps unknown dictionary fields and overlays Codec's known business projection/version 5. The open payload and parent token continue to refer to actual original text, not that projection. Only the backend's persisted candidate includes the binding; `payload_sha256` still identifies the coordinator's submitted payload, while `candidate_token` identifies the real pretty-printed file. Invalid UTF8 round-trips are refused for writing, while captured valid sources are kept byte-for-byte.

Regression: native **119 checks**, including versions 1–5, both-source byte preservation through two commit/ack/reopen cycles per version, missing permanent evidence, fractional/future versions and a real sidecar filesystem conflict. Existing SaveFiles recovery **24 checks** also passes. No production files or setter implementation changed in this increment.

## Idle-only synchronous compatibility entry

`commit_compat(candidate)` is available solely when the same native Host is ready with no active operation. The caller must keep its coordinator idle/detached; queued or unknown writes must not be replaced. It reuses `_prepare → _submit`, resolves an uncertain synchronous result by reading actual files (never resubmits), and acknowledges verified confirmation. It returns `{status, code, snapshot, token, ready}`. Confirmation returns the full backend snapshot including the source binding; ack failure retains confirmation but leaves ready false. Rejection requires actual trusted parent readback after termination. Source changes/corruption/missing evidence remain unknown/blocked and cannot bypass preservation via legacy synchronous APIs.

Regression now **133 checks**: includes v3→async→sync compatibility→async→restart, unchanged permanent evidence, returned binding/raw token, denial during prepared async work, corrupt/missing evidence non-overwrite, and a real temporary-path failure proved rejected only by recovery. The adapter itself does not detach/recreate coordinators or alter SaveStore; integration owns that idle transition.

## Orphaned source evidence

Both live save paths being absent is insufficient for new-player defaults when `<primary>.legacy-sources.json` or its `.tmp` residue remains. A valid/corrupt sidecar, a directory occupying either evidence path, or an incomplete sidecar blocks without returning a default snapshot/token or creating a new save. Evidence remains untouched for explicit recovery. A valid bound backup with primary absent still recovers its real raw token and keeps the source binding through a guarded commit.

Native suite: **161 checks**, including versions 1–5 sealed then live-file removal, corrupt/directory/temporary sidecar residues, compatibility-write rejection, and primary-missing bound-backup recovery. Existing recovery: **24 checks**.


## Preserved recovery from an unusable copy

For first-time malformed JSON/UTF8 plus a valid v1–v5 copy, the adapter captures complete bytes of both files, seals them, and recovers the valid copy. Immediately before commit it removes only unusable copies whose exact bytes match their permanent evidence; the independent valid copy stays available. This prevents SaveFiles parsing malformed UTF8 or overwriting the only good source. Sidecar errors, short reads, unreadable files, directories, valid JSON with missing/future/fractional version and two corrupt copies remain blocked. Existing evidence is never replaced to absorb later corruption.

Native regression **181 checks** now includes malformed JSON and invalid UTF8 in either primary or backup: original bytes sealed, successful save, restart with day/fish progress, and unchanged evidence. Existing SaveFiles suite **24 checks** passes unchanged in this branch. Full-game test fixtures must isolate/restore new evidence paths alongside primary/temp/backup; retaining an unrelated previous fixture's seal must correctly block, not silently overwrite it. OS-level external writers and power-loss durability remain outside this candidate's guarantee.

## Failed write after preserved-corruption cleanup

After a sealed corrupt copy is removed, a failed temporary-file write or promotion must still recover the exact valid original parent. For a seal containing exactly one valid and one malformed source, the guard now also accepts exactly one live copy whose bytes equal that valid original, with the other path absent. The kept copy may be in backup because SaveFiles rotates primary before promotion. It never accepts replacement bytes, two missing sources, removal of the sole valid source, or new corruption. Permanent evidence is unchanged.

Native **200 checks**: both damaged-primary and damaged-backup directions across real temporary-path failures and actual SaveFiles rotation with injected promotion failure, trusted-parent rejection, restart, successful new write after removing the obstruction, unchanged sidecar, and a substituted-good-source negative case. Failed writes are resolved, never resubmitted under the old request.
