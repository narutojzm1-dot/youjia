# Loading performance, September 30

The first accepted release transfers about 48 MB for PCK and WASM with HTTP gzip. This revision keeps the accepted art dimensions, source PNGs, actor anchors, gameplay and animations.

- Exclude unused `assets/holiday/sharing/*`, archived `site/*` resources and the unused template backdrop from the game pack. Public website notices remain separate website files.
- Import holiday paintings and sprites with Godot's lossy WebP mode at quality 0.85. Sources and alpha geometry are retained. Actual rendered yard quality was visually checked.
- PCK: 38,657,900 → approximately 10,257,600 bytes. Local gzip level 6: PCK + engine 47,826,676 → 19,542,586 bytes (about 59% less). Public-server encoded sizes can differ and must be measured after publication.
- The official unmodified engine still costs about 9.5 MB compressed. This is not an instant-load promise for an 80 KB/s connection. This change does not move hosting.
- Loader reports decoded resource bytes explicitly, download completion, engine ready and the first rendered frame. `window.youjiaLoadTimings` stores millisecond offsets; it does not send telemetry anywhere. The loading overlay only disappears after both engine readiness and the Godot first-frame event.
- WebGL2 and startup errors are visible rather than an indefinitely frozen percentage.

For production export, use `game-<source-commit-prefix>.html`, then rename only that HTML entry to `index.html`. Keep the matching versioned JS/WASM/PCK filenames and generated config. Retain the previous release's asset filenames during rollout so cached old HTML remains valid; never combine new HTML with an old same-name PCK that lacks the first-frame event.

Validation: 389 general + 399 locomotion checks, loader mocked-state tests (progress, unknown length, stall notice, both first-frame orderings, unsupported WebGL2), isolated exported pack resources/boot/gameplay/font checks. Cloud browser lacks WebGL2, so actual web gameplay remains unverified in that browser. Native Godot graphics render has been inspected.
