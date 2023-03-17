shader_type spatial;
//fucker.tres
uniform sampler3D viewportTexture_1;
uniform sampler3D viewportTexture_2;
//uniform vec3 cameraPos;

render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled,
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
		
		float v_r = texture(viewportTexture_1, texP).r;
		float v_g = texture(viewportTexture_1, texP).g;
		float v_b = texture(viewportTexture_1, texP).b;
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

vec4 GalaxyMarch(vec3 ro, vec3 rd, float thr, float t, inout vec3 detailgases){
	float dO = 0.0;
	float dS;
	float pDist;
	float sr = 30.0;
	
	vec4 gases = vec4(0.0);
	vec3 detail = vec3(0.0);
	
	float break_point = -log(1.0-thr);
	
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
		
		pDist = length(p);
		
		//Gas density dropoff function, closer to the ball edge	
		float densityDropoff = (1.0 - pDist/sr);
		float dd = densityDropoff;
		
		//Centering offset for non-repeating Volume Texture
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = p/(2.0*sr) + volOffset;
		
		float v_r = min(1.0, 1.0/exp(gases.w)) * texture(viewportTexture_1, texP).r;
		float v_g = min(1.0, 1.0/exp(gases.w)) * texture(viewportTexture_1, texP).g;
		float v_b = min(1.0, 1.0/exp(gases.w)) * texture(viewportTexture_1, texP).b;
		
		float d_r = 5.0*min(1.0, 1.0/exp(gases.w)) * texture(viewportTexture_2, texP).r;
		float d_g = min(1.0, 1.0/exp(gases.w)) * texture(viewportTexture_2, texP).g;
		float d_b = 5.0*min(1.0, 1.0/exp(gases.w)) * texture(viewportTexture_2, texP).b;
		
		float v_dust = 7.0 * texture(viewportTexture_2, texP).g;
		
		vec4 v_gases = 1.0 * vec4(v_r, v_g, v_b, v_dust);
		vec3 d_gases = 1.0 * vec3(d_r, d_g, d_b);
		
		gases += v_gases;
		detail += d_gases;
		
		if(gases.w > break_point){
			//gases = vec4(0.0);
			//break;
		}
		dO += dS;
	}
	gases = (1.0 - 1.0/exp(gases));
	detailgases = (1.0 - 1.0/exp(detail));
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
	
	float thr = 0.4;
	//sampleTest = SampleMarch(ro, rd, TIME, gases);
	vec3 detail;
	vec4 gases = GalaxyMarch(ro, rd, thr, TIME, detail);
	
	vec3 main_color = normalize(vec3(0.0, 0.1, 0.9));
	
	vec3 disc_c = main_color;
	vec3 medium_c = (main_color+0.2)/1.2;
	vec3 bulge_c = mix(vec3(1.0, 0.9, 0.4), main_color, 0.5);
	
	vec3 emi_c = mix(vec3(1.0, 0.2, 0.1), main_color, 0.1);
	vec3 dust_c = main_color/5.0;
	vec3 ref_c = mix(vec3(0.1, 0.2, 1.0), main_color, 0.1);
	
	float disc_v = (gases.r) * (1.0 - gases.b);
	float medium_v = gases.g;
	float bulge_v = 2.0*gases.b;
	
	float emi_v = detail.r;
	float dust_v = detail.g;
	float ref_v = detail.b;
	
	//vec3 colormarch = ColorsMarch(ro, rd, TIME, spiral_c, medium_c, bulge_c).xyz;
	vec3 color = max(max(disc_c*disc_v, medium_c*medium_v), bulge_c*bulge_v);
	vec3 colormix = (disc_c*disc_v + medium_c*medium_v + bulge_c*bulge_v);
	vec3 clown = disc_c*disc_v + bulge_c*bulge_v;
	vec3 dustmix = mix(colormix, dust_c, pow(dust_v, 2));
	vec3 fullmix = colormix + disc_v*(emi_c*emi_v + ref_c*ref_v);
	
	vec3 chosen = fullmix;
	
	ALBEDO = chosen;
	ALPHA = min(1.0, length(chosen)/30.0);
}