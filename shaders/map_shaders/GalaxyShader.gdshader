shader_type spatial;

uniform sampler2D ditherTexture;
uniform sampler3D viewportTexture_1;
uniform sampler3D viewportTexture_2;

uniform vec3 spiralColor = vec3(0.0, 0.05, 1.0);
uniform float galaxyRadius = 30.0;

render_mode unshaded, blend_mix, depth_prepass_alpha,
	cull_front;

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

vec4 GalaxyMarch(vec3 ro, vec3 rd, float time,  vec4 frag, inout vec3 detailgases, inout vec3 depth_point){
	float dO = 0.0;
	float dS;
	float pDist;
	float sr = galaxyRadius;
	
	vec4 gases = vec4(0.0);
	vec3 detail = vec3(0.0);
	
	float depth_write = 0.0;
	float dust = 0.0;
	
	//CALCULATING SPHERE INTERSECTS AND AMOUNT OF STEPS
	vec2 inSects = raySphereIntersects(ro, rd, vec3(0,0,0), sr);
	int steps = 100;
	//if(length(ro)>sr){steps = int(ceil(3.0*(inSects.y - inSects.x)));}
	//else{steps = int(ceil(3.0*(inSects.y)));}
	//steps = min(steps, 100);
	if (length(ro) > sr){
		dO = inSects.x;
		if(dO < 0.0) return vec4(0.0);
		dS = (inSects.y - inSects.x) / float(steps);
	}else{dS = inSects.y / float(steps);}
	/////////////////////////////////////////////////////
	
	for(int i=0; i < steps; i++){
		vec3 p = ro + rd * dO;
		
		pDist = length(p);
		
		//Gas density dropoff function, closer to the ball edge	
		float densityDropoff = (1.0 - pDist/sr);
		float dd = densityDropoff;
		
		//Centering offset for non-repeating Volume Texture
		vec3 volOffset =  vec3(0.5, 0.5, 0.5);
		vec3 texP = p/(2.0*sr) + volOffset;
		
		dust = 1.0/exp(gases.w);
		
		//DEPTH BUFFER DITHERING!!!
		if(depth_write < 0.5){
			vec2 screenCoord = vec2(mod(frag.x, 512.0), mod(frag.y, 512.0)); //Maybe fragcoord isn't in pixel values, mayb 0. - 1.
			float dither_val = texture(ditherTexture, screenCoord/512.0).r;
			dither_val = length(texture(ditherTexture, screenCoord/512.0))/length(vec3(1.0));
			float dust_val = 1.0 - dust;
			depth_write = step(dither_val, 3.5*dust_val);
			if(depth_write > 0.5){
				depth_point = p;
				break;
			}
		}
		///////////////////////////
		//DUST CHECKING
		//if(dust < 0.04){break;}
		///////////////////////////
		
		float v_r = min(1.0, dust) * texture(viewportTexture_1, texP).r;
		float v_g = min(1.0, dust) * texture(viewportTexture_1, texP).g;
		float v_b = min(1.0, dust) * texture(viewportTexture_1, texP).b;
		
		float d_r = 1.0 * min(1.0, dust) * texture(viewportTexture_2, texP).r;
		float d_g = 1.0 * texture(viewportTexture_2, texP).g;
		float d_b = 1.0 * min(1.0, dust) * texture(viewportTexture_2, texP).b;
		
		
		vec4 v_gases = 1.0 * vec4(v_r, v_g, v_b, d_g);
		vec3 d_gases = 1.0 * vec3(d_r, d_g, d_b);
		
		gases += v_gases;
		detail += d_gases;
		
		dO += dS;
	}
	gases = (1.0 - 1.0/exp(gases));
	detailgases = (1.0 - 1.0/exp(detail));
	detailgases.g *= 4.0;
	return gases;
}

varying vec3 camerapos;
varying mat4 obj_to_proj;

void vertex(){
	hitpos = VERTEX;
	camerapos = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(vec3(0), 1.0)).xyz;
	obj_to_proj = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX;
}

void fragment(){
	//vec3 ro = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(vec3(0), 1.0)).xyz;
	vec3 ro = camerapos;
	vec3 rd = normalize(hitpos - ro);
	
	vec3 detail = vec3(0.0);
	vec3 depth_p = vec3(0.0);
	vec4 gases = GalaxyMarch(ro, rd, TIME, FRAGCOORD, detail, depth_p);
	//DEPTH BUFFER
	float depthval = 1.0;
	if(depth_p != vec3(0.0)){
		vec4 thing = (obj_to_proj * vec4(depth_p, 1.0));
		depthval = (thing.z/thing.w);
	}
	DEPTH = depthval;
	
	vec3 main_color = normalize(spiralColor);
	
	float disc_v = (gases.r) * (1.0 - gases.b);
	float medium_v = gases.g;
	float bulge_v = 3.0*gases.b;
	
	float emi_v = detail.r;
	float dust_v = detail.g;
	float ref_v = detail.b;
	
	vec3 disc_c = main_color;
	vec3 medium_c = (main_color+0.2)/1.2;
	vec3 bulge_c = mix(vec3(1.0, 0.9, 0.4), main_color, 0.5);
	
	vec3 emi_c = mix(vec3(1.0, 0.2, 0.1), main_color, 1.0 - emi_v);
	vec3 dust_c = normalize(vec3(1.0) - main_color)/8.0;
	vec3 ref_c = mix(vec3(0.1, 0.2, 1.0), main_color, 1.0 - ref_v);
	
	
	vec3 colormix = (disc_c*disc_v + medium_c*medium_v + bulge_c*bulge_v);
	//vec3 clown = disc_c*disc_v + bulge_c*bulge_v;
	vec3 fullmix = colormix + disc_v*(emi_c*emi_v + ref_c*ref_v);
	vec3 dustmix = mix(fullmix, dust_c, dust_v);
	vec3 chosen = dustmix;
	
	ALBEDO = chosen;
	ALPHA = min(1.0, length(chosen)/45.0);
}