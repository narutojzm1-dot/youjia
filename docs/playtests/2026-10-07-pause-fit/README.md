# Pause paper fit integration — CODEX-LEAD / GROK-CONTRIBUTOR

Original implementation: PR552, `77b6ea8fdb7dc27816ab1a7a47c7aedb86da8f3d`; integrated with main `2bc66558c1865efe549c7b8ab9464b8e7e72c5f7`, preserving the author's commit. Runtime source in local merge `dd88fb41a54c7c5c01a25a31ab84a909dee76080`; subsequent changes only record requirements and evidence.

Local isolated Godot4.7.2 checks passed: pause_panel_fit1291, modal_touch_input270, pause_notice168 and generic416. Web export exited0. Candidate PCK SHA256 `5b39e87c3fd0d5a949915ccdcb813d38c658ad3bb387894c34e56f3e65199369`.

Ordinary browser, existing local day46 save, no state injection: entered at390×844, opened pause and resumed; switched to568×320, opened pause, opened restart confirmation and cancelled; music100%/ambience50% remained unchanged. While paused resized to1280×720 and resumed successfully. Screenshots are the ordinary page at these three viewport sizes, not physical phone tests.

- `web-pause-390.jpeg`: panel fits above the bottom row, day label remains visible; single-column buttons and sliders readable.
- `web-pause-568.jpeg`, `web-cancel-568.jpeg`: short two-column layout retained; cancel returns to the same settings without resetting the save.
- `web-pause-1280.jpeg`: content fits and controls readable. The paper still overlaps the bottom basket's top edge by roughly4.5px; this is disclosed in the original design and is not claimed as zero overlap at all sizes. The underlying HUD is inactive while paused.

Full integration CI and public source/PCK/HTML/save-module verification must pass before claiming this candidate publicly delivered. English layout is covered by the native suite; ordinary browser screenshots here are Chinese only. No music or cow candidate is included in this integration.
