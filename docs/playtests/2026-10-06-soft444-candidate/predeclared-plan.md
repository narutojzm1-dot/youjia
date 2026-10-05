# PR444 local candidate QA plan

Runner: implementation agent `/root/soft444_integration`, not independent final reviewer.
Final review stays `/root/leader_scope_audit`.

Run only after root releases the single browser/Godot window. Estimated 8–12 minutes.
One Chromium process; three fresh contexts, sequential 1280×720, 390×844, 568×320, DPR2.
Fresh context audio settings default on; perform off/on pair and visually confirm original label restored before closing.

For each size:
1. Actual first-frame title, ordinary Tab focus on play; capture readable focused text/ring.
2. Real mouse down on play; capture held state; release to enter yard. No Godot method call.
3. Escape opens pause. Observe layout; actual mouse click music off, move pointer aside, capture persistent focus and readable label. Repeat click on and move aside; capture setting label restored. This is UI feedback, not audibility proof.
4. From focused music Shift+Tab twice targets restart in the existing pause order; inspect screenshot before Enter. Enter opens the safe confirmation dialog. Capture whole dialog, then hold mouse on cancel, release and verify pause returns. Never accept restart or title departure in this path.
5. Record any clipped text/ring at short/narrow viewport; compare unchanged layout/hit behavior from ordinary successful operations, not numerical Godot control bounds.

Optional non-blocking album subcase: ordinary title album entry/back focus, or naturally generated photo if encountered; no save/photo injection and no waiting/restarting until a selected random photo. Empty album or skipped photo remains explicitly limited.

Bind each context before/after to actual fetched candidate metadata plus actual index.pck bytes/SHA256; HTML dataset must be candidate-soft444-14a85a5. Save all ordinary command receipts, original PNGs, console/errors, and first failed attempts.
No title license repeat matrix, business state injection, scripts calling grab_focus/emit_signal, acoustic or physical-device claims.
