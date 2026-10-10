shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;
uniform float amount = 0.0;
uniform float hip = 0.68;
uniform float foot_split = 0.5;
uniform bool grounded_stride = false;
uniform float stride_uv = 0.1;
uniform float lift_uv = 0.015;
uniform float native_walk_face = 1.0;
uniform bool face_override = false;
uniform sampler2D expression_texture : filter_linear;
uniform vec4 face_region = vec4(0.0,0.0,1.0,1.0);
uniform float rest_breath_shift = 0.0;
uniform vec4 rest_breath_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform float blink_amount = 0.0;
uniform sampler2D blink_texture : filter_linear;
uniform vec4 blink_eye_a = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 blink_eye_b = vec4(0.0, 0.0, 1.0, 1.0);

float eye_mask(vec2 uv, vec4 region) {
	vec2 local = (uv - region.xy) / region.zw;
	vec2 edge = smoothstep(vec2(0.0), vec2(0.14), local) * smoothstep(vec2(0.0), vec2(0.14), vec2(1.0) - local);
	return edge.x * edge.y;
}

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
	if (grounded_stride) {
		// A planted foot travels backward at ground speed during stance; only
		// the returning foot lifts. Distance-driven phase prevents moonwalking.
		float t = fract(phase / 6.2831853 + (side > 0.0 ? 0.5 : 0.0));
		float stance = 0.6;
		float foot = t < stance ? (stance * 0.5 - t) : mix(-stance * 0.5, stance * 0.5, smoothstep(stance, 1.0, t));
		float lift = t < stance ? 0.0 : sin((t - stance) / (1.0 - stance) * 3.14159265);
		uv = UV;
		uv.x -= foot * stride_uv * native_walk_face * leg * amount;
		uv.y += lift * lift_uv * leg * amount;
	}
	// Feather the chest, including its upper silhouette; head/feet lie outside.
	uv.y += clamp(rest_breath_shift, 0.0, 0.006) * eye_mask(UV, rest_breath_region);
	vec4 ink = texture(TEXTURE, uv);
	if (face_override) {
		vec2 local = (uv-face_region.xy)/face_region.zw;
		vec2 feather = smoothstep(vec2(0.0),vec2(0.08),local)*smoothstep(vec2(0.0),vec2(0.08),vec2(1.0)-local);
		vec4 expression = texture(expression_texture,uv);
		ink.rgb = mix(ink.rgb,expression.rgb,feather.x*feather.y*expression.a);
		// Preserve the canonical alpha silhouette, feet and body exactly.
	}
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	if (blink_amount > 0.0) {
		vec4 closed = texture(blink_texture, uv);
		float mask = max(eye_mask(uv, blink_eye_a), eye_mask(uv, blink_eye_b));
		ink.rgb = mix(ink.rgb, closed.rgb, mask * blink_amount * closed.a);
		// Canonical alpha, pose, muzzle, body and feet stay unchanged.
	}
	COLOR = ink * tint * inside;
}
