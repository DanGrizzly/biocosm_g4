shader_type spatial;

uniform sampler3D viewportTexture;
//uniform vec3 cameraPos;

render_mode unshaded, blend_add, depth_draw_opaque, 
	cull_front;

varying vec3 camerapos;
varying vec3 hitpos;
varying vec4 custom;
varying vec4 color;

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

vec3 GasesMarch(vec3 ro, vec3 rd, float t, vec3 offset, float texOffset){
	float dO = 0.0;
	float dS;
	
	float sr = 0.15;
	vec3 centerpoint = offset;
	
	vec3 gases = vec3(0.0);
	
	int steps_gas = 20;
	int steps_light = 5;

	vec2 inSects = raySphereIntersects(ro, rd, centerpoint, sr);
	
	if (length(ro - offset) > sr){
		dO = inSects.x;
		if(dO < 0.0) return vec3(0.0);
		dS = (inSects.y - inSects.x) / float(steps_gas);
	}else{
		dS = inSects.y / float(steps_gas);
	}
	
	for(int i=0; i < steps_gas; i++){
		vec3 p = ro + rd * dO;
		
		//Gas density dropoff function, closer to the ball edge	
		float densityDropoff = (1.0 - length(p - offset)/sr);
		
		//Centering offset for non-repeating Volume Texture
		float texSeedOffset = texOffset;
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = (p - offset)/(sr*3.0) + volOffset;
		texP.x /= 64.0;
		texP += vec3((1.0 - 1.0/64.0)*texSeedOffset, 0.0, 0.0);
		
		float v_r = texture(viewportTexture, texP).r;//*texture(viewportTexture, texP).g;
		float v_g = texture(viewportTexture, texP).g;
		float v_b = texture(viewportTexture, texP).b;
		
		float blockage = 0.0;
		vec3 rd_light = normalize(centerpoint - p);
		float dO_light = 0.0;
		float dS_light = distance(centerpoint, p)/float(steps_light);
		for(int j=0; j < steps_light; j++){
			vec3 p_light = p + rd_light * dO_light;
			vec3 texP_light = (p_light - offset)/(sr*3.0) + volOffset;
			texP_light.x /= 64.0;
			texP_light += vec3((1.0 - 1.0/64.0)*texSeedOffset, 0.0, 0.0);
			blockage += texture(viewportTexture, texP_light).r*dS_light;
			dO_light += dS_light;
		}
		
		vec3 v_gases = vec3(v_r, v_g, v_b) * densityDropoff * densityDropoff;
		v_gases.r = 5.0* v_r * densityDropoff * densityDropoff; //max(0.0, v_gases.r - blockage);
		v_gases.g = blockage;
		
		if((length(p - offset) < sr)){
			gases += v_gases;
		}
		
		dO += dS;
	}
	gases.r = (1.0 - 1.0/exp(gases.r)) - (1.0 - 1.0/exp(gases.g));
	gases.g = (1.0 - 1.0/exp(gases.g));
	return gases;
}


void vertex(){
	camerapos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	hitpos = VERTEX + INSTANCE_CUSTOM.xyz; /// WHY THE F*** DOES ADDING IT HERE MAKE IT WORK????????
	custom = INSTANCE_CUSTOM;
	color = COLOR;
    //VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
	vec3 ro = (inverse(MODEL_MATRIX) * vec4(camerapos, 1.0)).xyz; 
	//ro = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
	//ro = (INV_VIEW_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
	ro = camerapos;
	vec3 world_hitpos = (MODEL_MATRIX * vec4(hitpos, 1.0)).xyz;
	vec3 rd = normalize(world_hitpos - ro);
	
	vec3 gases = GasesMarch(ro, rd, TIME, custom.xyz, color.w);
	
	vec3 star_col = color.xyz;
	vec3 rayleigh = vec3(0.05, 0.1, 1.00);
	vec3 shifted_col = mix(star_col, rayleigh, sqrt(gases.g));
	vec3 ref_color = shifted_col*gases.r;
	
	ALBEDO = ref_color;
	ALPHA = min(1.0, gases.r);
	
}