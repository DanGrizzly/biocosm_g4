// NOTE: Shader automatically converted from Godot Engine 3.4.4.stable.mono's SpatialMaterial.

shader_type spatial;
render_mode blend_add, depth_draw_opaque, unshaded, skip_vertex_transform;

varying vec4 custom;
varying float giantness;
varying vec3 b_b_color;
varying float temp;
varying float twinkles;
varying float single_pixel;

float distanceTo(vec3 v, vec3 c, mat4 w){
	vec3 vv = (w * vec4(v, 1.0)).xyz; 
	return length(c - vv);
}

vec3 blackbody(float t){
	
	float Temperature = t;
	//based on data by Mitchell Charity http://www.vendian.org/mncharity/dir3/blackbody/
	vec3 color = vec3(255.0, 255.0, 255.0);
	color.x = 56100000. * pow(Temperature, (-3.0 / 2.0)) + 148.0;
	color.y = 100.4 * log(Temperature) - 623.6;
	if (Temperature > 6500.0){
		color.y = 35200000.0 * pow(Temperature, (-3.0 / 2.0)) + 184.0;
	}
	color.z = 194.2 * log(Temperature) - 1448.6;
	color = clamp(color, 0.0, 255.0) / 255.0;
	if (Temperature < 1000.0){
		color *= Temperature / 1000.0;
	}
	
	return color;
}

void vertex() {
	float distFromCamera = distanceTo(VERTEX, CAMERA_POSITION_WORLD, MODEL_MATRIX);
	float scaleIncrease = 1.0;
	float brightness = 1.0;
	single_pixel = 0.0;
	
	custom = INSTANCE_CUSTOM;
	
	if (distFromCamera > 5.0){
		scaleIncrease = scaleIncrease + 0.05*(distFromCamera-5.0);
		//brightness = pow(brightness / scaleIncrease, 1.0);
		brightness = max(0.01, brightness / pow(scaleIncrease, 1.3 - 1.0*(custom.x)));
		single_pixel = 1.0;
	}
	
	VERTEX = scaleIncrease*VERTEX;
	
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	
	VERTEX = (MODELVIEW_MATRIX*vec4(VERTEX,1.0)).xyz;

	//G/100: T = 6, L = 15, M = 26, K = 40, G = 55, F = 65, A = 100, B = 200, O = 500, W = 1200
	//S/100: T = 6, L = 15, M = 26, K = 40, G = 55, F = 65, A = 100, B = 200, O = 500, W = 1200
	
	temp = exp(5.3*pow(custom.x,1.3))*600.0;
	b_b_color = brightness * blackbody(temp);
	
	giantness = custom.w + 1.0;
	
	float twinkLevel = pow(1.65+custom.z/6.0,1.75);
	float twinkPhase = cos(temp + (0.6+custom.y*2.0)*TIME);
	twinkles = pow((twinkLevel-1.0+twinkPhase)/(twinkLevel), 0.2);
}


void fragment() {
	vec2 base_uv = UV; //ABECEDA
	
	float scale = min((1.0+giantness*twinkles/1.8)*twinkles*0.6, 0.95);
	
	float dist = clamp(length(UV * 2.0 - 1.0), 0.0, 1.0);
	if(dist>scale){
		discard;
	}
	float truedist = dist/scale;
	float i = pow(cos(truedist*PI/2.0)*(1.15),2);
	float b = clamp(1.0 - max(1.5 - i, 0.0) * max((temp/1000.0-7.0)/50.0, 0.0),0.0,1.0);
	float r = clamp(1.0 - max(1.2 - i, 0.0) * (7.0 - temp/1000.0)/6.0, 0.0, 1.0);
	float gh = pow((temp/1000.0-1.5)/2.0, 2.0) - pow((temp/1000.0)/4.0, 3.0);
	float g = clamp(1.0 - max(1.0 - i, 0.0) * gh, 0.0, 1.0);
	float w = 1.0/pow(1.0+i*giantness,2.0);
	
	float red = (b_b_color.x)*(b*b*b*b)*pow(g,1.0);
	float green = (b_b_color.y)*(r*r*b*b*sqrt(w));
	float blue = (b_b_color.z)*(r*r*r*r);
	
	vec3 halocorrected = vec3(red, green, blue);
	vec3 color = sqrt(1.0*pow(twinkles,1.0-i)*halocorrected);
	
	vec3 giant_outline = (1.5*abs(0.5 - custom.x))/exp(truedist) * vec3(1.0);
	color = color + giant_outline;
	
	if(single_pixel == 1.0){
		ALBEDO = pow(color, vec3(2.2));
		ALPHA = 1.0;
	}else{
		ALBEDO = i*pow(color, vec3(2.2));
		ALPHA = sqrt(i);
	}
}
