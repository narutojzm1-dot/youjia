# Cow ground feeding — CODEX-LEAD, #504

Work in progress; not published. Reuses the existing cast identity. Built-in image_gen generated a complete grazing cel; no programmatic body deformation, alpha replacement or sprite-part collage.

Selected source: exec-a263bb4b-afde-4984-8b19-16b333361a6e.png, copied byte-for-byte to assets/holiday/characters/ground_feed/cow-graze-v2.png. RGBA1254×1254,1051174bytes. Alpha>16 bounds [73,314,1104,682]; no opaque border clipping. Ground anchor [750,990], mouth [223,965], native facing -1. First draft exec-d00710ca-6be6-411c-9c38-849cc701ae08.png rejected for edge crowding; v2 corrects framing. Original standing cow remains unchanged.

Generation brief: exact cast_v2/cow.png character, cream-white and ginger patches, tan horns, white forelock, pink muzzle/ears, brown cloven hooves, relaxed eyes, udder/tail and watercolor/gouache texture; entire anatomically bent neck/head grazing with muzzle at hoof-ground height, facing left; transparent background, no grass/ground/shadow/text/extra animals. Revision brief: preserve exact pose/identity and paint, uniformly reduce framing to at most78% width, restore clipped ear/tail, leave transparent margins; no new elements.

Runtime: approach with the mouth offset instead of the body's centre; validate legal ground and collision before choosing the feeding stance. On arrival face the food, stop the remaining path, show the whole painted cel while competing for the same single durable food item. Cow feeding does not enable leading. Shared inventory/save protocol unchanged.

Evidence: controlled-contact.png is an isolated native GPU rendering from the real ground-food runtime suite with controlled positions, not ordinary mouse play. Visible muzzle contacts the separate grass sprite.63 native ground-food checks (durable drop/consume/reload, competitors, pause, return home, gate cluster, duck bank and rope priority),8 cow-glance and416 generic checks pass. Initial metadata-property access was invalid; corrected to the actor's existing visual_scale metadata. Initial gate assertion compared body centre to food region; now checks the actual biting mouth enters that same region, retaining durable consumption and route checks. Earlier failing runs are not counted as passing.

Still required: right-facing/reduced-motion and small viewport contact, photo compatibility, ordinary Web play, PR/CI and public package verification. Sheep/llama/duck/goose low-head food poses are separate remaining scope; this cow slice does not complete #504.
