shader_type canvas_item;

uniform float galaxy_type = 1.0;
uniform float galaxy_shape_displacement = 0.02;
uniform float galaxy_spin = 1.0;
uniform float noisiness;
uniform float rotation_noise = 1.0;
uniform float rotation_noise_detail = 2.0;
uniform float rotation_amount = 5.0;
uniform float arms_amount = 3.0;
uniform float arms_twist = 1.0;
uniform float arms_flocculence = 0.5;
uniform float medium_size = 0.5;
uniform float medium_noise = 1.3;
uniform float medium_power = 0.7;
uniform float bulge_size = 4.0;
uniform float bulge_barness = 0.0;
uniform float noise_mapping = 0.1;
uniform float noise_map_x = 0.2;
uniform float noise_map_y = 0.2;


vec3 mod289_3(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289_4(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289_4(((x * 34.0) + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 2.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) { 
    vec2 C = vec2(1.0/6.0, 1.0/3.0) ;
    vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    
    // First corner
    vec3 i  = floor(v + dot(v, vec3(C.y)) );
    vec3 x0 = v - i + dot(i, vec3(C.x)) ;
    
    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );
    
    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
    //   x1 = x0 - i1  + 1.0 * C.xxx;
    //   x2 = x0 - i2  + 2.0 * C.xxx;
    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
    vec3 x1 = x0 - i1 + vec3(C.x);
    vec3 x2 = x0 - i2 + vec3(C.y); // 2.0*C.x = 1/3 = C.y
    vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y
    
    // Permutations
    i = mod289_3(i); 
    vec4 p = permute( permute( permute( 
    		 i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
    	   + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
    	   + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));
    
    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    vec3  ns = n_ * D.wyz - D.xzx;
    
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)
    
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)
    
    vec4 x = x_ *ns.x + vec4(ns.y);
    vec4 y = y_ *ns.x + vec4(ns.y);
    vec4 h = 1.0 - abs(x) - abs(y);
    
    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );
    
    //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
    //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    
    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
    
    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);
    
    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    
    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), vec4(0.0));
    m = m * m;
    return 22.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3) ) );
}

float fbm(vec3 p, int octaves, float lacunarity, float gain){
	float v = 0.0;
	float freq = 2.0;
	float amp = 1.0;
	float normalising_factor = 0.0;
	for(int i = 0; i < octaves; i++){
		//v += (texture(noiseTexture, p*freq) - 0.4).r*amp;
		v += snoise(p*freq)*amp;
		normalising_factor += amp;
		amp *= gain;
		freq *= lacunarity;
	}
	return v/normalising_factor;
}

vec2 rotateUV(vec2 uv, float rotation){
    float mid = 0.5;
    return vec2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

float spiral(vec2 coord, float arms, float spiraliness){
	vec2 uv = (coord - 0.5);
	float r = length(uv);
    float theta = atan(uv.y, uv.x);   
    float spiral = fract((arms / 2.0) * theta / PI + spiraliness * pow(r, 0.4));
	return pow(sin(spiral*PI), 4.0);
}

float ring(vec2 coord, float vibr, float thickness){
	vec2 uv = (coord - 0.5);
	float r = length(uv);
    float theta = atan(uv.y, uv.x);   
    //float ring = fract((arms / 2.0) * theta / PI + spiraliness * pow(r, 0.4));
	float ring = cos(2.0*length(1.5*uv)) + fbm(2.0*vec3(uv, 1.0), 4, 2.0, 0.5);
	return pow(sin(ring*PI), 3.0);
}

void fragment(){
	
	float res = 256.0;
	float res_x = 16.0;
	float res_y = 16.0;
	float x_crd = mod(UV.x, 1.0/res_x)*res_x;
	float y_crd = mod(UV.y, 1.0/res_y)*res_y;
	float z_crd = (floor(UV.x*res_x) + res_x*floor(UV.y*res_y))/(res);
	vec3 uv3D = vec3(x_crd, y_crd, z_crd);

	
	//noise sampling parameters
	int octaves = 4;
	float lacunarity = 2.0;
	float gain = 0.5;
	//galaxy parameters
	float type = galaxy_type;
	float spin = galaxy_spin;
	float rot_a = rotation_amount;
	float rot_b = rotation_noise;
	float rot_c = rotation_noise_detail;
	float med_a = medium_noise;
	float med_b = medium_power;
	float med_width = medium_size;
	float spi_arms = round(arms_amount);
	float spi_b = arms_twist;
	float spi_f = arms_flocculence;
	float displ = galaxy_shape_displacement/10.0;
	float map = noise_mapping;
	float map_x = noise_map_x;
	float map_y = noise_map_y;
	
	float centerDist = length(uv3D - vec3(0.5));
	float distDropOff = max(0.0, 3.0*atan(1.0-2.0*centerDist));
	float ddo = min(1.0, distDropOff);
	
	vec3 offset_p = uv3D + displ*fbm(uv3D*0.7, 2, 2.0, 0.5);
	offset_p = offset_p + map*vec3(fbm(uv3D*map_x*ddo, 2, 2.0, 0.5), fbm(uv3D*map_y*ddo, 2, 2.0, 0.5), 0.0);
	
	float newCenterDist = length(offset_p - vec3(0.5));
	ddo = max(0.0, 3.0*atan(1.0-2.0*newCenterDist));
	distDropOff = distDropOff * ddo / max(distDropOff, ddo);
	
	float centerDist_Horizontal = length(offset_p.xy - vec2(0.5));
	float centerDist_Vertical = length(offset_p.z - 0.5);
	float cDH = centerDist_Horizontal;
	float cDV = pow(centerDist_Vertical, 0.95);
	
	float rotation = (rot_a*cDH) + rot_b*fbm(vec3(rot_c*offset_p.xy, 3.0*offset_p.z), octaves, lacunarity, gain);
	offset_p = vec3(rotateUV(offset_p.xy, -spin*rotation), offset_p.z);
	
	float v = (fbm(offset_p*med_a, octaves, lacunarity, gain) + 1.0)/ 2.0;
	v = v/exp(2.0*cDH/med_width);
	
	vec3 color = vec3(0.45,0.2,0.6);
	
	float spiralarms = spi_arms;
	float spiraliness = spin*spi_b;
	
	float vertical_dropoff_disc = pow(max(0.0, smoothstep(0.9, 1.0, 2.0*(0.5 - cDV))), 2.0);
	
	float spiralval = max(0.0, (2.0 - type) * spiral(offset_p.xy, spiralarms, spiraliness) * sqrt(cDH));
	float ringval = max(0.0, (type - 1.0) * ring(offset_p.xy, spiralarms, spiraliness) * sqrt(cDH));
	spiralval = (spiralval + ringval)/(1.0);
	spiralval = spiralval * vertical_dropoff_disc;
	
	float medium_str = med_b;  											//0.5 -> 2.0
	float mediumval = min(pow(v, 1.0/medium_str), 1.0);		//0.0 -> 2.0
	mediumval = mediumval * vertical_dropoff_disc;
	spiralval = (1.0-mediumval)*spiralval;
	
	centerDist = newCenterDist;
	
	float bulgesize = 10.0*bulge_size;
	//float bulgeval = (1.0/bulgesize)*max(0.0, bulgesize - pow(centerDist,1.0));
	float bulgeval = (1.0/(exp(bulgesize*(centerDist))+exp(-bulgesize*(centerDist)))) * pow(cos(centerDist*PI), 2.0);
	bulgeval = bulgeval * 1.0*pow(max(0.0, smoothstep(0.5, 1.0, 2.0*(0.5 - cDV))), 2.0);
	//Barred attempt bulgeval = bulgeval * (1.0 - 64.0*pow((uv3D.y - 0.5)*bulgesize/10.0, 2.0));
	
	float spirals = distDropOff*(spiralval);
	float medium = distDropOff*(mediumval);
	float bulge = distDropOff*(bulgeval);
	float full = distDropOff*(spiralval+mediumval+bulgeval);
	
	COLOR = vec4(spirals, medium, bulge, 1.0);
}
