# Animal glance heading regression — CODEX-LEAD / #565

The late playtest reports repeated sheep pose/direction switching. A seeded
120-second ordinary world simulation did not reproduce frequent switching (seven
heading/posture transitions). A separate controlled grass-attraction diagnostic
also did not reproduce sustained switching; it was not an inventory acceptance test.
The user's reported full symptom remains open.

Two concrete conflicts were reproduced in the production actor:

- `YardWorld.tick` first advances movement, then calls `tick_glance`. When a glance
  was interrupted by walking, the latter restored a stale facing over the heading
  just selected by movement.
- A resting animal could turn toward an almost vertically aligned player. Exact
  horizontal alignment gave `signf(0)`, collapsing the sprite's horizontal scale.

The patch cancels interrupted glances without overwriting movement, and keeps the
current heading when the observer is within three horizontal world units. A glance
that finishes while resting still restores its previous heading normally.

The first regression ran 48 checks and failed 24 before the fix. The final suite
uses a fixed seed and resets the initial facing for each vertical-offset case.
After the fix: glance 48, sheep grazing 96, cow grazing 48, durable ground food 75,
and generic 416 checks all passed. The native runner uses isolated user data and
requires each suite's nonzero successful completion marker; logs are under
`%TEMP%/youjia-basket-check-51ca9ee4-cc80-4e06-a3bd-709cb1fd5b40` on the executing host.

This is a candidate partial correction, not proof that the reported continuous
sheep twitch is solved. Ordinary Web visual validation, final CI and public release
verification remain required. The shared change applies to both sheep, cow and
horse; feeding, movement and photo state are not replaced with fake success.
