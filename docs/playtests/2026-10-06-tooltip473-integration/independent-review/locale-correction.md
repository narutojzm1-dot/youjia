# Tooltip473 locale attribution correction

Current source review: `a0a856f64e7764fbab5270412025e62b8e34cafd`, `scripts/main.gd` line246 inside `_ready()` explicitly calls `I18n.set_locale("zh-CN")` before building the UI. This is the directly observed cause of the startup locale reset. The earlier v3 independent report's statement that startup restored a saved locale was an incorrect causal attribution; that historical report and test raw logs remain unchanged for traceability, and this correction supersedes its cause description.

V2's210/0 did not cover English. V3's230/0 remains valid controlled native bilingual robustness evidence because it sets locale after startup, asserts requested equals actual, and records actual translated Chinese/English text. It is not a player-facing language-switch path. No ordinary UI language selector was found or authorized; no browser locale injection, fake English entry or product expansion is required. Planned ordinary Web acceptance is actual Chinese mouse input at1280×720,390×844,568×320 with statedDPR/reflow. English remains the controlled-native coverage only.

No source or original report was modified by this reviewer, and no runtime was launched for this correction.
