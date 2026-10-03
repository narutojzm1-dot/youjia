# Goose painted posture extension — REQ-20261002-004

- Date: 2026-10-02; user confirmed the art direction “every frame is an exquisite painting” and asked for a lying goose instead of permanently open wings.
- Identity/style reference: the project's already approved, right-facing white goose at `assets/holiday/characters/cast_v2/goose.png`. The original remains the active/alert cel. External sitting-geese photographs were examined only for anatomy; no photographic pixels are included here.
- Method: two separate high-resolution transparent painted posture variations of **that same** goose. One is quiet upright with both wings folded and a closed beak; the other lies with its belly in contact with the ground, its feet tucked and wings folded. No scale warp of the approved flared-wing painting masquerades as the new pose. Runtime cels are downsampled without clipping to the source cast's 1254×1254 canvas, with measured per-cel ground anchors and alpha bounds in `cast_v2/manifest.json`.

| Pose | 1920×1920 transparent source master SHA-256 | 1254×1254 runtime PNG SHA-256 | Alpha bound `(x,y,w,h)` | Ground anchor `(x,y)` |
| --- | --- | --- | --- | --- |
| Calm, folded standing | `goose_calm_master.png` · `dae18d0555b289e77cd89ee12305172d2fa1cc302d5beb771db8f381052439a9` | `goose_calm.png` · `a967fda3e27fc974ae63728a8a055589f95e8dd26424ac9d17cef783a9e95203` | `(182,50,945,1167)` | `(694.5,1216)` |
| Rest, belly grounded | `goose_rest_master.png` · `4c961a68680775c68c39bcf33f047448a20f68a19699c0707ae50ebd12a4eacc` | `goose_rest.png` · `5a158ddf1fd32fc5c85987f6774fe4a9a97c268424c6f455c154ab7503a03983` | `(39,227,1190,853)` | `(696.5,1078)` |

All four files have real alpha and no pixels with alpha >16 touching any canvas edge. The runtime cels and their `.png.import` sidecars are explicitly committed like the ten existing `cast_v2` PNGs; the high-resolution masters live under `art/` and are excluded from player exports. Godot captures and the targeted tests, not these source images alone, determine whether the pose reads clearly at display size and stays grounded in the yard. For art acceptance/remaining work see [design decision](../../../../docs/decisions/REQ-20261002-004.md).

## Riding flap pair — REQ-20261002-015 (issue #64)

- Date: 2026-10-03; product confirmed the mount-flap moment needs **two alternating cels**, not one, because the encounter alternates frames on a 0.28s cadence.
- Method honesty: both are freshly painted, separate full-body transparent cels of the same approved goose. Neither is a scaled/deformed copy of `goose.png`, `goose_calm.png` or `goose_rest.png`. Source renders carried a baked checkerboard matte which was removed with an alpha dematte pass (8px tile detection, iterative edge shrink, small-component removal, 1px feather) before downsampling.
- Both cels share one foot anchor `(533.5,1195)` so switching between them does not move the feet. The down-stroke anchor x is copied from the up-stroke rather than recomputed per-cel, which is the deliberate convention here: flap alternation must not shift the contact point against the horse back.

| Pose | 1024×1024 transparent source master SHA-256 | 1254×1254 runtime PNG SHA-256 | Alpha bound `(x,y,w,h)` | Ground anchor `(x,y)` |
| --- | --- | --- | --- | --- |
| Riding, wings up | `goose_riding_up_master.png` · `5580d237c0391bf08fe49a6e9d1c88589e54644e3ae872c05f07b16beaacf96c` | `goose_riding_up.png` · `5b19d0c379c60491a09ca5c94a8533765752e1398bca1496e1829e94571a1dc6` | `(107, 88, 1108, 1108)` | `(533.5,1195)` |
| Riding, wings down | `goose_riding_down_master.png` · `68a6058a58dfed88a4fd25598e51c97a8a4745f6c495ca135d5e17ba453d0158` | `goose_riding_down.png` · `13c3e31a59f42dff89389c52f2e41304545fe70ef7d51c08d535637dbdf25083` | `(145, 186, 1049, 1010)` | `(533.5,1195)` |

Runtime keys registered in `scripts/game/cast_art.gd`: `riding_up` / `riding_down` (textures + `posture_metadata`, `native_facing=1`). Runtime cels are 1029387 and 839572 bytes, both under the `goose.png` 1,212,584-byte ceiling. The high-resolution masters live under `art/` and are excluded from player exports. Director wiring of the two cels into the mount encounter stays with REQ-014 / `CODEX-LEAD`.
