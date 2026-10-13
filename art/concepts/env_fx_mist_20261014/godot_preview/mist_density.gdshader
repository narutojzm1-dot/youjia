shader_type canvas_item;
// # 与 generate_mist_density_anim.py 同一套双层雾体变换。
// # 远/近两层手绘薄雾 + 多尺度连续调制（alpha + 微形变）+ 空间包络。
// # 可选小幅平移；前景小路/木屋/桥与纸边由 envelope 保护。

uniform sampler2D base_tex : filter_nearest, repeat_disable;
uniform sampler2D mist_far_tex : filter_nearest, repeat_disable;
uniform sampler2D mist_near_tex : filter_nearest, repeat_disable;
uniform sampler2D mask_envelope : filter_nearest, repeat_disable;
uniform sampler2D mask_path : filter_nearest, repeat_disable;
uniform sampler2D mask_cottage : filter_nearest, repeat_disable;
uniform sampler2D mask_bridge : filter_nearest, repeat_disable;
uniform float phase = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float semantic_gate : hint_range(0.0, 1.0) = 0.0;
uniform vec2 base_size = vec2(1672.0, 941.0);
uniform vec2 far_origin = vec2(80.0, 340.0);
uniform vec2 near_origin = vec2(220.0, 420.0);
uniform float far_drift_px = 6.0;
uniform float near_drift_px = -4.0;
uniform float far_deform = 1.4;
uniform float near_deform = 1.8;
uniform float far_mod_xx = 95.0;
uniform float far_mod_yy = 70.0;
uniform float far_mod_fine = 38.0;
uniform float near_mod_xx = 70.0;
uniform float near_mod_yy = 55.0;
uniform float near_mod_fine = 28.0;

float muldiv255(float a, float b) {
	float t = a * b + 128.0;
	return floor((floor(t / 256.0) + t) / 256.0);
}

float mist_mod(float ph, float x, float y, float mod_xx, float mod_yy, float mod_fine) {
	float coarse = sin(ph + x / mod_xx + y / mod_yy) * cos(ph * 0.5 + y / (mod_yy * 1.3));
	float fine = sin(ph * 2.0 + x / mod_fine - y / (mod_fine * 1.1));
	return clamp(0.42 + 0.38 * coarse + 0.12 * fine, 0.18, 0.95);
}

void sample_layer(
	sampler2D mist_tex,
	vec2 origin,
	float ph,
	float drift_px,
	float deform,
	float mod_xx,
	float mod_yy,
	float mod_fine,
	float layer_strength,
	vec2 base_px,
	inout vec3 accum_rgb,
	inout float accum_a
) {
	vec2 mist_size = vec2(textureSize(mist_tex, 0));
	float drift = drift_px * sin(ph);
	float lx = base_px.x - origin.x - drift + deform * sin(ph + base_px.y / 55.0);
	float ly = base_px.y - origin.y + deform * 0.6 * cos(ph + base_px.x / 70.0);
	float x = floor(lx);
	float y = floor(ly);
	float inside = step(0.0, x) * step(x, mist_size.x - 1.0) * step(0.0, y) * step(y, mist_size.y - 1.0);
	if (inside < 0.5) {
		return;
	}
	vec2 mist_uv = (vec2(x, y) + vec2(0.5)) / mist_size;
	vec4 mist = texture(mist_tex, mist_uv);
	float modv = mist_mod(ph, x, y, mod_xx, mod_yy, mod_fine);
	float ca = floor(min(round(mist.a * 255.0) * modv * layer_strength, 255.0));
	float pr = muldiv255(round(mist.r * 255.0), ca);
	float pg = muldiv255(round(mist.g * 255.0), ca);
	float pb = muldiv255(round(mist.b * 255.0), ca);
	float pa = muldiv255(ca, ca);
	// Premultiplied-ish over into accum (u8 space), same order as Python composite
	float src_a = pa / 255.0;
	accum_rgb = vec3(pr, pg, pb) * src_a + accum_rgb * (1.0 - src_a);
	accum_a = pa + accum_a * (1.0 - src_a);
}

void fragment() {
	vec2 base_px = UV * base_size;
	vec2 texel = (floor(base_px) + vec2(0.5)) / base_size;
	vec4 base = texture(base_tex, texel);
	float env_s = texture(mask_envelope, texel).r;
	float path_m = texture(mask_path, texel).r;
	float cottage_m = texture(mask_cottage, texel).r;
	float bridge_m = texture(mask_bridge, texel).r;
	float semantic = path_m * cottage_m * bridge_m;
	float mask_s = mix(env_s, env_s * semantic, semantic_gate);
	float mask_u8 = round(mask_s * 255.0);

	vec3 base_u8 = round(base.rgb * 255.0);
	vec3 layer_rgb = vec3(0.0);
	float layer_a = 0.0;
	sample_layer(
		mist_far_tex, far_origin, phase, far_drift_px, far_deform,
		far_mod_xx, far_mod_yy, far_mod_fine, strength * 0.85,
		base_px, layer_rgb, layer_a
	);
	sample_layer(
		mist_near_tex, near_origin, phase + 1.7, near_drift_px, near_deform,
		near_mod_xx, near_mod_yy, near_mod_fine, strength,
		base_px, layer_rgb, layer_a
	);

	float mr = muldiv255(layer_rgb.r, mask_u8);
	float mg = muldiv255(layer_rgb.g, mask_u8);
	float mb = muldiv255(layer_rgb.b, mask_u8);
	float ma = muldiv255(layer_a, mask_u8);
	float src_a = ma / 255.0;
	vec3 masked_rgb = vec3(mr, mg, mb);
	vec3 out_u8 = floor(masked_rgb * src_a + base_u8 * (1.0 - src_a) + vec3(0.5));
	COLOR = vec4(out_u8 / 255.0, 1.0);
}
