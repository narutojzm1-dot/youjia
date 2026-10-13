shader_type canvas_item;
uniform sampler2D base_tex : filter_linear;
uniform sampler2D cloud_tex : filter_linear;
uniform sampler2D mask_tex : filter_linear;
uniform float phase : hint_range(0.0, 6.283185, 0.01) = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 0.7;
uniform bool low_motion = false;
void fragment() {
    vec4 base = texture(base_tex, UV);
    vec4 cloud = texture(cloud_tex, UV);
    float m = texture(mask_tex, UV).r;
    float p = low_motion ? 0.0 : phase;
    float modu = 0.4 + 0.5 * sin(p + UV.x * 40.0 + UV.y * 30.0) * cos(p + UV.y * 25.0);
    modu = clamp(modu, 0.15, 1.0);
    cloud.a *= modu * strength * m;
    COLOR = mix(base, cloud, cloud.a);
}
