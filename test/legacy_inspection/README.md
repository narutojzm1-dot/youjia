# Readonly legacy divergence inspection — #149 / #150

Agent-ID: CODEX-LEAD (internal implementation agent host_budget_impl).

Two additive callback APIs accept paths_json with exactly primaryPath and backupPath, using the same actual Godot globalized paths as initialize:

- inspectLegacy(paths_json, callback)
- exportRecovery(paths_json, callback)

Both require opened ready Host/runtime/page-writer ownership. Both use a readonly new-store snapshot, never recovery or acknowledgement, then the injected reviewed readonly IDBFS reader. Old pages can continue writing their old database: this is an observation, not a lock or merged progress guarantee. New-store and old-store snapshots are separate transactions, not an atomic cross-database snapshot.

Inspection exact fields: schema=youjia.legacy-inspection/v1, namespace, current_token, baseline (sealed/none), status (same/changed/absent/unavailable), sources. sources has primary and backup, each exactly status, snapshot_status, sha256, bytes, baseline_status, baseline_sha256, baseline_bytes, reason. SHA-256 covers original bytes, not parsed JSON. Invalid UTF8 remains exportable. Per-source absent reports absent; aggregate missing one previously present source is changed, both absent is absent. No seal means baseline none: any present source is changed, never assumed merged. Any unreadable/oversized source makes the aggregate unavailable, never same.

Export exact fields: schema=youjia.recovery-export/v1, namespace, inspection, current_envelope, legacy_sources (full seal or null), legacy_snapshot (complete bounded base64 source pair). Read failures retain explicit read_error/reason instead of fabricating absent bytes. The result is incomplete when inspection is unavailable; callers must communicate that status. Oversized sources are refused by the existing reader; no truncation or unbounded rescue path is introduced. Invalid new envelope/seal/binding rejects the request, preserving both databases.

The existing source budget is unchanged. No writes, deletions or automatic merges occur. A checksum detects byte differences/corruption, not hostile same-origin re-signing. Capture can become stale immediately after return; export represents captured snapshots only.

## Actual browser verification

Build the disposable production_save_host fixture using its documented reviewed reader dependency, then copy this branch's web/save/*.mjs into export/web/web/save/. Run:

```
python test/legacy_inspection/run.py --web /absolute/export/web --out /absolute/sealed.json
python test/legacy_inspection/run.py --web /absolute/export/web --out /absolute/no-seal.json --empty
```

Each run uses real IndexedDB and a separate popup page performing subsequent old FILE_DATA transactions, read through the actual readonly reader. Ten checks cover sealed/no-seal origins, subsequent old-page writes, unchanged current/seal, exact raw export, malformed UTF8, byte fingerprints and over-capacity unavailable semantics. This slice does not wire player-facing export UI or Godot strict decoders.
