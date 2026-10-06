# PR462 merged main publication — independent read-only acceptance

**PASS for main Actions / exact gh-pages / exact Pages deployment chain.** Source **b300da74bf157de3f152e63331096cb1eb28b3f7**, source tree **81e6ba37a366d4ca63c249fbf92354dcf0252858**, remains the independently approved PR462 tree. This is engineering release-chain acceptance, **not this reviewer's public HTTP package download or ordinary browser experience**. Root performs the final actual public manifest/PCK/module/license download independently.

Reviewer: relationship45_qa. I did not implement this change, run Godot/browser, alter remote branches, dispatch or retry a workflow. I followed the original automatic main push and its exact resulting Pages run using cache-busted API reads and the complete original log ZIPs.

## Actual full-history sparse checkout

Main run **37387842699**, attempt1, job **112025570299**, source **b300da74bf157de3f152e63331096cb1eb28b3f7**, completed **success 2026-10-05T23:27:31Z**. Every step actually succeeded. Actual action source is `actions/checkout@v4` commit **11d5960a326750d5838078e36cf38b85af677262**. Its logged input is `fetch-depth: 0`, non-cone `/*` / `!/docs/`; its actual initial fetch command is:

```text
[command]/usr/bin/git -c protocol.version=2 fetch --prune --no-recurse-submodules --filter=blob:none origin +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/*
```

There is no depth argument in this main fetch, and heads/tags use the full refspec. Actual source checkout finished **2026-10-05T23:19:51Z–2026-10-05T23:20:00Z (9 seconds)**. Previous source9623's checkout was350 seconds. These are separate measured observations, not a controlled speed comparison or causal performance guarantee.

The unchanged publisher later fetched gh-pages and added the linked worktree at **16944e4fa02d280f8ff150b89e62ba76d1ec9f1c**. It actually pruned exactlyone oldest bundle from5 staged candidates, then committed/pushed. The unchanged helper returnswithoutpruning when shared-shallow=true, so this actual successful5→4 pruning rules out that failure path. The production logs do **not** print a standalone `is-shallow-repository` boolean or a follow-fetch promisor config dump; I do not manufacture those observations. Retained partialclone config/sharedsparse mechanics are additionally supported by the independent exact-script six-mode Git fixtures already reviewed for PR462.

## Real validation and publish

- Actual **74Godot starts =1import +73suites**; each sequential suite chunk independently matches the final committed positive completion contract. Includes disabled4400 and photoarrivalmat550. No engine error/fail lines found in actual daily/export/publish stages.
- Existing controlled gate50, two Node checks, Pythonretention11 and the original real publisher fixture pass. Controlled fakes and actual engine suites remain distinct.
- Real Godot4.7.2 Web export succeeds; original publisher verifies HTML mapping, stages artifacts/modules, creates actual gh-pages commit and logs successful push. This main workflow does not contain the PR workflow's extra `test -s` loop; actual published Git entries below separately prove nonempty JS/WASM/PCK/HTML.
- Entry **game-b300da7**, git release manifest `sourceCommit=b300da74bf157de3f152e63331096cb1eb28b3f7`, publishedAt **2026-10-05T23:27:14Z**. Manifest schema is youjia.release/v1 and does not contain a PCK SHA256 field.

Published gh-pages commit **e6d192eab33cc67e32f76656cdc24eb222b2a869**, tree **3760584ab1adfe40c17afa15ba7637531ebbedbc**. Independently walked five exact first-parent publish commits and decoded each manifest: b300→9623→870→a0bb→d788. Actual root retains **game-b300da7, game-9623ba2, game-870f4fa, game-a0bb75e** and removes **game-d788f48** plus its companions. Existing retained bundles remain byte-identical by Git blob; indexJS/WASM/PCK aliases equal their new named blobs; indexHTML executable/script/modulepath/filesizes all bind b300. All prior versioned save directories remain unchanged, and all10current module Git blobs plus manifest SHA256 values match the reviewed source.

Published Git PCK: **27,089,276 bytes**, Git blobSHA1 **9659cb9321946770ff12c563d9be8baae70c6a98**. License: **147,966 bytes**, blobSHA1 **ad9ed8e77c0c50dd7dd3b1f24ba2b7417a66f601**. These Git-object checks are not public HTTP download SHA256 checks. Parent performs those next. Real old Pages has no rootdocs entry: hidden old Pages docs preservation and unknown-history fallback are covered by the explicit Git fixtures, not claimed as cases encountered on this production branch.

## Exact Pages chain

Pages run **37388592826**, source **e6d192eab33cc67e32f76656cdc24eb222b2a869**, all3jobs success:

- build112027994247
- deploy112028138007
- report-build-status112028138070

Complete build log checks out the exact gh-pages SHA; deploy log `pages_build_version` is the sameSHA, artifact **11379883536**, and contains:

```text
2026-10-05T23:29:44.2198450Z Reported success!
```

Run final update **2026-10-05T23:29:47Z**. This is a successful exact deploy, not just queued dispatch or artifact upload. No other source build was substituted.

## Retained evidence and remaining handoff

- Main fullZIP: **97,487B**, SHA256 **37bf8d8564bfdf9883c4e8171daf91952296b0ab5193516ed161bcea42dc9035**.
- Pages fullZIP: **30,638B**, SHA256 **58f42ea6f068951411626b42f30950a2990a12a72af68e27cac5258f4fff5d2e**.
- Safe summary: [safe-summary.json](safe-summary.json).
- Actual fullfetch/retention analysis: `actual-checkout-retention-analysis.json`; ordered suite markers: `actual-main-suite-completions.json`; exact published inventory/source bindings: `published-tree-analysis.json`. Raw API JSON, release manifest, indexHTML and bothlogZIPs remain in the same directory. Report and summary contain no signed download URLs or authorization headers.

**Main/Pages acceptance PASS; final public HTTP package verification remains with root.** No new gameplay, production unknown-history event, real hidden-docs case, ordinary UI experience, subjective quality claim or long-term performance guarantee is inferred from this internal workflow change. #130 long-term issue is not closed by this scoped result.

Final verification UTC: 2026-10-05T23:31:34.490130+00:00
