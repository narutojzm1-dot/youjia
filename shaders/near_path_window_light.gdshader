shader_type canvas_item;
render_mode unshaded;

uniform sampler2D pane_mask : filter_linear, repeat_disable;
uniform vec2 source_size;
uniform vec4 pane_bounds;
uniform float amount = 0.0;
varying vec4 light_modulate;

void vertex() {
    light_modulate = COLOR;
}

void fragment() {
    vec2 at = (UV * source_size - pane_bounds.xy) / pane_bounds.zw;
    float pane = 0.0;
    if (all(greaterThanEqual(at, vec2(0.0))) && all(lessThanEqual(at, vec2(1.0)))) {
        pane = texture(pane_mask, at).r;
    }
    vec3 paint = texture(TEXTURE, UV).rgb;
    // Retain the small painted variations; the frames and boxes are unmasked.
    vec3 warm = vec3(1.0, 0.68, 0.24) * (0.78 + 0.22 * paint.g);
    COLOR = vec4(warm * light_modulate.rgb, pane * amount * 0.62 * light_modulate.a);
}
