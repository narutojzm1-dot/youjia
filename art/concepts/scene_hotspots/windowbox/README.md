# Windowbox painted encounter — REQ-20261002-009

- Date: 2026-10-02. Source reference is this project's already published `assets/holiday/environment/yard_sunny.png`, specifically the real second-floor balcony windowbox. The reference crop was only used to guide brushwork and was not introduced as a runtime asset. These three **new, original transparent paintings** were made for the user's “every frame a refined painting” direction; no third-party butterfly or stock icon was copied.
- Source paintings: `petals_master.png` is one airy hand-painted pink-petal/leaf response; `butterfly_open_master.png` and `butterfly_rest_master.png` are two complete poses of the same apricot/blue Alpine butterfly. The high-resolution sources stay under this `.gdignore` directory and are not part of the player export.
- Reproduce the compact 320×136 and two 256×256 runtime paintings by running `python3 prepare_assets.py` from the repository. The conversion only trims faint alpha noise and downscales the genuine source pigments. Butterfly cels share the same canvas, constant scale, and approximate torso pivot; no wing is programmatically squeezed or mirrored.
- Runtime paintings live at `assets/holiday/fx/windowbox_petals.png`, `windowbox_butterfly_open.png`, and `windowbox_butterfly_rest.png` (including their Godot `.import` sidecars). On the actual yard, `YardSceneFeedback` positions them over the painted flowers, behind ground-sorted characters; movement is only a restrained translation, and reduced motion holds a complete still cel. It also inherits the backdrop's sunny/overcast tint. This is **an overlay**, not a replacement of the painted windowbox, so the base flowerpot never appears twice.

| Artifact | SHA-256 |
| --- | --- |
| `butterfly_open_master.png` | `a7815a9b6705586c3fe327341ec98a50be38cad7bf524e87623a1cc8a77c6922` |
| `butterfly_rest_master.png` | `0e6a19b919f4a88c6c9e86b70178266b02472fcf47134375f87754d3ff15e9d5` |
| `petals_master.png` | `b0388e6d4cc5b919b42f22371416b98137d41c8960cd10af2e3f0b8c36f37e24` |
| `windowbox_butterfly_open.png` | `7142135264509698b3bd00241863a9dfda9db002b4b565313c8386d29b40fab8` |
| `windowbox_butterfly_rest.png` | `62de6bc9e67703be75d4d9d5d096acbec1384d66907a0f326b0f451e627a6c2f` |
| `windowbox_petals.png` | `f929179ea5494f7fdac26a20dd0998863cca8288496697d3e7376052fb1505cf` |

**Native Godot placement evidence:** [desktop sun](../../../../docs/playtests/2026-10-02-REQ-009-windowbox/sun-native.png), [overcast](../../../../docs/playtests/2026-10-02-REQ-009-windowbox/overcast-native.png), [reduced-motion still](../../../../docs/playtests/2026-10-02-REQ-009-windowbox/reduced-native.png), and [mobile response](../../../../docs/playtests/2026-10-02-REQ-009-windowbox/mobile-response.png).
