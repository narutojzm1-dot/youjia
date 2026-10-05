# Daily Godot suite completion contract (#130)

Owner: CODEX-LEAD. This completes a narrow part of #130: detecting a test process
that exits zero without finishing its assertions. It changes no game runtime,
save format, art, or audio. The PR-only validation workflow is a separate slice.

`tools/verify_daily_life.sh` distinguishes editor import from test execution:

- Import uses the existing `run_verified_godot` process/log check. Import does not
  execute assertions and is not required to print a made-up test completion line.
- Every daily test uses `run_verified_godot_suite`. That function looks up the
  exact `.tscn` / `.gd` entry in `tools/lib/godot_suite_completions.tsv`, then
  appends that same entry to the actual Godot command. An unregistered entry
  fails before Godot starts. `res://` and project-relative keys are equivalent.
- Success requires Godot/timeout and `tee` to exit zero, no error/FAIL anywhere in
  the complete log, and the registered whole-line successful completion. A
  per-assertion PASS or another suite's PASS is insufficient. Zero check counts and nonzero or nonempty
  failure summaries cannot match the success contract. Check counts may grow,
  but where the suite reports a count it must be positive. The exploration
  slice summary also requires matching completed/total counts.
- Log scan errors and completion scan errors both block the caller. A matching
  completion followed by a later exception or FAIL still blocks.

The TSV records the suites' existing final output; tests do not print new success
markers on behalf of a failing or unfinished suite. When adding a daily suite,
register its actual successful final line and keep that line after its assertions.
When changing a suite's summary format, update its registration in the same PR.
Changing the map to broad `PASS` matching defeats this contract.

`bash test/godot_gate_test.sh` exercises the wrapper with disposable executable
processes, including empty/unrelated output, exact and wrong-suite markers,
partial completion, zero/nonzero failure summaries, process failures,
post-completion errors, `tee` failure, missing logs and completion-read failure.
It also checks that the registered script/scene is the command actually invoked
and that the caller's `errexit`, `nounset` and `pipefail` remain enabled. These
controlled tests are wrapper evidence, not gameplay or a real engine run.

Compatibility: existing import/export, movie and isolated-tool users of the
lower-level `run_verified_godot` retain their prior strict process/log behavior.
Only all daily test invocations migrate in this slice; this does not claim that
all isolated prototype scripts have acquired the daily completion contract.

Validation for the implementation candidate:

- Shell syntax and 50 controlled wrapper cases passed. In particular, licenses
  cannot pass with `checks=0 failures=0` plus its old PASS line, and each of the
  explicit-target, UI-interaction and viewport suites rejects both zero counts
  and its old counterless summary. Their existing `check()` methods now count
  calls; their assertion bodies and execution order are unchanged.
- The 71 registrations include the separately integrating soft-button suite.
  An offline comparison against the existing soft444 run's engine output blocks
  matched 68 unchanged output formats and correctly rejected the three old
  counterless formats above. This is a format audit, not a new Godot run.
- Actual Godot 4.7.2 combined daily ran on
  `819200429f94bfda60b14cec76de93d1d00381c6` with the frozen soft444 ancestor:
  exit 0, 72 engine launches (one import plus 71 registered suites), and both
  Node checks passed. The new counts were explicit-target 25, UI-interaction 63,
  viewport 135 and licenses 124. Full output and each matched completion are in
  [daily.log](godot-completion-gate-evidence/daily.log) and
  [daily-result.json](godot-completion-gate-evidence/daily-result.json).
- Web release export also exited 0; its local PCK was 27,088,652 bytes, SHA256
  `cd7b6ed95205d1cec307e704c9887be0d08d8bff080a7e413e37b5957eb9f8ed`.
  [Export output](godot-completion-gate-evidence/export.log) and
  [artifact hashes](godot-completion-gate-evidence/export-result.json) are local
  build evidence, not a public manifest/PCK check or new browser experience.
- [50-case mock output](godot-completion-gate-evidence/mock-contract-final-pre-full.log)
  is recorded separately from the real engine output. Five automatically
  rewritten import metadata files and 36 generated UIDs were restored/removed
  only in the isolated worktree; the exact diff and cleanup inventory are kept
  with the evidence. No generated resource change enters this slice.
- Independent final-SHA review remains required before this gate-only PR merges.
  The frozen soft444 source was subsequently integrated through PR451; this
  branch retains main `de4ba4227a1ce0eff5db1106a051bdf9845332a9` and its
  daily entry. [Ancestry/code comparison](godot-completion-gate-evidence/main-integration.json)
  confirms that only documentation changed since the actual full run. The
  PR-only validation workflow (PR450) is a separate change, still awaiting its
  GitHub checks/integration; this local run does not certify it. #130 remains
  open for its other tracked concerns.
