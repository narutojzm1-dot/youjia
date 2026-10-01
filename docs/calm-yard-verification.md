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
