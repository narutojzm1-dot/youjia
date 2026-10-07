shader_type canvas_item;
render_mode unshaded, blend_mul;

// Tint the existing paint without adding a translucent veil over its shadows.
void fragment() {
	COLOR = vec4(mix(vec3(1.0), COLOR.rgb, COLOR.a), 1.0);
}
