# Confirmed overnight fatigue hints — CODEX-LEAD / #700

Built on main including Cloud #759 and the reviewed #703 bark implementation. Only Main's fatigue presentation entry changes. The existing source of truth is SaveStore.get_rest_context(); legacy/sleep/invalid provenance never implies fatigue. A pending save cannot emit a new hint.

After 15 continuous seconds with the yard available for a bubble, offer the existing localized fatigue line. Existing 60-second same-line/global cooldowns apply. Menus, house actions, invisible player, exploration, save trouble and an already visible bubble reset preparation; no overdue queue. This is a configurable presentation interval, not an AP, fatigue recovery or nutrition rule. No saved fields change.

Godot 4.7.2 Windows, independent isolated profiles:

- Resident barks: 120 checks PASS, including real queued natural rollover, pending rejection, legacy, invalid provenance, sleep recovery, reread, modal/scene suppression and no data mutation.
- Rest context: 43 checks, 0 failures.
- Latest Cloud HUD keyboard: 234 checks, 0 failures.
- Controlled native GPU: 1280×720 and 390×844. Only the initial clock is placed just before the morning boundary. World/SaveStore confirm it; the normal Main loop emits the hint after about 15 seconds. The capture tool never calls show_bark. Screenshots explicitly named controlled-*.

Natural-night recording is performed separately with YOUJIA_FATIGUE_NATURAL_NIGHT=1, a fresh isolated profile, no clock, inventory or save injection and a 660-second timeout. Its final result is recorded below when completed. The tool enters the normal holiday scene via its production entry method; this is native engine playback, not a physical-phone or browser touch session.

Full CI/export, final SHA and public artifact verification belong to the original PR. #738 cooking/audio remains a separate Draft pending hearing and its other gates; this silent hint does not accept audio or complete #700.

Local Web release export: PASS after creating the output directory. The first invocation failed solely because the temporary destination directory did not exist; no code or asset fix was needed. Full hosted CI remains the merge gate.

Natural-night result: PASS. Fresh day 1 / legacy at elapsed 0.0167; unchanged production clock reached midnight at 450.0065 seconds with legacy provenance still intact; automatic day 2 / awake morning emitted the localized fatigue hint. Wall elapsed to capture: 621,333 ms, screenshot error 0, process exit 0, no runtime errors. See natural-midnight.png, natural-morning.png and natural-night.log. The character lying outdoors is an ambient idle pose, not the house sleep operation.
