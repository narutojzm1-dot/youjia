shader_type canvas_item;
// # 与 generate_stream_flow_anim.py 同一套溪流。
// # 水纹贴图横向一圈才重复，phase 直接沿弧长往下游平移。
// # 笔触仍是双相位：非循环细节回绕时把那一层权重藏起来。岸、桥、石、纸边蒙版为 0。
// # 不要把水纹也差半圈混在一起。偶数谐波贴图配半圈偏移会采到同一个纹素，亮带不动。
// # 宽水面另加次级层：横纹、侧流、涡流。权重贴图为 0 的像素不加，主下游切线不动。

uniform sampler2D base_tex : filter_nearest, repeat_disable;
uniform sampler2D flow_map : filter_nearest, repeat_disable;
uniform sampler2D coord_sn : filter_nearest, repeat_disable;
uniform sampler2D ripple_tile : filter_linear, repeat_enable;
uniform sampler2D water_detail : filter_linear, repeat_disable;
// # phase 是弧度 0→TAU，不是归一化 0→1。
uniform float phase = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform vec2 base_size = vec2(1672.0, 941.0);
uniform float advect_travel_px = 12.0;
uniform float ripple_amp = 118.0;
uniform float advect_gain = 0.50;
uniform float advect_clamp = 8.0;
uniform float detail_scale = 48.0;
uniform sampler2D secondary_map : filter_nearest, repeat_disable;
uniform sampler2D secondary_weight : filter_nearest, repeat_disable;
uniform float cross_amp = 112.0;
uniform float side_amp = 148.0;
uniform float eddy_amp = 132.0;
uniform float secondary_clamp = 84.0;

const vec3 POS_TINT = vec3(1.02, 0.98, 0.62);
const vec3 NEG_TINT = vec3(-0.62, -0.48, -0.22);
const vec3 SEC_POS_TINT = vec3(0.74, 0.82, 0.60);
const vec3 SEC_NEG_TINT = vec3(-0.50, -0.64, -0.76);

float _bump(float u, float center, float sigma) {
	float du = abs(u - center);
	du = min(du, 1.0 - du);
	return exp(-0.5 * pow(du / sigma, 2.0));
}

float _signed_wave(float raw, float baseline) {
	float wave = raw - baseline;
	return wave >= 0.0 ? wave * 0.75 : wave * 1.08;
}

float _wrap_half(float value) {
	return fract(value + 0.5) - 0.5;
}

vec3 decode_detail(vec3 enc) {
	return (enc - vec3(0.5)) * (detail_scale * 2.0);
}

void fragment() {
	vec2 base_px = UV * base_size;
	vec2 texel = (floor(base_px) + vec2(0.5)) / base_size;
	vec4 base = texture(base_tex, texel);
	vec4 flow = texture(flow_map, texel);
	vec4 sn = texture(coord_sn, texel);
	float mask = flow.a;
	float density = flow.b;
	vec2 dir = flow.rg * 2.0 - vec2(1.0);
	float p0 = fract(phase / TAU);
	float p1 = fract(p0 + 0.5);
	float weight = abs(p0 - 0.5) * 2.0;

	vec3 rgb = round(base.rgb * 255.0);
	// # 保护区蒙版是 0，直接输出原像素，不参与水纹。
	if (mask > 0.0) {
		float u = sn.r;
		float v = clamp(sn.g, 0.001, 0.999);
		// # 贴图自身循环，用 p0 平移。p1/weight 只给下面的笔触。
		float rip = texture(ripple_tile, vec2(fract(u - p0), v)).r;
		float centered = (rip - 0.5) * 2.0;

		vec3 local = decode_detail(texture(water_detail, texel).rgb);
		vec2 src0 = base_px - dir * p0 * advect_travel_px;
		vec2 src1 = base_px - dir * p1 * advect_travel_px;
		vec3 hp0 = decode_detail(texture(water_detail, src0 / base_size).rgb);
		vec3 hp1 = decode_detail(texture(water_detail, src1 / base_size).rgb);
		vec3 hp = mix(hp0, hp1, weight);
		vec3 shift = clamp(hp - local, vec3(-advect_clamp), vec3(advect_clamp));

		float m = mask * strength;
		float amp = ripple_amp * density * m;
		float pos = clamp(centered, 0.0, 1.0);
		float neg = clamp(-centered, 0.0, 1.0);
		rgb += shift * (m * advect_gain);
		rgb += pos * amp * POS_TINT + neg * amp * NEG_TINT;
	}

	// # 主水流先落成 8-bit，再在宽水面上加次级层，和生成脚本的两段舍入一致。
	vec3 main_u8 = clamp(floor(rgb + vec3(0.5)), vec3(0.0), vec3(255.0));
	vec3 sw = texture(secondary_weight, texel).rgb;
	if (strength > 0.0 && (sw.r + sw.g + sw.b) > 0.0) {
		vec3 sec = texture(secondary_map, texel).rgb;
		float u_cross = fract(sec.r - p0);
		float u_side = fract(sec.g - p0);
		float cross_raw = _bump(u_cross, 0.18, 0.16) + _bump(u_cross, 0.62, 0.09);
		float side_raw = _bump(u_side, 0.22, 0.075) + _bump(u_side, 0.67, 0.060);
		float turn = _wrap_half(sec.b - p0);
		float turn_opposite = _wrap_half(turn + 0.5);
		float arm = exp(-0.5 * pow(turn / 0.11, 2.0));
		arm += 0.58 * exp(-0.5 * pow(turn_opposite / 0.11, 2.0));
		float delta = _signed_wave(cross_raw, 0.42) * cross_amp * sw.r;
		delta += _signed_wave(side_raw, 0.40) * side_amp * sw.g;
		delta += _signed_wave(arm, 0.46) * eddy_amp * sw.b;
		delta = clamp(delta, -secondary_clamp, secondary_clamp) * strength;
		float spos = max(delta, 0.0);
		float sneg = max(-delta, 0.0);
		main_u8 += spos * SEC_POS_TINT + sneg * SEC_NEG_TINT;
	}

	vec3 out_u8 = clamp(floor(main_u8 + vec3(0.5)), vec3(0.0), vec3(255.0));
	COLOR = vec4(out_u8 / 255.0, 1.0);
}
