shader_type spatial;
//fucker.tres
uniform sampler3D viewportTexture;
//uniform vec3 cameraPos;

render_mode unshaded, blend_add, depth_draw_opaque, 
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

float SampleMarch(vec3 ro, vec3 rd, float t, out vec3 gases){
	float dO = 0.0;
	float dS;
	float pDist;
	float sr = 0.5;
	float gas = 0.0;
	
	int steps = 50;
	
	vec2 inSects = raySphereIntersects(ro, rd, vec3(0,0,0), sr);
	
	if (length(ro) > sr){
		dO = inSects.x;
		if(dO < 0.0) return 0.0;
		dS = (inSects.y - inSects.x) / float(steps);
	}else{
		dS = inSects.y / float(steps);
	}
	for(int i=0; i < steps; i++){
		vec3 p = ro + rd * dO;
		pDist = length(p);
		
		//Gas density dropoff function, closer to the ball edge	
		float densityDropoff = (1.0 - pDist/sr);
		
		//Centering offset for non-repeating Volume Texture
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = p*1.0 + volOffset;
		
		float pv = texture(viewportTexture, texP).r;
		
		float v_r = texture(viewportTexture, texP).r;
		float v_g = texture(viewportTexture, texP).g * v_r;
		float v_b = texture(viewportTexture, texP).b* v_r;
		
		vec3 v_gases = 0.5 * vec3(v_r, v_g, v_b) * densityDropoff * densityDropoff;
		
		float v = 0.5 * pv * densityDropoff;
		
		if((length(p) < sr)){
			gas += max(0, v);
			gases += v_gases;
		}
		if (gas > 2.0) break;
		dO += dS;
	}
	gas = (1.0 - 1.0/exp(gas));
	gases = (1.0 - 1.0/exp(gases));
	return gas;
}
vec3 GasesMarch(vec3 ro, vec3 rd, float t){
	float dO = 0.0;
	float dS;
	float pDist;
	float sr = 0.5;
	float gas = 0.0;
	vec3 gases = vec3(0.0);
	
	int steps = 50;
	
	vec2 inSects = raySphereIntersects(ro, rd, vec3(0,0,0), sr);
	
	if (length(ro) > sr){
		dO = inSects.x;
		if(dO < 0.0) return vec3(0.0);
		dS = (inSects.y - inSects.x) / float(steps);
	}else{
		dS = inSects.y / float(steps);
	}
	for(int i=0; i < steps; i++){
		vec3 p = ro + rd * dO;
		pDist = length(p);
		
		//Gas density dropoff function, closer to the ball edge	
		float densityDropoff = (1.0 - pDist/sr);
		
		//Centering offset for non-repeating Volume Texture
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = p*1.0 + volOffset;
		
		float pv = texture(viewportTexture, texP).r;
		
		float v_r = texture(viewportTexture, texP).r;
		float v_g = texture(viewportTexture, texP).g * densityDropoff;
		float v_b = texture(viewportTexture, texP).b * v_r;
		
		vec3 v_gases = 0.5 * vec3(v_r, v_g, v_b) * densityDropoff * densityDropoff;
		
		float v = 0.5 * pv * densityDropoff;
		
		if((length(p) < sr)){
			gas += max(0, v);
			gases += v_gases;
		}
		if (gas > 2.0) break;
		dO += dS;
	}
	gas = (1.0 - 1.0/exp(gas));
	gases = (1.0 - 1.0/exp(gases));
	return gases;
}


void vertex(){
	hitpos = VERTEX;
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
	vec3 ro = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(vec3(0), 1.0)).xyz;
	vec3 rd = normalize(hitpos - ro);
	
	float sampleTest;
	vec3 gases;
	
	//sampleTest = SampleMarch(ro, rd, TIME, gases);
	gases = GasesMarch(ro, rd, TIME);
	//if(sampleTest < 0.0001) discard;
	
	//ALBEDO = vec3(1.0, 0.0, 0.0);
	//ALPHA = min(1.0, sampleTest);
	
	vec3 r = vec3(1.0, 0.01, 0.05);
	vec3 g = vec3(0.0, 0.8, 0.9);
	vec3 b = vec3(0.0, 0.0, 1.0);
	vec3 colormix = ( r*gases.r + g*gases.g + b*gases.b )/2.0;
	
	ALBEDO = colormix;
	ALPHA = min(1.0, length(colormix));
	
}