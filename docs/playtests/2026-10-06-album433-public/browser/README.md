# PR433 official public album QA

Independent ordinary Web QA by review304, 2026-10-05 UTC. This is the actual public release, separate from PR431 local candidate evidence.

## Build identity

- URL https://narutojzm1-dot.github.io/youjia/
- Full source: `c6e5c9b8b1764f8c41eb492b56b4d11da7f1386b`.
- Actual HTML entry: `game-c6e5c9b` on both pages.
- Actual downloaded PCK on both pages: 27,086,076 bytes, SHA256 `f80ba8f58617ca6d4e91ce86deb80416f71f09286d7e2faaca99c48ae6d340c3`.
- Four complete manifest checks, before/after each page, all match the full source. Raw manifests and PCK checks retained in `result.json`. No candidate hash or old public source is substituted.

## Observed PASS within scope

Fresh Chromium context, CSS1280×720/DPR2, headless WebGL/SwiftShader. Normal mouse title entry, natural sheep interaction and ordinary album button produced one readable photo (“绵羊愿意靠近我了。” / “你伸出手。它没有走。”). No state, seed, save, time or location injection. No DB access.

Original PNGs independently viewed:

- `desktop-album.png`: original single sheep photo and text.
- `568x300-album.png`, `640x300-album.png`, `568x320-album.png`: actual viewport resizes; paper/photo, complete caption and text, page 1 footer and all three buttons fit onscreen. Paging buttons are visibly disabled for the single entry; close remains visible.
- `closed-small.png`: normal close gives the yard HUD. `reopened-small.png`: normal album button restores the same readable photo at 568×320.
- `restored-desktop.png`: restoring1280×720 returns to the readable desktop layout.
- `real-reopened-album.png`: real page.close followed by new page in the same browser context, normal title entry and album button; original photo and text remain readable. This is visual same-photo persistence evidence, not DB byte equality or a full browser/profile restart.

Driver exit0, recorded console/page errors empty. The raw input/screenshot monotonic timeline, two navigations, console, manifests and download checks remain in `result.json`. All eight PNGs are unedited original Playwright CSS-scale screenshots; actual context DPR2 is retained in driver.

## Limits

Only one naturally obtained Chinese photo. No next/previous page navigation, multiple photos, all long captions/English, touch, physical phone, audio or complete save matrix is claimed. No extra interaction loop was used merely to force a second photo. Broad native layout tests and earlier local candidate checks remain separate. No failure occurred in this public run; the old candidate metadata preflight failure belongs to the separate candidate archive. Unused generic media/card-detector helper functions remain in the reused driver but were not called (`media` is empty); this is not a reduced-motion retest.
