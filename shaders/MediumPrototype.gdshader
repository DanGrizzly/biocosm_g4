shader_type spatial;

uniform sampler3D mediumTexture;

render_mode unshaded, blend_add, depth_draw_never, 
	cull_front, skip_vertex_transform;

varying vec3 hitpos;

vec2 raySphereIntersects(vec3 r0, vec3 rd, vec3 s0, float sr){
	//r0 - ray origin //rd - ray direction //s0 -sphere origin
	//sr - sphere radius //returns both intersects, -1 if none
	float a = dot(rd, rd);
	vec3 s0_r0 = r0 - s0;
	float b = 2.0 * dot(rd, s0_r0);
	float c = dot(s0_r0, s0_r0) - (sr * sr);
	if (b*b - 4.0*a*c < 0.0) {
	    return vec2(-1.0, -1.0);
    }
	float thing = sqrt((b*b) - 4.0*a*c);
	return vec2 ((-b - thing)/(2.0*a) ,  (-b + thing)/(2.0*a));
}

float FogMarch(vec3 ro, vec3 rd, float t){
	float dO = 0.0;
	float dS;
	float sr = 30.0;
	float fog = 0.0;
	
	int steps = 10;
	
	vec2 inSects = raySphereIntersects(ro, rd, vec3(0,0,0), sr);
	if (length(ro) > sr){
		dO = inSects.x;
		if(dO < 0.0) return 0.0;
		dS = (inSects.y - inSects.x) / float(steps);
	}else dS = inSects.y / float(steps);
	
	for(int i=0; i < steps; i++){
		vec3 p = ro + rd * dO;
		float pDist = length(p);
		
		//Gas density dropoff function, closer to the ball edge	
		float densityDropoff = (1.0 - pDist/sr);
		
		//Centering offset for non-repeating Volume Texture
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = p*1.0 + volOffset;
		
		//float pv = texture(viewportTexture, texP).r;
		float pv = 0.05;
		float v = 0.5 * pv * densityDropoff;
		
		if((length(p) < sr)){
			fog += max(0, v);
		}
		if (fog > 2.0) break;
		dO += dS;
	}
	fog = (1.0 - 1.0/exp(fog/3.0));
	return fog;
}


void vertex(){
	hitpos = VERTEX;
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
	vec3 ro = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(vec3(0), 1.0)).xyz;
	vec3 rd = normalize(hitpos - ro);
	
	float fog;
	vec3 color = vec3(0.2, 0.05, 0.25);
	fog = FogMarch(ro, rd, TIME);
	
	//ALBEDO = vec3(1.0, 0.0, 0.0);
	//ALPHA = min(1.0, sampleTest);
	
	ALBEDO = color;
	ALPHA = min(0.3, fog);
	
}