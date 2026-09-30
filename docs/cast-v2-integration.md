# Approved painted cast and cow–horse teasing

The user approved the second cast design and integration on 2026-09-30. The
existing yard now contains nine animals of six species: one llama, one irritable
goose, two distinct sheep, one weary cow, one weary chestnut horse and three
instances of the same duck. The accepted sixteen-frame resident hero remains
unchanged.

## Resources and scale

Ten source PNGs and provenance are in `assets/holiday/characters/cast_v2/`.
`manifest.json` records source dimensions, measured visible bounds, native facing
and ground anchors. `CastArt` converts visible height into world scale rather
than applying the old small-image multipliers to the new1254px canvases. Unit-depth
height targets: llama/cow100px, horse110px, sheep/goose70px, duck34px, with the
existing duck size differences and scene-depth scaling preserved. Picture-layout
scales are converted using the same source ratio. The metadata is explicitly
included in the export preset; concept sheets under `art/` are excluded.

The raw generated llama variants are not pixel-identical. World sprites and
album portraits therefore retain the canonical smirk image's body/feet/alpha
and use only a softly blended face rectangle from the expression texture.
Expression changes do not change the body resource, ground anchor or breathing
pattern. Spit originates at the measured mouth point, with the old effect size
compensated for the larger source resolution. The obsolete experimental llama
limb rig is not allowed on this new artwork.

No new animal animation system was added. Existing traveled-distance gait,
acceleration, ground constraints, rest rhythm and non-walking swimming behavior
remain. The horse shares the lawn, avoids the pond and has a photo-layout slot.

## Relationship and save compatibility

The internal rule ID `llama_sheep_cow_smirk` is intentionally retained so old
collected photos and mainline completion continue to work. Its new condition is
cow and horse sharing the pasture, with the llama in the pasture and visible
to the player. It no longer requires a sheep. The new caption is “今天不加班”.

Ambient teasing has priority65, below feeding70; its existing7-second hold and
16-second additional cooldown prevent constant refresh. The expression can
recur, while its photo is collected only once. Mainline and total album counts
remain4 and6. The goose's existing overcast approach can provoke annoyance and
spitting. There are no jobs, grind, damage, currencies or daily tasks.

## Verification

- `npm run verify:locomotion`: 389 general +399 focused checks passed
- Focused checks cover all nine resources/anchors, facing, horse lawn/pond
  constraints and picture placement, cow+horse condition and missing-partner
  negatives, repeated expression cooldown, old-photo compatibility, feeding
  priority and fixed llama body across four expressions
- Local `--export-pack Web` and an isolated exported-pack verifier passed
  resources, metadata inclusion, font coverage, exclusions, boot, gameplay,
  calibrated horse art and the accepted default hero
- Actual Godot renders: full cast, four expression states with fixed body, and
  an eight-second interaction capture through normal condition evaluation
- No push, PR, merge or deployment was performed

The source artwork and the approved hero's existing motion limitations are not
hidden by passing tests; this milestone finalizes the approved static cast and
its bounded interactions.
