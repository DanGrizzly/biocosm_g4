shader_type spatial;

render_mode blend_add, unshaded, skip_vertex_transform, cull_disabled;

varying vec4 custom;

float noise3to1(in vec3 p) {
  const mat3 m = mat3(
	vec3(1.0, 0.0, 0.0),
	vec3(0.5, 1.2, 0.0),
	vec3(0.0, 0.0, 1.0));
  vec3 s = m * p;

  return sin(s.x) * sin(s.y) * sin(s.z);
}

vec3 noise3to3(in vec3 p) {
  return vec3(
    noise3to1(p.xyz + vec3(1, 2, 3) * vec3(0.9, 0.7, 1.3)),
    noise3to1(p.zyx + vec3(7, 9, 8) * vec3(0.5, 1.2, 1.1)),
    noise3to1(p.yxz + vec3(3, 2, 5) * vec3(0.8, 0.3, 1.5)));
}

vec3 brown(in vec3 p) {
  return 0.5 * noise3to3(p) + 0.2 * noise3to3(p * 3.0) + 0.1 * noise3to3(p * 5.0);

}

vec3 grey(in vec3 p) {
  return brown(brown(p * 0.1) * 5.0);
}

vec2 rot(vec2 inp, float angle){
	vec2 input = inp - vec2(0.5);
	float c = cos(angle*PI/180.0);
	float s = sin(angle*PI/180.0);
	
	return vec2(input.x*c - input.y*s, input.x*s + input.y*c);
}

void vertex() {
	VERTEX = (MODELVIEW_MATRIX*vec4(VERTEX,1.0)).xyz;

	custom = INSTANCE_CUSTOM;
}


void fragment() {
	vec2 base_uv = UV; //ABECEDA
	
	float scale = 0.6;
	
	float dist = clamp(length(UV * 2.0 - 1.0), 0.0, 1.0);
	if(dist>scale){
		discard;
	}
	float noisedisc = length(grey(vec3(rot(UV, TIME*7.0) * 5000.0, 60.0) * 0.02));
	float thing = (custom.x/1.5 + 0.33) * noisedisc;
	
	float pattern1 = cos(dist*PI*(5.0+custom.y*20.0))/1.6;
	float pattern2 = sin(dist*PI*(15.0+custom.z*10.0))/1.6;
	
	float tint = custom.w;
	float dropoff = 1.0/(0.4+dist)*pow(1.0-dist, 2.0);
	float pattern = (0.5+pattern1*pattern2+thing);
	
	vec3 color = dropoff*pattern*vec3(1.0,0.4,0.05);
	
	ALBEDO = pow(color, vec3(2.2 + tint));
	ALPHA = 1.0;
}
