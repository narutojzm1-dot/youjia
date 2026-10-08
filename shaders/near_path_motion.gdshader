shader_type canvas_item;
render_mode unshaded;

// Red: water interiors. Green: leaf / grass interiors. Black: unchanged paint.
// The mask never includes banks, bridge, trunks, house, road or paper edge.
uniform sampler2D region_mask : filter_linear, repeat_disable;
uniform float phase = 0.0;
varying vec4 paint_modulate;

void vertex() {
	paint_modulate = COLOR;
}

void fragment() {
	vec2 region = texture(region_mask, UV).rg;
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	float wave = sin(pixel.x * 0.085 - pixel.y * 0.05 + phase * 3.0);
	float leaves = sin(phase + pixel.y * 0.03) * 0.8 + sin(phase * 2.0 + pixel.x * 0.035) * 0.25;
	vec2 displacement = vec2(wave * 1.1, wave * 0.45) * region.r;
	displacement += vec2(leaves, leaves * 0.2) * region.g;
	COLOR = texture(TEXTURE, UV + displacement * TEXTURE_PIXEL_SIZE) * paint_modulate;
}
