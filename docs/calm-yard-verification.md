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

## Recorded event photos

- New photos retain the actual encounter's character frames, poses, expressions, held/loose grass, lead, weather tint and yard background. Event-specific crops show the relevant people/animals/pond, rather than repeated white-background catalog portraits.
- Snapshots are inert JSON scene records (~7–8 KB per event), rendered from the existing approved assets. No new character artwork, waiting, chores, screenshot readback or image upload is introduced.
- Save version4 preserves every existing collected ID. Old IDs without a scene acquire one only when that encounter really happens again, without another unlock notice or camera jump. Malformed scene data is discarded without deleting album progress.
- Renderer/data tests cover six events, clipping, backdrop bounds, immutable state, existing hero frames and shader/atlas fidelity. Save integration tests cover real harvest/feed, scene cards, reload, old-save migration and silent upgrades.
- Native free-input candidate4 validation: fresh0/6; ordinary harvest/feed and pond observation produced distinct event photos; cards remained unchanged after walking elsewhere, returning to the menu, and exiting/restarting the process. Album scrolling, close, Escape and confirmation remained usable. Neighboring non-subject animals can be partially cropped like a normal local photograph; no subject/frame clipping blocker was observed.

## Pointer boundary feedback

- Rejected clicks now show a brief warm broken ring at the actual selected point and a short footing explanation. No walkable geometry was expanded.
- A click at the player's feet stops the previous route without a false unreachable warning. A newer valid click immediately clears the rejection.
- `boundary_feedback_suite.gd` checks the exact rejected point, fade lifetime, replacement by a valid route, feet-stop behavior, and disabled input (11 checks).

- Candidate5 actual native input review found the rejection text remained briefly after a valid new destination. Candidate6 clears only that obsolete rejection on newer clicks or keyboard movement, preserving unrelated event notices.

## Independent review corrections

- Mixed pointer/Space input could feed within 88px while preserving a pending 64px approach, then unintentionally start leading at arrival. Successful immediate interactions now consume the pending intent and path. A raw device0 Space regression covers the complete delayed outcome.
- Spitting can flip a led llama immediately. The photo capture now refreshes the rope after that reaction so its stored collar endpoint uses the same pose. The regression asserts the actual stored photo, and the general photo renderer suite now checks stored event snapshots rather than a manually refreshed recapture.
- Candidate6 real native CUA review confirmed boundary ring, click-to-walk replacement, keyboard clearing, and own-feet stop. Post-review interaction/photo changes require final candidate regression before publication.
- Review also found that the person could stand beside the cow where the larger llama cannot fit. Following now falls back to a reachable point within trailing distance if the exact player footprint is blocked, rather than abandoning approach. Natural-cast seed1102026 regression at30/60/120Hz verifies substantial movement, arrival under78px, no pond/fence crossing and normalized body separation>=0.995 (18 checks).

## Engine-independent accept input

External merge d62df69 retains the reviewed source tree but its Web release was exported with Godot4.7.2. A same-source engine comparison showed the built-in `ui_accept` keyboard device changed from0 in4.6.3 to16 in4.7.2. Native4.7.2 real input still worked, so the device0 injected-test failures alone are not evidence of a user-visible regression.

The compatibility candidate explicitly binds the same Enter, keypad Enter and Space keys to all devices (-1), matching the project's existing movement/pause policy. `portable_accept_suite.gd` verifies12 logical-only and logical-plus-physical key/device0/device16 combinations, plus4 raw Space gameplay outcomes under both engines; original raw-device0 keyboard45 and mixed-input6 tests also pass unchanged on both. This is cross-engine input hardening, not a claim that native4.7.2 Space was broken.
