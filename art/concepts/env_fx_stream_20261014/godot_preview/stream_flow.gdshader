shader_type canvas_item;
// # 与 generate_stream_flow_anim.py 同一套溪流双相位。
// # 流向贴图 RG 驱动水纹和短距离笔触；沿弧长往下游走，不是左右来回推 UV。
// # 权重在某一层回绕时把它藏起来，减轻拉长和循环跳变。岸、桥、石、纸边蒙版为 0。

uniform sampler2D base_tex : filter_nearest, repeat_disable;
uniform sampler2D flow_map : filter_nearest, repeat_disable;
uniform sampler2D coord_sn : filter_nearest, repeat_disable;
uniform sampler2D ripple_tile : filter_linear, repeat_enable;
uniform sampler2D water_detail : filter_linear, repeat_disable;
uniform float phase = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform vec2 base_size = vec2(1672.0, 941.0);
uniform float advect_travel_px = 12.0;
uniform float ripple_amp = 46.0;
uniform float advect_gain = 0.50;
uniform float advect_clamp = 8.0;
uniform float detail_scale = 48.0;

const vec3 POS_TINT = vec3(1.02, 0.98, 0.62);
const vec3 NEG_TINT = vec3(-0.62, -0.48, -0.22);

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
		float ra = texture(ripple_tile, vec2(fract(u - p0), v)).r;
		float rb = texture(ripple_tile, vec2(fract(u - p1), v)).g;
		float rip = mix(ra, rb, weight);
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

	vec3 out_u8 = clamp(floor(rgb + vec3(0.5)), vec3(0.0), vec3(255.0));
	COLOR = vec4(out_u8 / 255.0, 1.0);
}
