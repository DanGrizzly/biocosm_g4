shader_type spatial;
render_mode blend_add, depth_draw_opaque, unshaded;

uniform bool twinklesetting;

varying vec4 custom;

varying vec3 b_b_color;
varying float temp;
varying float twinkles;
varying float single_pixel;

float distanceTo(vec3 v, vec3 c, mat4 w){
	vec3 vv = (w * vec4(v, 1.0)).xyz; 
	return length(c - vv);
}
float falloff(float dist){
	if(dist*10.0/7.0 < 0.1){
		return 1.0;
	}
	float b = dist*10.0/7.0 - 0.1;
	float calc = cos(b*PI*5.0/9.0);
	return pow(calc, 4);
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

varying mat4 CAMERA;

void vertex() {
	float distFromCamera = distanceTo(VERTEX, CAMERA_POSITION_WORLD, MODEL_MATRIX);
	float scaleIncrease = 1.0;
	float brightness = 1.0;
	single_pixel = 0.0;
	
	custom = INSTANCE_CUSTOM;
	
	if (distFromCamera > 3.0){
		scaleIncrease = scaleIncrease + 0.05*(distFromCamera-3.0);
		brightness = max(0.01, brightness / pow(scaleIncrease, 1.35 - 1.0*(custom.x)));
		single_pixel = 1.0;
	}
	VERTEX = scaleIncrease*VERTEX;
	/* ORBITS (for binary and multiple systems (trinary, quaternary, quinary, senary) */
	//float orbit_vel = TIME*4.0;
	//float orbit_length = 1.0/100.0;
	//vec3 orbit_adjust = 0.0*(MODELVIEW_MATRIX*vec4(orbit_length*vec3(cos(orbit_vel), sin(orbit_vel), 0.0), 1.0)).xyz;
	//VERTEX += orbit_adjust;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	
	
	temp = exp(10.0*custom.x/2.7)*1000.0;
	b_b_color = brightness * blackbody(temp);
	twinkles = 1.0;
	if (twinklesetting){
		twinkles = pow((pow(custom.z,2)-1.0+sin(custom.x + custom.y*TIME))/pow(custom.z,2), 0.3);
	}
}

void fragment() {
	vec2 base_uv = UV; //ABECEDA
	

	float weirdcalc = min((sqrt(temp/1000.0)-1.0)/((sqrt(20.0)-1.0)), 1.0);
	float scale = twinkles*min(0.4+0.3*weirdcalc, 0.7);
	
	float dist = clamp(length(UV * 2.0 - 1.0), 0.0, 1.0);
	if(dist>scale){
		discard;
	}
	
	float truedist = dist/scale;
	float i = pow(cos(truedist*PI/2.0)*(1.25 - 0.1*weirdcalc),2);
	float b = clamp(1.0 - max(1.5 - i, 0.0) * max((temp/1000.0-7.0)/50.0, 0.0),0.0,1.0);
	float r = clamp(1.0 - max(1.2 - i, 0.0) * (7.0 - temp/1000.0)/6.0, 0.0, 1.0);
	vec3 halocorrected = vec3(b_b_color.x*pow(b, 4.0), b_b_color.y*b, b_b_color.z*r);
	vec3 color = pow(twinkles,1.0-i)*halocorrected; //pow(i,pow(twinkles, 10.0))*
	
	//vec3 color = vec3(1.0);
	if(single_pixel == 1.0){
		ALBEDO = pow(color, vec3(2.2));
		ALPHA = 1.0;
	}else{
		ALBEDO = i*pow(color, vec3(2.2));
		ALPHA = sqrt(i);
	}
	
	//ALBEDO = vec3(1.0);
	//ALPHA = 0.99;
}
