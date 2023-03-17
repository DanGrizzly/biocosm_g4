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

vec3 GasesMarch(vec3 ro, vec3 rd, float t, vec3 offset, float texOffset, float size){
	float dO = 0.0;
	float dS;
	
	float sr = 0.5*(size+0.5)/1.5;
	
	vec3 gases = vec3(0.0);
	
	int steps = 100;
	
	vec2 inSects = raySphereIntersects(ro, rd, vec3(0,0,0) + offset, sr);
	
	if (length(ro - offset) > sr){
		dO = inSects.x;
		if(dO < 0.0) return vec3(0.0);
		dS = (inSects.y - inSects.x) / float(steps);
	}else{
		dS = inSects.y / float(steps);
	}
	for(int i=0; i < steps; i++){
		vec3 p = ro + rd * dO;
		
		//Gas density dropoff function, closer to the ball edge	
		float densityDropoff = (1.0 - length(p - offset)/sr);
		
		//Centering offset for non-repeating Volume Texture
		float texSeedOffset = texOffset;
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = (p - offset)/(sr*2.0) + volOffset;
		texP.x /= 64.0;
		texP += vec3((1.0 - 1.0/64.0)*texSeedOffset, 0.0, 0.0);
		
		float v_r = texture(viewportTexture, texP).r;
		float v_g = texture(viewportTexture, texP).g * densityDropoff;
		float v_b = texture(viewportTexture, texP).b * v_r;
		
		vec3 v_gases = 0.5 * vec3(v_r, v_g, v_b) * densityDropoff * densityDropoff;
		
		
		if((length(p - offset) < sr)){
			gases += v_gases;
		}
		
		dO += dS;
	}
	gases = (1.0 - 1.0/exp(gases));
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
	//vec3 frag_hitpos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 rd = normalize(world_hitpos - ro);
	
	float sampleTest;
	vec3 gases;
	
	//sampleTest = SampleMarch(ro, rd, TIME, gases);
	gases = GasesMarch(ro, rd, TIME, custom.xyz, color.w, custom.w);
	//if(sampleTest < 0.0001) discard;
	
	//ALBEDO = vec3(1.0, 0.0, 0.0);
	//ALPHA = min(1.0, sampleTest);
	
	vec3 r = vec3(1.0, 0.01, 0.03);
	vec3 g = color.xyz;
	vec3 b = normalize(vec3(1.0) - normalize(r + g));
	vec3 colormix = ( r*gases.r + g*gases.g + b*gases.b )/2.0;
	
	ALBEDO = colormix;
	ALPHA = min(1.0, length(colormix)/3.0);
	
}