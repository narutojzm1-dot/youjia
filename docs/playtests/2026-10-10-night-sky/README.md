# #640 shared night sky — CODEX-LEAD

Base: main `75fdafeec0ab7c3cc1b4dd3ecc370589364d9f32`. No new saved clock and no shader TIME. Twilight is an art-directed regional clock, not astronomical simulation. Clear sky only; opaque authored cloud bands remain painted, while original pale clouds and the conservative blue/horizon mask occlude stars. This does not add moving-cloud physical occlusion or normal maps.

Native checks: regional_night_sky 3757; world_daylight 226; regional_clock 92; photo_moment_render 2523; photo_moment_save 48; save_data_codec 16; house_sleep 136. Total 6798 distinct checks. `tools/capture_night_sky640.gd` uses isolated controlled clock/weather and camera fixtures, never a player's save. Actual RTX4070 OpenGL render difference: 2417 changed pixels, 0 outside the authored sky rectangle. Camera cropping initially hid the moon; fixed authored placement and light layer order after inspecting GPU output. Nearby normal framing often contains no visible sky: sky effects stay at world coordinates instead of floating over trees.

Photographs store optional bounded amount/phase, replay without a clock, and exclude the shader sprite's source image from ordinary item capture. Invalid optional values are discarded; legacy photographs remain valid. Title/cleared world hides the light overlay. Corrected stale “stars have not appeared” night notice.

Screenshots are controlled GPU evidence, not continuous ordinary play or physical-phone proof. Browser experience, PR CI and public package verification will be recorded separately after completion. #640 remains open; #635 art is not complete and remains isolated on its own local branch.
