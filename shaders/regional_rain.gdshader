shader_type canvas_item;
render_mode unshaded;
uniform float rain_clock = 0.0;
uniform float amount = 0.0;
uniform bool reduced_motion = false;
uniform bool surface_only = false;
uniform bool with_pond = true;
varying vec2 point;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453); }
void vertex() { point = VERTEX; }
void fragment() {
	float alpha = 0.0;
	if (surface_only) {
		// Conservative ellipse lies inside the painted shoreline; no rings on land.
		vec2 water = (point-vec2(705.0,592.0))/vec2(132.0,39.0);
		if (with_pond && dot(water,water) < 1.0) {
			vec2 p = point/vec2(29.0,13.0);
			vec2 cell = floor(p);
			float phase = fract(rain_clock*0.75+hash(cell));
			vec2 center = vec2(0.25+hash(cell+2.0)*0.5,0.25+hash(cell+8.0)*0.5);
			float radius = 0.04+phase*0.36;
			float ring = 1.0-smoothstep(0.012,0.045,abs(length(fract(p)-center)-radius));
			alpha = ring*(1.0-phase)*0.55*(1.0-smoothstep(0.84,1.0,dot(water,water)));
		}
	} else {
		vec2 p = vec2(point.x+point.y*0.16, point.y-rain_clock*240.0);
		vec2 cell = floor(p/vec2(37.0,92.0));
		vec2 local = fract(p/vec2(37.0,92.0));
		float x = 0.15+hash(vec2(cell.x,0.0))*0.7;
		float y = hash(cell)*0.76;
		float stroke = (1.0-smoothstep(0.009,0.027,abs(local.x-x)))*smoothstep(y,y+0.035,local.y)*(1.0-smoothstep(y+0.11,y+0.14,local.y));
		float density = step(reduced_motion ? 0.90 : 0.36,hash(cell+17.0));
		alpha = stroke*density*0.36;
	}
	COLOR = vec4(0.77,0.86,0.92,alpha*amount);
}
