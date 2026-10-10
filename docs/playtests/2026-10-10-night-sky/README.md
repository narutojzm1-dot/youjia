# #640 shared night sky — CODEX-LEAD

Base: main `75fdafeec0ab7c3cc1b4dd3ecc370589364d9f32`. No new saved clock and no shader TIME. Twilight is an art-directed regional clock, not astronomical simulation. Clear sky only; opaque authored cloud bands remain painted, while original pale clouds and the conservative blue/horizon mask occlude stars. This does not add moving-cloud physical occlusion or normal maps.

Native checks: regional_night_sky 3759; world_daylight 226; regional_clock 92; photo_moment_render 2523; photo_moment_save 48; save_data_codec 16; house_sleep 136. Total 6800 distinct checks. `tools/capture_night_sky640.gd` uses isolated controlled clock/weather and camera fixtures, never a player's save. Actual RTX4070 OpenGL render difference: 2417 changed pixels, 0 outside the authored sky rectangle. Camera cropping initially hid the moon; fixed authored placement and light layer order after inspecting GPU output. Nearby normal framing often contains no visible sky: sky effects stay at world coordinates instead of floating over trees.

Photographs store optional bounded amount/phase, replay without a clock, and exclude the shader sprite's source image from ordinary item capture. Invalid optional values are discarded; legacy photographs remain valid. Title/cleared world hides the light overlay. Corrected stale “stars have not appeared” night notice.

Screenshots are controlled GPU evidence, not continuous ordinary play or physical-phone proof. Browser experience, PR CI and public package verification will be recorded separately after completion. #640 remains open; #635 art is not complete and remains isolated on its own local branch.

## Continuous light evidence

[Continuous 17:00 to next-day 07:00 movie](night640-continuous-proof.mp4), 350.25 seconds, 640x360/10fps, silent H.264. Original 7005-frame 20fps recording uses a controlled 17:00 start and clear regional episode, then ordinary 0.05-second runtime steps; no later clock jumps, time acceleration, edits or cuts. Recorded preceding visual tree cbb9d40b99dce6bb8ad035e729b5bfa9383759ea; final code adds only same-session reload reference cleanup. Full driver source and checkpoint log are beside the movie. Video SHA256 2d63147c72f2cad032f48ec2117678cbda4e2dec9e4d55f3cca58889fa7c4d5e. This is controlled continuous runtime evidence, not manual browser play and not audio acceptance.

Ordinary browser fresh profile naturally reached day 2 midnight (star/moon/window-light screenshot), 390x844 responsive night screenshot, and day 3 dawn with celestial light gone. No save or time injection. Final code candidate re-exported and genuinely reloaded. Real phone touch and listening are not claimed.

Pre-publish Gmail recheck timed out; last successful round-start check was 08:34 CST. Failure is not evidence of no new reply. Historical SHA text accidentally altered by broad numeric replacement was restored verbatim from main before merge; only the new #640 section is added.
