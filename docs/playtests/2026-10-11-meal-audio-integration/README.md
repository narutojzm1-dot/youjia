# #700 / #745 production meal audio candidate — CODEX-LEAD, 2026-10-11 21h

Preserves Grok PR747 full author head `2bcf4ab7e8ff304d1ad72370792320f8d6f360a7`, previous PR738 `0230a25b84cdf7bbb1fa1224b96316f4b02a6811`, and main `14e38fb442447c4d6fe5e37918cc4eb02c0f8600`. Previous 738 CI38136515666 succeeded; it is not the CI result of this new tree.

## Implementation

Main owns one MealAudioHost. Actual house `cook` stage starts the existing Grok loop; leaving/cancelling cook stops it. Scene replacement suspends immediately. AudioDirector gesture/application permission, pause and modal panels gate playback; focus loss suspends immediately. No new save fields. Hunger observes continuous live meal-window endings, requires a valid idle ledger and absence of a completed receipt, and never infers hunger from AP (fatigued breakfast can earn 0). Busy/unknown/paused/load/time-jump observations are discarded, not queued for replay.

## Controlled verification

Godot 4.7.2 Windows headless, isolated APPDATA: host 70, full Main cooking 116, leaf 63, HUD pointer 72, exit0, completion markers present, no ERROR/SCRIPT ERROR. Host covers each meal, zero-point eaten breakfast, mute/permission/pause/scene lifecycle and invalid/unknown ledger boundaries. Full Main checks actual cook start/confirmed stop and scene reset. These are controlled fixtures, not ordinary player or hearing acceptance. Initial test-only float inference error and a fixture that ignored the leaf's 350ms cooldown were fixed before successful runs; production cooldown was not weakened.

## Ordinary Web evidence

Local release export succeeded, final log and exact PCK/source hashes attached. In-app browser 1280x720, existing Day5 save, ordinary controls only, no hidden world/inventory injection. Before the final one-line scene-suspend guard, observed autonomous lunch and balcony brushing (live screenshot observation; no claim the later still captures brushing), medium fish 1 to 0, wheat2/corn2 unchanged. Saved after-stock and pause stills. Returned to title, reloaded final export, entered Day5 at 13:42, opened basket: medium fish0/wheat2/corn2 preserved. Final stock still attached. Console error/warn query empty. Browser tab closed; no user audio/OS settings changed.

## Limits / next acceptance

Grok's native Pulse software recordings were reviewed at review5483425619: valid output/mute evidence, not human listening. This round does not prove hardware or Web audible quality, mobile audio, background lifecycle on actual devices, loop seam quality, or every branch through ordinary play. PR738 stays Draft, not merged/published. Next: actual listening and device lifecycle evidence; remaining growth labor/experience, carried-food pose and ingredient sources are separate unfinished work. Fatigue scope confirmation and #750 dietary attributes are synchronized in design/requirements/decisions, not claimed implemented here.
