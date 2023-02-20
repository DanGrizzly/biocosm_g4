shader_type spatial;
//fucker.tres
uniform sampler3D viewportTexture;
//uniform vec3 cameraPos;

render_mode unshaded, blend_add, depth_draw_opaque, depth_prepass_alpha,
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

vec4 DustMarch(vec3 ro, vec3 rd, float thr, float t, inout vec3 depth_point){
	float dO = 0.0;
	float dS;
	float pDist;
	float sr = 30.0;
	float gas = 0.0;
	vec4 gases = vec4(0.0);
	
	float break_point = -log(1.0-thr);
	int steps = 100;
	vec3 depth = vec3(0.0);
	
	vec2 inSects = raySphereIntersects(ro, rd, vec3(0,0,0), sr);
	
	if (length(ro) > sr){
		dO = inSects.x;
		if(dO < 0.0) return vec4(0.0);
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
		vec3 texP = p/(2.0*sr) + volOffset;
		
		float v_r = texture(viewportTexture, texP).r;
		float v_g = texture(viewportTexture, texP).g*densityDropoff;
		float v_b = texture(viewportTexture, texP).b;
		
		float v_w = v_r + v_g + v_b / 3.0;
		
		vec4 v_gases = 1.0 * vec4(v_r, v_g, v_b, v_w);
		
		gases += v_gases;
		if(gases.g > break_point){
			depth_point = p;
			break;
		}
		
		dO += dS;
	}
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
	
	float thr = 0.01;
	vec3 depth_p = vec3(0.0);
	vec4 gas_depth = DustMarch(ro, rd, thr, TIME, depth_p);
	
	vec3 main_color = normalize(vec3(0.1, 0.2, 0.6));
	
	float dust = gas_depth.g;
	vec3 dust_clr = normalize(vec3(1.0, 0.3, 0.0))/20.0;
	float alpha = min(1.0, dust);
	
	if(depth_p != vec3(0.0)){
		vec4 thing = (PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(depth_p, 1.0));
		dust_clr = normalize(vec3(1.0, 0.0, 1.0))/3.0; //The purplening
		DEPTH = (thing.z/thing.w);
	}
	
	ALBEDO = dust_clr;
	ALPHA = pow(alpha, 0.5);
	
}