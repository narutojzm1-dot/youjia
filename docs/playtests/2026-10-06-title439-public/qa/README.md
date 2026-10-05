# PR439 official title declaration-link four-viewport QA

Independent review304, 2026-10-05 UTC. Ordinary public browser input, not candidate/native rendering evidence. Chromium WebGL/SwiftShader, fresh profile, DPR2. One actual game page sequentially resized through CSS1280×720,568×320,640×300,390×844; no gameplay start, state/save/seed injection or Godot setter.

## Exact build

https://narutojzm1-dot.github.io/youjia/?qa=<timestamp> avoids old root HTML cache. Full source089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21; actual HTMLgame-089d453. Before/after full game-release.json match this source. Before/after actual versioned PCK downloads both27,088,396 bytes SHA256fb7b1473608a999f76eb46a8fd18b7f6fa2e8456f0508ee0db0693b2cddba1f8. Those are explicit HTTP download checks, not interception claims about the engine's fetch. No other game page is claimed.

## Actual ordinary-input matrix: PASS within scope

All originals listed in archive-manifest.json were retained; declaration normal/hover/down/focus and return frames were independently viewed.

| CSS viewport | Normal declaration | Pointer hover | Held real mouse.down | Tab declaration focus | Actual mouse release license popup/return |
|---|---|---|---|---|---|
|1280×720|initial.png|desktop-hover|desktop-down|desktop-focus|desktop-return|
|568×320|short-normal|short-hover|short-down|short-focus|short-return|
|640×300|low-normal|low-hover|low-down|low-focus|low-return|
|390×844|portrait-normal|portrait-hover|portrait-down|portrait-focus|portrait-return|

Declaration text remains dark and readable inside the paper card in each state/size. Actual Tab traversal produces the thin dark visible declaration focus rectangle. No code emitted a pressed signal or set focus. The normal frames for resized views deliberately Tab away from the declaration: another button has keyboard focus, but declaration itself is unfocused with pointer elsewhere. Those frames are not misrepresented as every control having no focus.

Additional desktop keyboard activation: after visually confirming desktop-focus is on “开源软件声明”, actual Enter opens the license tab. desktop-enter-return-license.png shows real Open Source Licenses / THIRD-PARTY NOTICES / Godot Engine4.7.2 MIT license content. After actually closing that tab, desktop-enter-return.png shows the original title with declaration focus retained. No accidental gameplay start.

Five actual license popup opens total (four mouse, one Enter), all https://narutojzm1-dot.github.io/youjia/open-source-licenses.html with title Open Source Licenses. Five real browser response events are HTTP200; popup URL/title/full text retained in result.json, each popup screenshotted and closed, original page brought front. Return frames show readable declaration; each size then reaches visible Tab focus. The full action order and monotonic command timing, console, popup records and response events remain unmodified in result.json.

## Limits

This demonstrates visual readability and keyboard/mouse operation of the declaration link, not a numerical measured pixel contrast ratio (no claim that browser pixels were measured at4.5:1), a complete accessibility audit, other menu-button contrast, native license window, physical phone, touch or audio. Other menu focus colors appear pale in intermediate frames; they are not the declaration under test. No failure or mis-targeted activation occurred in the completed matrix. An early attempt to read initial.png before rendering finished returned file-not-found to the QA tool; it neither changed the page nor constitutes a game failure. No screenshots were altered or overwritten. CSS-scale originals retain actual DPR2 context in driver.

errors=[]; run.exit0; browser.close completed before handoff. No production code or site content was modified.
