shader_type canvas_item;
render_mode unshaded;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float phase = 0.0;
uniform vec4 sky_bounds = vec4(0.22, 0.015, 0.84, 0.13);
uniform vec2 moon_position = vec2(0.58, 0.07);
uniform float mountain_step_x = 0.58;
uniform float mountain_top = 0.09;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec3 paint = texture(TEXTURE, UV).rgb;
	// Conservative authored horizon AND painted blue: no stars on white paper,
	// snowy peaks, roofs or foliage. Original clouds occlude the effect too.
	float sky = step(sky_bounds.x, UV.x) * step(UV.x, sky_bounds.z)
		* step(sky_bounds.y, UV.y) * step(UV.y, sky_bounds.w)
		* smoothstep(0.015, 0.065, paint.b - paint.r)
		* smoothstep(0.01, 0.035, paint.b - paint.g);
	// The right-hand peaks rise above the lower central skyline.
	sky *= 1.0 - step(mountain_step_x, UV.x) * step(mountain_top, UV.y);
	vec2 grid = UV * vec2(60.0, 34.0);
	vec2 cell = floor(grid);
	float seed = hash(cell);
	vec2 point = vec2(0.2) + 0.6 * vec2(hash(cell + 7.0), hash(cell + 19.0));
	float star = (1.0 - smoothstep(0.025, 0.12, length(fract(grid) - point))) * step(0.65, seed);
	star *= 0.66 + 0.16 * sin(phase + seed * 6.283185);
	vec2 moon_delta = (UV - moon_position) * vec2(1.0, 0.5625);
	float radius = length(moon_delta);
	float moon = 1.0 - smoothstep(0.0065, 0.008, radius);
	float halo = (1.0 - smoothstep(0.008, 0.023, radius)) * 0.08;
	float ink = max(star, moon * 0.88 + halo);
	COLOR = vec4(vec3(1.0, 0.94, 0.78), clamp(ink * sky * amount, 0.0, 1.0));
}
