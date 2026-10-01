# Playability recovery

The previous world-only captures and direct method tests missed a real UI failure: fullscreen Main intercepted mouse input before `_unhandled_input`, and raw touch was not implemented. A new viewport-dispatched regression starts from the initial title/yard with no teleporting or forced photos.

Fixed:
- Ground clicks and raw touches now reach navigation. Touch menus/HUD are explicitly hit-tested with their canvas transform; paired mouse events cannot double-toggle them.
- Tapping grass or the llama is an approach-and-interact command. The selected target is preserved through arrival, even when both interaction ranges overlap; a grass command cannot feed/toggle the llama, and a llama command cannot pick nearby grass. HUD commands also keep their explicit target, while Space retains contextual priority. The llama waits during approach. Keyboard motion cancels that intention; invalid background taps never feed or toggle a lead.
- A short visibility-graph route follows the concave lawn instead of pushing into its boundary. The destination is visible.
- HUD, pause and album remain in a CanvasLayer independent of photo zoom. Portrait and landscape layouts reserve an operation strip, keep controls on-screen and allow a single-column scrolling album.
- Feeding takes priority over passive expressions and must produce its exact photo. Photos remain automatic nearby observations, with no task list or collection chore.
- A visible loose cord connects the player and the led llama. Release is an explicit button.
- Weather changes light on one stable yard rather than replacing the painted geography underneath actors.
- Spit faces and travels toward the actual goose from the measured mouth, with a short world-space arc rather than inverse-scale high-speed particles. Goose/sheep approach targets stop outside the llama's body.
- Grazers rest longer, take shorter local steps, and retain rigid bodies rather than whole-body hops/pivot squeezing.

Limits: animal legs remain restrained procedural cutout animation, not fully authored natural walk cycles. Actors can still overlap; a full dynamic-obstacle/collision system is outside this recovery. Portrait preserves the full yard, so its scene is smaller than landscape. Native real-input playback and actual scoped-window clicks were verified; iOS Safari and cloud-browser WebGL playthrough are not claimed. Cloud Chrome lacks WebGL2.

Evidence: `capture_gameplay_input.gd` uses actual viewport InputEventScreenTouch/MouseButton dispatch on the Main scene, with `--fixed-fps 30`. Every third real renderer frame is recorded and played at 10fps, preserving game speed. Test suites may accelerate simulation for assertions and are not timing evidence. Mobile 390×844 and 844×390 captures use the actual engine renderer and raw UI events.

Target-intent regression: `test/explicit_target_suite.gd` starts from the title and initial spawn with viewport mouse/touch and keyboard input. It covers the naturally moving llama, immediate and walking-arrival interactions beside grass, full-hands grass taps, HUD and Space semantics, exact background destinations, and cancellation by invalid newer taps. It does not teleport actors or force a photo.
