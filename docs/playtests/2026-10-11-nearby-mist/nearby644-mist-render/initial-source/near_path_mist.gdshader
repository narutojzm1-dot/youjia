shader_type canvas_item;
render_mode unshaded;

uniform sampler2D region_mask : filter_linear, repeat_disable;
uniform vec4 region_bounds = vec4(480.0, 240.0, 540.0, 220.0);
uniform float phase = 0.0;
uniform float strength = 0.12;
varying vec4 paint_modulate;

void vertex() {
	paint_modulate = COLOR;
}

void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	vec2 region = texture(region_mask, (pixel - region_bounds.xy) / region_bounds.zw).rg;
	// Broad, slow bands within authored paint; all phase terms wrap seamlessly.
	float lake = 0.58 + 0.24 * sin(pixel.x * 0.048 + pixel.y * 0.025 - phase);
	lake += 0.10 * sin(pixel.x * 0.019 - pixel.y * 0.043 - phase * 2.0);
	float ridge = 0.55 + 0.27 * sin(pixel.x * 0.036 + pixel.y * 0.065 - phase);
	ridge += 0.12 * sin(pixel.x * 0.016 - pixel.y * 0.037 - phase * 2.0);
	vec3 original = texture(TEXTURE, UV).rgb;
	// Retain some of the original pigment grain instead of a flat white veil.
	float grain = clamp(dot(original, vec3(0.299, 0.587, 0.114)), 0.35, 1.0);
	float ink = strength * (region.r * lake * 0.8 + region.g * ridge);
	ink *= 0.75 + grain * 0.25;
	vec3 fog = mix(original, vec3(0.91, 0.91, 0.87), 0.68);
	COLOR = vec4(fog * paint_modulate.rgb, clamp(ink, 0.0, 0.28) * paint_modulate.a);
}
