# Calm yard and grass states

## Rules

- Cow and horse stay in the upper pasture; sheep stay beside the cottage; goose patrols a small dry strip beside the pond; ducks stay on the water.
- Residents alternate long stationary intervals with short reachable local moves. Weather no longer makes sheep/goose chase the llama across the yard.
- The llama can explore any reachable lawn and resumes quiet exploration after release, including outside its initial area. Leading it to sheep or goose still earns the existing photo opportunities.
- Motion targets are checked along their complete segment. Residents turn while stopped, accelerate/decelerate, and avoid boundary retries/bounces.
- Painted animal feet now use distance-driven stance/return phases scaled to the actual artwork size. Bodies and accepted character designs are unchanged.
- Rooted grass, clipped stubble, a transient loose harvested bundle and held feed are separate visuals. Harvest changes inventory immediately. The cosmetic pickup never blocks feeding or repeated inputs. A revision counter cancels stale transfer effects after feeding.

## Outcome checks

- `test/animal_home_suite.gd`: 18 simulated minutes spanning 30/60/120 Hz, both weathers and transitions. Home confinement, water safety, stationary share, finite/continuous motion and short trips.
- `test/photo_home_suite.gd`: walk/lead from initial spawn to sheep then goose; collect natural photo triggers; release near cottage and verify free exploration continues without teleporting.
- `test/grass_state_suite.gd`: immediate inventory, visible state transfer, clipped/regrowing roots, repeated pickup/feed, no stale visual resurrection, facing/scale/palm anchor and reduced-motion checks.
- Existing explicit-target regression retains all intent checks. Its second approach now uses a real lawn tap instead of relying on the released llama to move away while the player presses into the lawn edge.
- Existing UI/capture feeding wait checks both photo and consumed inventory, so an album from an earlier run cannot falsely finish the action.

Headless accelerated simulation proves outcomes, not device performance. Native Godot render captures exercise real viewport input but use a software renderer/fixed simulation cadence; they are not iOS or browser/WebGL performance evidence.

## Physical bodies and depth follow-up

- Player and land animals have elliptical foot-ground footprints. Swept contact stops penetration; tangential movement can slide along contact instead of teleporting either body.
- Pointer paths use current animal footprints, follow safe intermediate waypoints at walking speed, and replan for moving obstacles. A temporarily occupied goal keeps its intent and retries rather than disappearing.
- Reversing while leading routes the player around the llama. The llama separately routes around residents and the pond when following.
- All character/animal draw depth is derived from the same foot Y coordinate. The former player-only 32px foreground bias is removed.
- `test/physical_yard_suite.gd` independently checks pairwise ellipse clearance, common depth ordering, four-sided approaches, six crossing routes and five leading legs at 30/60/120 Hz. No test teleports animals to make the route pass.
- `tools/capture_physical_routes.gd` renders multiple raw-viewport touch routes, including repeated lead reversals and walking in front of/behind cattle. It remains native software-renderer evidence rather than a browser/device benchmark.

## Manual playtest follow-up: keyboard, fence and lead

- Ordinary keyboard events were rejected by custom input bindings pinned to device16. Bindings now accept all keyboard devices; device0 raw key tests cover WASD, arrows and Escape after HUD focus.
- Escape is handled before GUI focus consumption, cancels a restart confirmation without resetting, closes the album, and pauses/resumes. Repeated key echoes do not toggle repeatedly.
- The right-hand walkable boundary now follows the foreground foot line of the painted fence. The previous triangle included rail/gate-top artwork and let the free-roaming llama appear on the fence.
- Contact shadows use the animals' footprint width with soft overlapping opacity layers. The lead uses the accepted hero's real palm and the llama artwork's neck anchor, and is drawn above the wearers instead of behind all sprites.
- Earlier route fixtures that clicked the painted fence were moved to actual foreground grass; explicit tests now reject those former rail points. Collision, intended-target and natural-photo assertions remain.
- Manual candidate playtest is required before publication; headless tests cannot judge whether the new rope/ground contact reads clearly at default scale.
- Native free-input candidate3 verification: held D/Down/Right moved the person; HUD stayed unfocused; Escape paused/resumed after a HUD click; Left then Space did not open the album; the previously blocked near-right grass point became reachable without stepping onto rails. The lead was visibly attached to the hand/neck and the llama's feet/shadow read as grounded at the fence front.
