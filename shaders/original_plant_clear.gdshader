shader_type canvas_item;
render_mode unshaded;
uniform sampler2D cloudy_plate : source_color, filter_linear_mipmap;
uniform vec4 sun_source_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 cloud_source_rect = vec4(0.0, 0.0, 1.0, 1.0);
// Only the independent pond patch supplies non-neutral local color matching.
uniform vec3 sun_grade = vec3(1.0, 1.0, 0.0);
uniform vec3 cloud_grade = vec3(1.0, 1.0, 0.0);
uniform float weather_mix = 0.0;
uniform vec4 sun_tint : source_color = vec4(1.0);
uniform vec4 cloud_tint : source_color = vec4(1.0);
uniform vec2 edge_points[16];
uniform int edge_count = 0;
uniform float feather = 1.25;
varying vec2 world_uv;

void vertex() {
	// Polygon coordinates stay in the original world, including photo replays.
	world_uv = VERTEX / vec2(1280.0, 720.0);
}

vec3 match_plate(vec3 color, vec3 grade) {
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	return clamp((mix(vec3(grey), color, grade.x) - vec3(0.5)) * grade.y + vec3(0.5 + grade.z), vec3(0.0), vec3(1.0));
}

void fragment() {
	vec2 point = world_uv * vec2(1280.0, 720.0);
	float distance_to_edge = 10000.0;
	for (int i = 0; i < 16; i++) {
		if (i >= edge_count) break;
		vec2 a = edge_points[i];
		vec2 b = edge_points[(i + 1) % edge_count];
		vec2 ab = b - a;
		float t = clamp(dot(point - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
		distance_to_edge = min(distance_to_edge, length(point - a - ab * t));
	}
	vec2 sun_uv = (world_uv - sun_source_rect.xy) / sun_source_rect.zw;
	vec2 cloud_uv = (world_uv - cloud_source_rect.xy) / cloud_source_rect.zw;
	vec4 sunny = texture(TEXTURE, sun_uv);
	vec4 cloudy = texture(cloudy_plate, cloud_uv);
	sunny.rgb = match_plate(sunny.rgb, sun_grade);
	cloudy.rgb = match_plate(cloudy.rgb, cloud_grade);
	sunny *= sun_tint;
	cloudy *= cloud_tint;
	vec4 plate = mix(sunny, cloudy, weather_mix);
	COLOR = vec4(plate.rgb, plate.a * smoothstep(0.0, feather, distance_to_edge));
}
