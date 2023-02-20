shader_type canvas_item;


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

vec2 rotateUV(vec2 uv, float rotation)
{
    float mid = 0.5;
    return vec2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

float spiral(vec2 coord, float arms, float spiraliness)
{
	vec2 uv = (coord - 0.5);
	float r = length(uv);
    float theta = atan(uv.y, uv.x);   
    float spiral = fract((arms / 2.0) * theta / PI + spiraliness * pow(r, 0.4));
	return pow(sin(spiral*PI), 4.0);
}

void fragment(){
	vec2 xy = FRAGCOORD.xy;
	
	int octaves = 8;
	float lacunarity = 2.0;
	float gain = 0.5;
	
	vec2 offset_p;
	
	//offset_p = xy;
	//offset_p.x = (fbm(vec3((xy + vec2(1.69))/200.0, TIME/30.0), octaves, lacunarity, gain));
	//offset_p.y = (fbm(vec3((xy + vec2(-0.42))/200.0, TIME/10.0), octaves, lacunarity, gain));
	
	offset_p = UV;
	offset_p = rotateUV(offset_p, TIME/10.0);
	
	float distfromcenter = length(offset_p - vec2(0.5));
	//float rotation = (4.0*exp(distfromcenter));
	float rotation = (7.0*distfromcenter) + 1.0*fbm(vec3(4.0*offset_p, (TIME/5.0)), 3, 2.0, 0.5);
	offset_p = rotateUV(offset_p, -rotation);
	
	float v = (fbm(vec3(offset_p*10.0, (TIME/5.0)), octaves, lacunarity, gain) + 1.0)/ 2.0;
	v = 5.0*v/exp(10.0*length(UV - vec2(0.5)));
	
	float distDropOff = 3.0*atan(1.0-2.0*distfromcenter);
	vec3 color = vec3(0.35,0.2,0.9);
	float spiralval = spiral(offset_p, 2.0, 1.0) * sqrt(distfromcenter);
	float mediumval = pow(v, 1.0);
	COLOR = vec4(distDropOff*(spiralval+mediumval)*color, 1.0);
}
