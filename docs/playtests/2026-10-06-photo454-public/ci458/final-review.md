# PR458 sparse checkout independent review — code and local evidence

Reviewer: CODEX-LEAD independent sub-agent `leader_scope_audit`; no implementation, Godot, browser or repository mutation performed by this reviewer.

PR: https://github.com/narutojzm1-dot/youjia/pull/458
Reviewed remote head: `a8c4bd5fa377cbd5890249d392ec7c7cb74660b5`
API tree: `dea408fa33dfd66e3ea46f11ca1d3487dda96b07`
Identical local head/tree: `1eb5696eb4a3093512ef39434b285fffeed34b62` / `dea408fa33dfd66e3ea46f11ca1d3487dda96b07`
Actual local runtime validation: `1596cd1f05df3744045f19d929eabb906bdddaba` / tree `107463b049c86df7069aed3d3127b6b7725900cd`.

## Verdict

APPROVE the code and local validation evidence at the exact reviewed head. This is **not an overall merge approval**: final proposed-merge CI success and unchanged head still required. During this review GitHub returned `mergeable=false`, `mergeable_state=dirty`, `merge_commit_sha=null`; root has been informed and must resolve/rebind any resulting head and tree. An earlier head or CI cannot satisfy the new final-head gate.

Initial blocker found and corrected before this verdict: narrative PCK SHA was truncated although JSON and actual binary hashes were correct. The correction changes only that documentation literal; final narrative now contains the exact 64-character actual hash.

## Scope and dependency findings

- Base-to-final only non-docs change is the four checkout input lines in `.github/workflows/verify-pr.yml`. All 913 non-docs Git entries remain; actual tested source and final non-docs trees are identical. No changes to scripts, tests, assets, export configuration or publisher.
- Non-cone `/*` followed by `!/docs/` excludes only root docs. Hidden files, nested `test/docs`, full art, source, tests, tools, web, site and four root metadata files remain included. No ref override, fetch-depth override, permission escalation, credential persistence or removal of verification/export steps.
- Independently read checkout v4 implementation at `11d5960a326750d5838078e36cf38b85af677262`: sparse input selects `blob:none` when explicit filter is absent; non-cone patterns are written before checkout. This verifies the implementation semantics inspected, not measured GitHub bytes/speed.
- Independently scanned retained executable/config text for docs references: only workflow/exclusion entries, source comments, historical provenance/site manifest and one capture-tool comment were found. No current executable docs dependency identified. `export_presets.cfg` already excludes root docs. Actual production art fixture remains available.
- Reviewer reran the exact three sparse/partial Git cases and seven retention cases in disposable local file:// repositories, copying the immutable helper. All passed and generated results equal frozen JSON. No repo files were touched. This distinguishes sparse working tree plus partial transport from either alone, and preserves full-history publisher behavior.
- Actual source preparation intentionally excluded docs for validation; archived before/after checks and preparation failure/recovery remain explicit. Docs later added for evidence do not alter the tested non-docs inputs. This is not a guarantee for future docs-based fixtures; future dependency additions must reassess this checkout rule.

## Evidence independently verified

- All 16 archived files with corresponding raw evidence copies are byte-identical; no mismatches.
- 78 recorded direct processes all return 0: 73 daily Godot launches (import plus 72 suites), two Node, two publisher-fixture Godot version processes, one real Web export.
- Independently split the raw daily log into 73 actual Godot banners and paired process entries with the frozen completion map: 72 distinct suites match their exact completion expressions. Photo mat has 550 checks, soft-button suite remains included; 50 gate contract cases present.
- Python raw retention log reports 11 tests and OK. Publisher fixture reports two real local-bare-remote builds and module-byte/SHA validation. All four validation phases return 0. Daily and both export logs contain no error/warning/failure/resource-load diagnostics in review scanning.
- Independently rehashed all nine actual exported files, each matching `validation.json`. The local export harness does not set errexit; this limitation is explicitly disclosed, and the direct actual engine exit record, strict helper, output hashes and raw diagnostics were examined instead of trusting only the last shell command.
- Reran read-only PCK comparison against the actual preserved full-metadata PR454 baseline and actual sparse candidate. Output equals archived comparison JSON; all member MD5s validate. Both have 398 members; no added or missing names; 394 member payloads identical. UID cache has the same 176 path-to-UID mappings with changed order. Three compiled scenes each have one 4-byte difference; its precise engine-field cause is not proven, and the report correctly avoids semantic/byte-identity overclaim.
- Actual candidate PCK: 27,089,100 bytes; SHA256 `89b6593e8e05951fc24f139dc01092b3281bc59cd5dcf8616caef5dc198d00e8`. Baseline `faa935055fb62250c137625da28e15d2ac28ef3880db1e8993e5991afec84df6`.

## Remaining gate and limits

Require actual GitHub CI on the final proposed merge, binding checkout action version, `--filter=blob:none`, `--depth=1`, final head/base parents and complete daily/Python/Web steps. Verify no workflow change in any conflict-resolution commit; docs-only resolutions still require exact new head/tree binding. This is an internal verification-input optimization; no new browser, playable feature, Pages release, network-byte reduction or speed improvement has been established by local fixtures. #130 remains open for its other scope.

## Final source integration rebind

Reviewed remote head `6862b4c65b6c037fa2319a38ed12f7f0238168b7`, API tree `895be87dd881f1662d6b2b78c7c4b41e7883ebfa`, exactly equal local `5131237878a7cf55bfc5972c17d3f05ebba7c909`. Remote parents exactly preserve old candidate `a8c4bd5fa377cbd5890249d392ec7c7cb74660b5` and current main `87076010555fc7283b97b583eff60a5fd8a9fccb`.

Independent Git object comparison verifies unchanged non-docs tree from the previously reviewed/tested candidate; all unrelated PM main paths and candidate evidence paths retain exact blobs. Requirements retains current main rows plus the exact candidate requirement; decisions retains main section and candidate append. Clean worktree. The four-line runtime-input workflow patch remains the sole non-docs change. **Code/local evidence APPROVE transfers to this exact head; overall merge remains pending actual new CI.** New actual CI run is `37382704512` (event pull_request, head `6862b4c...`); old-head runs excluded. Initial current API reports mergeable true and proposed merge `5c236828ea23fd376a036dc2e83f92d4234b7780`.

## Final actual-CI gate and overall verdict: APPROVE

**APPROVE PR458 at exact final remote head `6862b4c65b6c037fa2319a38ed12f7f0238168b7`, tree `895be87dd881f1662d6b2b78c7c4b41e7883ebfa`.** Earlier pending/dirty notes above record superseded observations; the final source integration and actual new CI have now both been verified. Root may merge only with a fresh compare-and-swap against this exact unchanged head.

Actual final-head run [37382704512](https://github.com/narutojzm1-dot/youjia/actions/runs/37382704512), job `112008583888`, completed success at 2026-10-05 22:35:13 UTC. All actual steps succeeded. The downloaded complete original log ZIP is 78,624 bytes, SHA256 `0f915e46a2daa4b80f393d104590b3c9c524c69d59032f22d572466e399a1ddc`; the safe CI summary and exact suite-by-suite mapping are archived beside this review, with the original GitHub run linked above. No signed redirect URLs or response headers were printed or retained as review evidence.

Actual checkout log confirms checkout action `11d5960a326750d5838078e36cf38b85af677262`, `--filter=blob:none`, `--depth=1`, non-cone root docs exclusion, no credential persistence, and proposed merge `5c236828ea23fd376a036dc2e83f92d4234b7780`. API binds that exact merge to parents `87076010555fc7283b97b583eff60a5fd8a9fccb` and final head `6862b4c...`, with the same reviewed tree `895be87...`. Checkout step was 22:29:11–22:29:16 (five seconds); this single observed run is not a universal speed or network-byte guarantee.

Independently verified raw final-CI log has 73 actual Godot launches, import plus 72 suites, all 72 exact completion patterns matched their own ordered run segments; photo mat550 and button5080 included; 50 mock gate cases; both Node completion lines (Loading shell PASS and MOTION PREFERENCE JS PASS21); retention11 and real publisher fixture two-build checks. Real Web export ran under Bash errexit and checked four nonempty required outputs. No error/warning/resource-load failure diagnostics found in daily/export logs. CI exported PCK bytes are not a published/downloaded artifact here, so no CI PCK hash or Pages release claim is made.

Fresh API before this final approval confirms unchanged final head, mergeable true, and completed success `verify-export` check on that head. This resolves the code/local/actual-CI review gates for this narrowly scoped checkout optimization. No local engine or browser was started by the reviewer. Main/Pages post-merge verification remains the publisher owner's next step; #130 parent scope is not thereby closed.
