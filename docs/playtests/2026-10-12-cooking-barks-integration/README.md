# CODEX-LEAD #738 integration with #758

Merge parents: existing cooking candidate b303b742c9bda94ace56eee6f88373d267780af5 and reviewed bark candidate ec4ef1d073d1f5a173f31a350039275941dc5559. Preserves original Grok and Cloud history. Final published SHA is recorded in PR #738.

Resolved append conflicts by preserving both meal and bark localization keys, both suite completion registrations, and both product/QA records. Main combines the existing cooking audio lifecycle, new menu keyboard behavior and bark presentation; no new fatigue, nutrition or AP policy is introduced. All original audio candidates remain unchanged.

Godot 4.7.2 isolated native integration checks:
- Resident barks: 99 PASS.
- House cooking: 116 checks, 0 failures.
- Meal audio host: 70 checks, 0 failures.
- Menu keyboard focus: 204 checks, 0 failures.
- Web release export: exit 0.

Each suite used a separate APPDATA. These are software checks, not human listening or physical-phone tests. Launch of the local HTTP server for another ordinary browser run was rejected by automatic approval policy, with no more specific reason; this integrated tree has no new ordinary Web playtest claim. Earlier cooking and #758 screenshots remain evidence for their stated source trees only.

Still Draft: user's audio listening reply, physical mobile/background lifecycle and updated ordinary cooking playtest remain open. No release, no audio approval, no claim that the complete growth loop is finished. Existing sleep/fatigue rules and pending cross-day AP decisions remain unchanged.

## Full-CI teardown failure and correction

Full CI 38169437986 for 9fd22f0 failed after meal_audio_suite printed 63 PASS: Linux reported four ObjectDB instances / two resources still in use at process exit. The wrapper correctly failed; no gate was weakened. Windows verbose reproduction passed without this leak, so it is not claimed as a locally reproduced Linux failure.

The suite intentionally starts native audio voices. Its teardown now follows the existing yard_audio_suite pattern: verify leaf deletion, clear the retained stream reference, release AudioDirector fixture streams, verify release, then allow 0.25 seconds for mixer retirement. Audio assets and runtime behavior are untouched. Local verbose corrected run: 65 PASS with no ERROR/WARNING; Linux confirmation remains the new final CI's job.
