# PR427 shared-contract read-only review

Scope: Draft head `a69979b5c7148034d1598ea00ba6de2c413aa5d0`. No Cloud branch/source modified. Isolated diagnostics in `/dev/shm/pr427-review`; nine relevant Host/Director/Main/Store/Coordinator/Native/Codec/Session/fixture files verified byte-identical against exact Git objects in `/tmp/pr427-source-verification.json`. This is parallel compatibility feedback, not an added Leader approval stage.

## Blocking finding: INVALID_ARGUMENT fallback removes unknown preserved fields

Location `scripts/exploration/exploration_host.gd:301-305`.

The fallback `store.request_exploration_record(request.target)` bypasses the cleanup interface after its deliberate fail-closed rejection. `INVALID_ARGUMENT` includes future/unknown structured extensions, not merely harmless unsupported fixtures. `_cleanup_still_ours` at 313-316 only checks that the same authoritative extended record is still present now; that equality does not authorize deleting its unknown content. It also is not a queue-head CAS: ordinary `request_exploration_record` freezes target, then unconditionally replaces `current.exploration` when executed (SaveStore:231-237).

Actual reachable case, not hypothetical format:
1. Create normal formal near-path trip1, request return, leave `pending_commit` record in save with committed watermark1 (ordinary grant-confirmed/pre-cleanup boundary).
2. Add `session.started_clock.future_payload={keep:raw}` to authoritative current. Session's existing structural validator accepts this child extension; Codec.project retains full exploration (`save_data_codec.gd:58-60`).
3. `ExplorationSession.restore` validates, loads session and sees serial<=watermark, returns `HOST_CLOSE` (`exploration_session.gd:89-105`). PR427 Host closes and invokes cleanup.
4. #391 correctly rejects op1 as `EXPLORATION_CLEANUP_INVALID_ARGUMENT` before prepare. PR427 then enqueues unrestricted fallback op2, which confirms idle/session:null and drops the extension.

Both diagnostic paths reproduce:
- Existing real SaveStore API + PR427 MemoryStore queue: `/tmp/pr427_probe.gd`, `/tmp/pr427-probe-final.log`.
- Real SaveStore + real Coordinator + real NativeHost and actual file write/readback: `/tmp/pr427_native_probe.gd`, `/tmp/pr427-native-final.log`. Output: `COORDINATOR true`, `RESTORE close`, op1 cleanup INVALID_ARGUMENT, op2 exploration confirmed, `BACKEND_CALLS 3`, `FILE_IDENTICAL false`, `RAW_AFTER ... session:null`, `PRESERVED false`. Godot4.7.2, process exit0, clean final log without SCRIPT ERROR. Three calls are actual prepare/submit/ack; this is not a fake successful Host.

Native reproduction writes only an isolated diagnostic player profile in `/dev/shm/pr427-native-state`. Native legacy source sealing may keep an original sidecar, but the authoritative current is overwritten and does not meet #391's explicit zero-prepare/current-byte-preservation contract. This is not a claim that all historical recovery behavior regressed: the fallback explicitly preserves older direct-write behavior; that behavior still cannot satisfy the newly adopted #391 guard.

Minimum recommendation to Cloud: treat INVALID_ARGUMENT as a non-retriable preserved/unsupported state for this new cleanup path, with no fallback ordinary write; retain current data and visible failure. If a separate known legacy reset needs support, define/prove its exact permitted shape independently, without swallowing unknowns or bypassing queue-head CAS. Add full Host.restore→Store→Coordinator→Native regression for nested clock/proposal/item/failure extensions, not only direct cleanup API tests. No fix applied by reviewer.

## Main failure/ack ordering read-through

No additional concrete ordering defect established in this review. Main connects Store rejected before creating/attaching the exploration Host (`main.gd:232-235`); Coordinator terminal reject emits ready then rejected and schedules next pump (`save_coordinator.gd:262-268`). Thus in the current normal attach order Main records the rejection revision before Host emits cleanup_resubmitted. New handler captures exact failure dictionaries; confirmed calls `_clear_covered_save_problems` using equality, not arbitrary null, and panel closure remains ready+idle with other problems/untracked photos considered. Subsequent ack failure is a new problem even when kind is empty; it is not hidden solely because old cleanup coverage cleared. These are source-based observations, not new full Main fault tests or Web/IDB coverage. The confirmed fallback could hide the correctly rejected old cleanup issue after destroying unknown fields; that is the concrete finding above, not a second speculative UI finding.

## Reproduction hashes and limitations

- native script SHA256 `7110b939c7e065d29b8bf0efcaee675bb1c2873a846afab151e90e5e00b252ff`
- memory script SHA256 `de45f7d5189303e8aefd8fe0b0bb3f93655d92b4d707c5607902416f5389a4b9`
- clean native log SHA256 `427097dda0d31d047bd14c0739ca3b2bfd666c07d33c1db36ebc1cd9a086e686`
- clean memory log SHA256 `a6b6ec87ee382a0f5399c3cb49efbe7d48477eecc42546a92964dff2ffeaa93f`

Early local diagnostic setup had a Variant-inference warning and missing shader symlink; fixed only isolated harness/environment, rerun clean. `/tmp/pr427-probe.log` is excluded setup output, not final evidence. No full daily, live Web, or all recovery cases claimed. No remote comments/changes or self-approval performed.
