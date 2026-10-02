# Painted interaction responses — REQ-20261002-008

Date: 2026-10-02. The user expects an exquisite painting in every frame and visible feedback on successful interactions. Two **original transparent watercolor paintings**, not polygon icons or recolored gameplay assets, were created with the built-in image tool using the game's actual yard capture as style context. They appear only briefly near the recipient; no screenshot or existing yard art was copied into the resulting PNGs. This directory is excluded from Godot import/export by `.gdignore`, and `export_presets.cfg` excludes `art/*`.

| Response | 1920×1920 source master SHA-256 | 512×512 runtime cel SHA-256 | Trigger |
| --- | --- | --- | --- |
| Rose-pink painted hearts | `pet_heart_master.png` · `03f657a4038a02bf15cce41315fdbb2a32a4db967ddfb617d8a44883b3d55b12` | `assets/holiday/fx/pet_heart_watercolor.png` · `e09793c84c29070b9c3017c5f8a487a8d6ec4af70d6e8dfe7d69f3ce4aec19a4` | A cow/sheep/horse was actually petted within reach; follows that exact actor. |
| Pale-blue painted water droplets / shallow ripple | `water_splash_master.png` · `eb514e0f604e31302ee75f98e6b850c70159dfd412907b692522b155c6b877e0` | `assets/holiday/fx/water_splash_watercolor.png` · `e0db086c7d7bb8486a3da7de7617aebc4b384f1094af43abb2c25453dc476482` | Seed or sprout actually watered for the first time that day. |

`prepare_assets.py` deterministically bounds alpha >16, provides proportional 24% breathing room and downsamples by LANCZOS; it zeroes transparent noise and never distorts either painted image. Both runtime cels are RGBA with content set back from every canvas edge and need explicit `git add -f` under this repo's asset ignore rule. See [real Godot yard captures](../../../docs/playtests/2026-10-02-REQ-008-pet-water-feedback.md). This is a response overlay, not an animal action-frame substitute; future affection or plant-growth poses must be separate artwork.
