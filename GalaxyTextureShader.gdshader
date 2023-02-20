shader_type spatial;
//fucker.tres
uniform sampler3D viewportTexture;
//uniform vec3 cameraPos;

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

vec4 ColorsMarch(vec3 ro, vec3 rd, float t, vec3 a, vec3 b, vec3 c){
	float dO = 0.0;
	float dS;
	float pDist;
	float sr = 30.0;
	float gas = 0.0;
	float w = 0.0;
	vec4 gases = vec4(0.0);
	vec3 final_color = vec3(0.0);
	
	int steps = 50;
	
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
		
		//Centering offset for non-repeating Volume Texture
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = p/(2.0*sr) + volOffset;
		
		float v_r = texture(viewportTexture, texP).r;
		float v_g = texture(viewportTexture, texP).g;
		float v_b = texture(viewportTexture, texP).b;
		vec3 v_mix = v_r*a + v_g*b + v_b*c;
		v_mix = max(max(v_r*a, v_g*b), v_b*c);
		
		float v_w = v_r + v_g + v_b;
		
		vec4 v_gases = 1.0 * vec4(v_r, v_g, v_b, v_w);
		
		w += v_w;
		float newgas = (1.0 - 1.0/exp(w));
		float gasdiff = newgas - gas;
		gas = newgas;
		final_color += gasdiff * v_mix;
		
		dO += dS;
	}
	return vec4(final_color, 1.0);
}

vec4 GalaxyMarch(vec3 ro, vec3 rd, vec3 op, float t){
	float dO = 0.0;
	float dS;
	float pDist;
	float sr = 30.0;
	float gas = 0.0;
	vec4 gases = vec4(0.0);
	
	int steps = 100;
	
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
		
		if(distance(ro, p) > distance(ro, op)){
			break;
		}
		
		pDist = length(p);
		
		//Gas density dropoff function, closer to the ball edge	
		float densityDropoff = (1.0 - pDist/sr);
		
		//Centering offset for non-repeating Volume Texture
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = p/(2.0*sr) + volOffset;
		
		float v_r = texture(viewportTexture, texP).r;
		float v_g = texture(viewportTexture, texP).g;
		float v_b = texture(viewportTexture, texP).b;
		
		float v_w = v_r + v_g + v_b / 3.0;
		
		vec4 v_gases = 1.0 * vec4(v_r, v_g, v_b, v_w);
		
		gases += v_gases;
		gas = length(gases.xyz);
		
		dO += dS;
	}
	gases = (1.0 - 1.0/exp(gases));
	return gases;
}

varying mat4 CAMERA;

void vertex(){
	hitpos = VERTEX;
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	CAMERA = INV_VIEW_MATRIX;
}

void fragment(){
	vec3 ro = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(vec3(0), 1.0)).xyz;
	vec3 rd = normalize(hitpos - ro);
	
	float sampleTest;
	vec4 gases;
	
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
  	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  	view.xyz /= view.w;
  	float linear_depth = -view.z;
	float depth_dist = linear_depth;
	vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  	vec3 world_position = world.xyz / world.w;
	
	vec3 o_p = (inverse(MODEL_MATRIX) * vec4(world_position, 1.0)).xyz;
	
	//sampleTest = SampleMarch(ro, rd, TIME, gases);
	gases = GalaxyMarch(ro, rd, o_p, TIME);
	//if(sampleTest < 0.0001) discard;
	
	//ALBEDO = vec3(1.0, 0.0, 0.0);
	//ALPHA = min(1.0, sampleTest);
	
	vec3 main_color = normalize(vec3(0.1, 0.2, 0.6));
	
	vec3 spiral_c = main_color;
	vec3 medium_c = (main_color+0.2)/1.2;
	vec3 bulge_c = mix(vec3(0.8, 0.8, 0.2), main_color, 0.5);
	
	float spiral_v = (gases.r) * (1.0 - gases.b);
	float medium_v = gases.g;
	float bulge_v = gases.b;
	
	//vec3 colormarch = ColorsMarch(ro, rd, TIME, spiral_c, medium_c, bulge_c).xyz;
	vec3 color = max(max(spiral_c*spiral_v, medium_c*medium_v), bulge_c*bulge_v);
	vec3 colormix = (spiral_c*spiral_v + medium_c*medium_v + bulge_c*bulge_v);
	vec3 chosen = colormix;
	
	ALBEDO = chosen;
	ALPHA = min(1.0, length(chosen)/20.0);
}