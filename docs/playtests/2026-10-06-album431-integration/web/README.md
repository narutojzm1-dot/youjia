# PR431 album candidate: ordinary Web QA

Independent QA: CODEX-LEAD / review304. Executed 2026-10-05 UTC, local candidate only; not a public release or physical-phone test.

## Identity

- URL http://127.0.0.1:8201/ ; actual HTML data-build `index`, not a production manifest.
- Export runtime: `95a3b0950f7612263e8f3939664fdd1b0906e73f`.
- Actual source checkout at every page boundary: `71b636d6b280cac3fbc783bccd2c11b207f36d23`. The complete runtime-to-HEAD diff list in `final/result.json` contains 11 documentation-only files. No checkout alteration was used to force an assertion.
- Both pages downloaded actual `index.pck` and checked SHA256 `8e64a09de7735786a50c98ed6ae7a33c297bc422358693d4c6eb762df78051da` (expected build size 27,086,076 bytes, supplied by builder; this driver records hashes, not byte counts).

## Observed result: PASS within this scope

Fresh browser context, Chromium WebGL/SwiftShader, CSS 1280×720, DPR 2. Only ordinary mouse input and viewport resizing; no business state, seed, location, time or save injection. Normal title entry and a sheep interaction naturally produced one photo. The following original screenshots were independently viewed:

- `final/desktop-album.png`: real sheep photo, day 1, caption “绵羊愿意靠近我了。” and text “你伸出手。它没有走。”
- `final/568x300-album.png`, `640x300-album.png`, `568x320-album.png`: paper/photo, complete caption/text, page 1 footer and all three buttons fit within the viewport. Back/next are correctly visually disabled for this single entry; the close button remains visible.
- `final/closed-small.png` and `reopened-small.png`: actual normal close and reopen at 568×320. The former is the yard HUD, the latter the same readable photo.
- `final/restored-desktop.png`: desktop layout restored with the same readable content.
- `final/real-reopened-album.png`: actual page.close followed by a new page in the same context, normal title entry and album button; the original photo and text remain readable. This is visual persistence evidence, not database byte comparison or whole-browser restart.

Two real page loads, four source boundary checks, two actual PCK hash checks. `final/run.exit` is 0 and recorded console/page errors are empty. Input and screenshot monotonic timestamps, navigation, console, actual checkout and docs-only deltas remain in `final/result.json`. PNGs are original Playwright CSS-scale captures, not edited images.

## Preserved failure and limits

Initial preflight incorrectly required checkout HEAD to equal export runtime although the author had appended docs. It stopped before any game UI ran. Top-level `result.json`, `pre-metadata-failure.log` and `pre-metadata-driver.py` preserve that excluded failure. `run.py` corrects only source metadata validation; `final/` is the first completed UI run, not a rerun of a failed game flow.

Only one Chinese photo was naturally obtained. No previous/next page navigation, all long titles, English variants, touch, physical phone, audio or full persistence matrix was tested. Native broad layout tests belong to their separate implementation evidence. The inherited driver contains unused media/card-detector helpers and generic limits; no media emulation or detector was used in this album flow (`media` is empty).

Incidental existing #400 observation: after viewport restoration the background left paper edge is around x213 rather than initial x95; a fresh page returns it to around x95. Album panel and content remain intact. No cause is inferred and this QA does not claim to fix camera/background behavior.
