shader_type canvas_item;
// # 与 generate_mist_density_anim.py 同一套双层雾体变换。
// # 远/近两层手绘薄雾 + 整数谐波浓淡（1× 大团、2× 细团）+ 漂移/抬升 + 微形变。
// # 覆盖度只与包络相乘一次。前景小路/木屋屋顶/桥与纸边由 envelope 保护。

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
uniform vec2 far_origin = vec2(70.0, 220.0);
uniform vec2 near_origin = vec2(160.0, 300.0);
uniform float far_drift_px = 150.0;
uniform float near_drift_px = -120.0;
uniform float far_lift_px = 48.0;
uniform float near_lift_px = 62.0;
uniform float far_deform = 22.0;
uniform float near_deform = 30.0;
uniform float far_mod_xx = 230.0;
uniform float far_mod_yy = 160.0;
uniform float far_mod_fine = 92.0;
uniform float near_mod_xx = 145.0;
uniform float near_mod_yy = 110.0;
uniform float near_mod_fine = 60.0;
uniform float ca_cap = 170.0;
// # 与生成脚本 DEFORM_* / NEAR_PHASE / FAR_STRENGTH 相同，不单独在场景里再改一套。
const float DEFORM_X_PERIOD = 160.0;
const float DEFORM_Y_PERIOD = 300.0;
const float NEAR_PHASE = 2.1;
const float FAR_STRENGTH = 0.90;

float muldiv255(float a, float b) {
	float t = a * b + 128.0;
	return floor((floor(t / 256.0) + t) / 256.0);
}

float mist_mod(float ph, float x, float y, float mod_xx, float mod_yy, float mod_fine) {
	// # 整数谐波：半频 cos(ph*0.5) 在 2π 处会跳，不能用。
	float bank = sin(ph + x / mod_xx + y / (mod_yy * 1.7));
	float wisp = sin(ph * 2.0 - x / mod_fine + y / mod_yy);
	return clamp(0.12 + 0.58 * bank + 0.30 * wisp, 0.02, 1.0);
}

void sample_layer(
	sampler2D mist_tex,
	vec2 origin,
	float ph,
	float drift_px,
	float lift_px,
	float deform,
	float mod_xx,
	float mod_yy,
	float mod_fine,
	float layer_strength,
	float mask_u8,
	vec2 base_px,
	inout vec3 base_u8
) {
	vec2 mist_size = vec2(textureSize(mist_tex, 0));
	float drift = drift_px * sin(ph);
	float lift = lift_px * (1.0 - cos(ph)) * 0.5;
	float lx = base_px.x - origin.x - drift + deform * 0.55 * sin(ph * 2.0 + base_px.y / DEFORM_X_PERIOD);
	float ly = base_px.y - origin.y - lift + deform * cos(ph + base_px.x / DEFORM_Y_PERIOD);
	float x = floor(lx);
	float y = floor(ly);
	float inside = step(0.0, x) * step(x, mist_size.x - 1.0) * step(0.0, y) * step(y, mist_size.y - 1.0);
	if (inside < 0.5) {
		return;
	}
	vec2 mist_uv = (vec2(x, y) + vec2(0.5)) / mist_size;
	vec4 mist = texture(mist_tex, mist_uv);
	float modv = mist_mod(ph, x, y, mod_xx, mod_yy, mod_fine);
	float ca = min(floor(round(mist.a * 255.0) * modv * layer_strength), ca_cap);
	// # 直线色 + 一次包络覆盖，与 Python composite_frame 相同
	float cov = muldiv255(ca, mask_u8) / 255.0;
	vec3 src = vec3(round(mist.r * 255.0), round(mist.g * 255.0), round(mist.b * 255.0));
	base_u8 = src * cov + base_u8 * (1.0 - cov);
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
	sample_layer(
		mist_far_tex, far_origin, phase, far_drift_px, far_lift_px, far_deform,
		far_mod_xx, far_mod_yy, far_mod_fine, strength * FAR_STRENGTH,
		mask_u8, base_px, base_u8
	);
	sample_layer(
		mist_near_tex, near_origin, phase + NEAR_PHASE, near_drift_px, near_lift_px, near_deform,
		near_mod_xx, near_mod_yy, near_mod_fine, strength,
		mask_u8, base_px, base_u8
	);

	vec3 out_u8 = clamp(floor(base_u8 + vec3(0.5)), vec3(0.0), vec3(255.0));
	COLOR = vec4(out_u8 / 255.0, 1.0);
}
