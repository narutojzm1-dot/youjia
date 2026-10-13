shader_type canvas_item;
// # 与 generate_cloud_density_anim.py 同一套云层变换。
// # 云图是 cloud_candidate 的 LANCZOS 1.8 倍结果，贴在底图 (180, 30)。
// # 调制用缩放后云图的像素坐标 xx/70、yy/50、yy/90，不用整幅 UV。
// # 合成遮罩 = 高斯模糊(天空渐变 × 屋顶 × 雪峰 × 树冠)，白色允许云，黑色保护。

uniform sampler2D base_tex : filter_nearest, repeat_disable;
uniform sampler2D cloud_tex : filter_nearest, repeat_disable;
uniform sampler2D mask_combined : filter_nearest, repeat_disable;
uniform sampler2D mask_roof : filter_nearest, repeat_disable;
uniform sampler2D mask_snow : filter_nearest, repeat_disable;
uniform sampler2D mask_canopy : filter_nearest, repeat_disable;
uniform float phase = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
// # 0 = 只用合成遮罩（与 PNG 一致）。1 = 再乘屋顶/雪峰/树冠硬边。
uniform float semantic_gate : hint_range(0.0, 1.0) = 0.0;
uniform vec2 base_size = vec2(1920.0, 1080.0);
uniform vec2 cloud_origin = vec2(180.0, 30.0);
uniform float mod_xx = 70.0;
uniform float mod_yy_sin = 50.0;
uniform float mod_yy_cos = 90.0;

// # PIL 8 位乘除：((a*b+128)>>8 + (a*b+128))>>8
float muldiv255(float a, float b) {
	float t = a * b + 128.0;
	return floor((floor(t / 256.0) + t) / 256.0);
}

void fragment() {
	// # UV 映射到底图像素。取像素中心，和 PNG 的整数像素对齐。
	vec2 base_px = UV * base_size;
	vec2 texel = (floor(base_px) + vec2(0.5)) / base_size;
	vec4 base = texture(base_tex, texel);
	float roof_m = texture(mask_roof, texel).r;
	float snow_m = texture(mask_snow, texel).r;
	float canopy_m = texture(mask_canopy, texel).r;
	float combined_s = texture(mask_combined, texel).r;
	// # 三张语义遮罩始终采样，场景里已经绑定。默认不重复相乘，避免削掉模糊渗边。
	float semantic = roof_m * snow_m * canopy_m;
	float mask_s = mix(combined_s, combined_s * semantic, semantic_gate);
	float mask_u8 = round(mask_s * 255.0);

	vec3 base_u8 = round(base.rgb * 255.0);
	vec2 cloud_size = vec2(textureSize(cloud_tex, 0));
	vec2 local = base_px - cloud_origin;
	float x = floor(local.x);
	float y = floor(local.y);
	float inside = step(0.0, x) * step(x, cloud_size.x - 1.0) * step(0.0, y) * step(y, cloud_size.y - 1.0);
	vec3 out_u8 = base_u8;
	if (inside > 0.5) {
		vec2 cloud_uv = (vec2(x, y) + vec2(0.5)) / cloud_size;
		vec4 cloud = texture(cloud_tex, cloud_uv);
		// # 与脚本 cloud_modulation 相同，周期在 phase 的 π（视觉上 0→2π 走两圈）。
		float modv = 0.4 + 0.5 * sin(phase + x / mod_xx + y / mod_yy_sin) * cos(phase + y / mod_yy_cos);
		modv = clamp(modv, 0.15, 1.0);
		float ca = floor(min(round(cloud.a * 255.0) * modv * strength, 255.0));
		// # 生成脚本 paste(cloud, pos, cloud)：RGB 与 alpha 先各乘一次云的 alpha。
		float pr = muldiv255(round(cloud.r * 255.0), ca);
		float pg = muldiv255(round(cloud.g * 255.0), ca);
		float pb = muldiv255(round(cloud.b * 255.0), ca);
		float pa = muldiv255(ca, ca);
		float mr = muldiv255(pr, mask_u8);
		float mg = muldiv255(pg, mask_u8);
		float mb = muldiv255(pb, mask_u8);
		float ma = muldiv255(pa, mask_u8);
		float src_a = ma / 255.0;
		vec3 masked_rgb = vec3(mr, mg, mb);
		// # 与 PIL：composite 先按遮罩缩放 RGB/A，alpha_composite 再按直通道 over。
		out_u8 = floor(masked_rgb * src_a + base_u8 * (1.0 - src_a) + vec3(0.5));
	}
	COLOR = vec4(out_u8 / 255.0, 1.0);
}
