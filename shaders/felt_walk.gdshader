shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;
uniform float amount = 0.0;
uniform float hip = 0.68;
uniform float foot_split = 0.5;
uniform bool face_override = false;
uniform sampler2D expression_texture : filter_linear;
uniform vec4 face_region = vec4(0.0,0.0,1.0,1.0);

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	// A restrained cutout gait: bend only below the hip, keeping the face,
	// wool, and expression untouched. Opposite feet alternate stance/swing.
	vec2 uv = UV;
	float leg = smoothstep(hip, 0.98, uv.y);
	float side = mix(-1.0, 1.0, smoothstep(foot_split - 0.025, foot_split + 0.025, uv.x));
	float swing = sin(phase) * side;
	uv.x -= swing * leg * 0.055 * amount;
	uv.y += max(0.0, cos(phase) * side) * leg * 0.024 * amount;
	vec4 ink = texture(TEXTURE, uv);
	if (face_override) {
		vec2 local = (uv-face_region.xy)/face_region.zw;
		vec2 feather = smoothstep(vec2(0.0),vec2(0.08),local)*smoothstep(vec2(0.0),vec2(0.08),vec2(1.0)-local);
		vec4 expression = texture(expression_texture,uv);
		ink.rgb = mix(ink.rgb,expression.rgb,feather.x*feather.y*expression.a);
		// Preserve the canonical alpha silhouette, feet and body exactly.
	}
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	COLOR = ink * tint * inside;
}
