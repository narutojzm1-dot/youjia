# #399 ordinary public carried-items touch-gate return

Independent QA: review304. 2026-10-05 UTC. One bounded natural trip; no second trip, seed/state/location/time/save injection or controlled failure. Chromium browser-emulated touch at CSS 1280×720 / DPR2, not a physical touchscreen phone. Movement, title/outside/gate use real touchscreen.tap; observations and taking use ordinary E/T keyboard bindings, so this is mixed ordinary input, not an all-touch collection claim.

## Exact public build

URL https://narutojzm1-dot.github.io/youjia/ ; full source `96f090a63e0997244924a7463bd0e52a025b57b1`, actual HTML entry `game-96f090a`. Both real pages check full game-release.json before/after (4 checks), plus downloaded actual PCK SHA256 `8b5c85763a480a9f7a6e40196ccd0a5b04b645be2a79391c0c1b63eca04c6aa0` (2 checks). Root-supplied release size 27,085,436 bytes; this driver records hash, not count. `result.json` retains actual manifests, actions and monotonic timestamps, entry, navigation, console and errors.

## Observed result — limited PASS

Normal title entry → touch the yard path → natural near-path exploration. Three ordinary stops with 12 seconds walking allowance and E/T input yielded pine cone at shade, round stone at brook, round stone at slope. Original `shade-take.png`, `brook-take.png`, `slope-take.png` visually show basket contents progressing to “松果、圆石×2”: **three pieces, two kinds**, not the three distinct collectible types. No attempt to force a feather.

From the slope, actual touchscreen.tap(1060,390) targeted the courtyard gate and the game was allowed 28 real seconds for ordinary walking. `touch-return.png` was visually inspected and shows the actual yard and “回到院里了。松果、圆石×2都收好了。” It is not the initial-arrival notice mislabelled as a return.

Then real page.close, new page in the same browser context, and ordinary title entry. `reopened-yard.png` proves reopening into the yard; it does **not** display an inventory count. Item persistence is separately supported by allowed **read-only IndexedDB** evidence: after-return and reopened `records/current` envelopes are exactly equal, generation 12, keepsakes `formal.find.pine_cone:1`, `formal.find.brook_stone:2`, exploration session null and committed serial 1. No duplicate award. DB observation only; no DB writes or gameplay setters were used.

`before-return-db.json` is an asynchronous intermediate snapshot, generation 8 with two items, sampled shortly after the third take and before its commit became visible. It is preserved and must not be cited as final basket state. The subsequent original UI screenshot shows three pieces; after-return committed intent parent also retains all three carried items. After-return contains a committed intent; current-envelope equality after reopen is the stated assertion, **not equality of every object store or proof of ack timing**.

`run.exit` is 0, errors=[]; two ordinary page navigations only. All PNGs are original CSS-scale browser screenshots. Source unchanged throughout. No full browser restart, physical device, all collectible kinds, all item quantities/routes, failures, storage durability, Cloud427 fault matrix, or whole #399 closure is claimed. The generic unused media/detector helpers in the reused driver were not executed; media list is empty.
