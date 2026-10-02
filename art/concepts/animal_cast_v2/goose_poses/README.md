# Goose painted posture extension — REQ-20261002-004

- Date: 2026-10-02; user confirmed the art direction “every frame is an exquisite painting” and asked for a lying goose instead of permanently open wings.
- Identity/style reference: the project's already approved, right-facing white goose at `assets/holiday/characters/cast_v2/goose.png`. The original remains the active/alert cel. External sitting-geese photographs were examined only for anatomy; no photographic pixels are included here.
- Method: two separate high-resolution transparent painted posture variations of **that same** goose. One is quiet upright with both wings folded and a closed beak; the other lies with its belly in contact with the ground, its feet tucked and wings folded. No scale warp of the approved flared-wing painting masquerades as the new pose. Runtime cels are downsampled without clipping to the source cast's 1254×1254 canvas, with measured per-cel ground anchors and alpha bounds in `cast_v2/manifest.json`.

| Pose | 1920×1920 transparent source master SHA-256 | 1254×1254 runtime PNG SHA-256 | Alpha bound `(x,y,w,h)` | Ground anchor `(x,y)` |
| --- | --- | --- | --- | --- |
| Calm, folded standing | `goose_calm_master.png` · `dae18d0555b289e77cd89ee12305172d2fa1cc302d5beb771db8f381052439a9` | `goose_calm.png` · `a967fda3e27fc974ae63728a8a055589f95e8dd26424ac9d17cef783a9e95203` | `(182,50,945,1167)` | `(694.5,1216)` |
| Rest, belly grounded | `goose_rest_master.png` · `4c961a68680775c68c39bcf33f047448a20f68a19699c0707ae50ebd12a4eacc` | `goose_rest.png` · `5a158ddf1fd32fc5c85987f6774fe4a9a97c268424c6f455c154ab7503a03983` | `(39,227,1190,853)` | `(696.5,1078)` |

All four files have real alpha and no pixels with alpha >16 touching any canvas edge. The runtime cels and their `.png.import` sidecars are explicitly committed like the ten existing `cast_v2` PNGs; the high-resolution masters live under `art/` and are excluded from player exports. Godot captures and the targeted tests, not these source images alone, determine whether the pose reads clearly at display size and stays grounded in the yard. For art acceptance/remaining work see [design decision](../../../../docs/decisions/REQ-20261002-004.md).
