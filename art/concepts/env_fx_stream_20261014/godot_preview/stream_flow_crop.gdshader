shader_type canvas_item;
// # #749 溪流候选的裁切版：挂在 183×302 溪床子层上，不是整幅四边形。仍只是候选。
// # 节点自身的 texture 是裁切后的 flow_map（只决定四边形大小与 UV）；UV 0→1 覆盖裁切矩形。
// # 控制图全部是同一矩形的裁切版；底图仍采样原整幅 near_path，用 crop_origin 对齐。
// # 水面算法与 stream_flow.gdshader 逐行相同。区别只在：
// #   1. 采样坐标先加 crop_origin 再按整幅算，控制图再减回去；
// #   2. 不在水面上的像素、以及 strength == 0 时，输出透明，下面的原画原样露出来。
// #      所以保护区和 0 强度时与原画逐像素一致，不依赖本层的采样方式。
// # 与 stream_flow.gdshader 同一套溪流。phase 是弧度 0→TAU，不是归一化 0→1。
// # 线性过滤：Painting 与 StreamCrop 子层 Sprite2D.texture_filter = TEXTURE_FILTER_LINEAR（2），
// # base_tex 使用 filter_linear，匹配宿主 near_path_scroll.gd 的 painting.texture_filter = TEXTURE_FILTER_LINEAR。
// # ripple_tile / water_detail 保持 filter_linear；控制图 flow_map / coord_sn / secondary_* 保持 filter_nearest。
// # 缩放由宿主 Sprite2D.scale 驱动，shader 采样仍按裁切像素坐标，不随 scale 改变逻辑。

uniform sampler2D base_tex : filter_linear, repeat_disable;
uniform sampler2D flow_map : filter_nearest, repeat_disable;
uniform sampler2D coord_sn : filter_nearest, repeat_disable;
uniform sampler2D ripple_tile : filter_linear, repeat_enable;
uniform sampler2D water_detail : filter_linear, repeat_disable;
// # phase 是弧度 0→TAU，不是归一化 0→1。
uniform float phase = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform vec2 base_size = vec2(1672.0, 941.0);
uniform vec2 crop_origin = vec2(191.0, 543.0);
uniform vec2 crop_size = vec2(183.0, 302.0);
// # 可选（默认关，保持已复核算法）：底图按连续 UV 线性取样，与宿主线性过滤的 Painting 对齐；
// # 控制图仍按纹素中心 nearest。仅供缩放对照，是否启用待 Leader 定。
uniform bool base_sample_linear = false;
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
	vec2 local_px = UV * crop_size;
	vec2 local_texel = (floor(local_px) + vec2(0.5)) / crop_size;
	vec2 base_px = local_px + crop_origin;
	vec2 texel = (floor(base_px) + vec2(0.5)) / base_size;
	vec4 base = base_sample_linear ? texture(base_tex, base_px / base_size) : texture(base_tex, texel);
	vec4 flow = texture(flow_map, local_texel);
	vec4 sn = texture(coord_sn, local_texel);
	vec3 sw = texture(secondary_weight, local_texel).rgb;
	float mask = flow.a;
	bool water = mask > 0.0 || (sw.r + sw.g + sw.b) > 0.0;
	// # 保护区或 0 强度：整层透明，露出下面的原画。
	if (!water || strength <= 0.0) {
		COLOR = vec4(0.0);
	} else {
	float density = flow.b;
	vec2 dir = flow.rg * 2.0 - vec2(1.0);
	float p0 = fract(phase / TAU);
	float p1 = fract(p0 + 0.5);
	float weight = abs(p0 - 0.5) * 2.0;

	vec3 rgb = round(base.rgb * 255.0);
	if (mask > 0.0) {
		float u = sn.r;
		float v = clamp(sn.g, 0.001, 0.999);
		float rip = texture(ripple_tile, vec2(fract(u - p0), v)).r;
		float centered = (rip - 0.5) * 2.0;

		vec3 local = decode_detail(texture(water_detail, local_texel).rgb);
		// # 位移仍按整幅像素算（与整幅版一致），再换回裁切图坐标；外扩 16 px 大于最大位移 12 px。
		vec2 src0 = base_px - dir * p0 * advect_travel_px;
		vec2 src1 = base_px - dir * p1 * advect_travel_px;
		vec3 hp0 = decode_detail(texture(water_detail, (src0 - crop_origin) / crop_size).rgb);
		vec3 hp1 = decode_detail(texture(water_detail, (src1 - crop_origin) / crop_size).rgb);
		vec3 hp = mix(hp0, hp1, weight);
		vec3 shift = clamp(hp - local, vec3(-advect_clamp), vec3(advect_clamp));

		float m = mask * strength;
		float amp = ripple_amp * density * m;
		float pos = clamp(centered, 0.0, 1.0);
		float neg = clamp(-centered, 0.0, 1.0);
		rgb += shift * (m * advect_gain);
		rgb += pos * amp * POS_TINT + neg * amp * NEG_TINT;
	}

	vec3 main_u8 = clamp(floor(rgb + vec3(0.5)), vec3(0.0), vec3(255.0));
	if ((sw.r + sw.g + sw.b) > 0.0) {
		vec3 sec = texture(secondary_map, local_texel).rgb;
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
}
