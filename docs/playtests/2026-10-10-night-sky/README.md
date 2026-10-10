# #640 shared night sky — CODEX-LEAD

Base: main `75fdafeec0ab7c3cc1b4dd3ecc370589364d9f32`. No new saved clock and no shader TIME. Twilight is an art-directed regional clock, not astronomical simulation. Clear sky only; opaque authored cloud bands remain painted, while original pale clouds and the conservative blue/horizon mask occlude stars. This does not add moving-cloud physical occlusion or normal maps.

Native checks: regional_night_sky 3759; world_daylight 226; regional_clock 92; photo_moment_render 2523; photo_moment_save 48; save_data_codec 16; house_sleep 136. Total 6800 distinct checks. `tools/capture_night_sky640.gd` uses isolated controlled clock/weather and camera fixtures, never a player's save. Actual RTX4070 OpenGL render difference: 2417 changed pixels, 0 outside the authored sky rectangle. Camera cropping initially hid the moon; fixed authored placement and light layer order after inspecting GPU output. Nearby normal framing often contains no visible sky: sky effects stay at world coordinates instead of floating over trees.

Photographs store optional bounded amount/phase, replay without a clock, and exclude the shader sprite's source image from ordinary item capture. Invalid optional values are discarded; legacy photographs remain valid. Title/cleared world hides the light overlay. Corrected stale “stars have not appeared” night notice.

Screenshots are controlled GPU evidence, not continuous ordinary play or physical-phone proof. Browser experience, final CI and public package verification are recorded below. Combined with PR649 window rules and PR658 solar light, #640 has met its stated acceptance. #635 art is not complete and remains isolated on its own local branch.

## Continuous light evidence

[Continuous 17:00 to next-day 07:00 movie](night640-continuous-proof.mp4), 350.25 seconds, 640x360/10fps, silent H.264. Original 7005-frame 20fps recording uses a controlled 17:00 start and clear regional episode, then ordinary 0.05-second runtime steps; no later clock jumps, time acceleration, edits or cuts. Recorded preceding visual tree cbb9d40b99dce6bb8ad035e729b5bfa9383759ea; final code adds only same-session reload reference cleanup. Full driver source and checkpoint log are beside the movie. Video SHA256 2d63147c72f2cad032f48ec2117678cbda4e2dec9e4d55f3cca58889fa7c4d5e. This is controlled continuous runtime evidence, not manual browser play and not audio acceptance.

Ordinary browser fresh profile naturally reached day 2 midnight (star/moon/window-light screenshot), 390x844 responsive night screenshot, and day 3 dawn with celestial light gone. No save or time injection. Final code candidate re-exported and genuinely reloaded. Real phone touch and listening are not claimed.

Pre-publish Gmail recheck timed out; last successful round-start check was 08:34 CST. Failure is not evidence of no new reply. Historical SHA text accidentally altered by broad numeric replacement was restored verbatim from main before merge; only the new #640 section is added.


## Final public delivery

PR684 final head `27be9317d86a779b6530e3a91e13e46d7b6e628c`, full CI 38013464759 success; merged source `82f18b75939b7107d77286efc00fed1d0b63ffd5`. Preserves Cursor683 and Grok685 original commits. Publish 38014493526 and Pages 38015309167 succeeded. Actual public manifest source, HTML/PCK Git blobs, ten storage modules, four engine assets and two loader modules all verified against the deployed files. PCK 65917076 bytes, SHA256 `f2add87d49f5177b60853b88d84ee8970185ada7787901732dea6d478bb171c9`.

Ordinary public old save was reloaded through the title screen and normal UI, retaining its day, basket and animal progress; [screenshot](public/old-save-restored.png). No browser storage/time injection. Ordinary local final-code play later reached day 5 at 02:36 under overcast: dark scene, warm outdoor windows, no visible stars/moon [screenshot](web-natural-overcast-midnight.png). [Manifest](public/game-release.json), [download verification](public/verification.json). The movie remains explicitly controlled continuous runtime evidence and the browser night shots ordinary natural-time experience; no physical phone or audio listening acceptance is claimed.

The original #640 conditions are now covered together: deeper midnight and sunny gold sunrise/orange sunset (PR658); restrained overcast/rain colour; four inside/outside night/midnight lamp combinations (PR649 and 136 sleep checks); clear-sky stars/moon and shared scene/photo/save behaviour (PR684); continuous sunset-to-dawn recording linked above. Normal maps were optional in the request and are not implemented. This closes #640, not the entire game Goal.

The single-thread Gmail read timed out earlier. At 09:33 CST the batch-thread fallback successfully read the full three-message decision thread, and the inclusive read/unread incremental search succeeded with no new user decisions; the deduplication state was updated. No extra mail sent. This daytime delivery does not duplicate the 23:00 daily release or its mail.

#635 follow-up: two further generated opposite-leg attempts were rejected for repeated lead legs / unwanted halo. Isolated local journal commit `52dd0eff45` records the result; no eight-direction runtime claim or publication.
