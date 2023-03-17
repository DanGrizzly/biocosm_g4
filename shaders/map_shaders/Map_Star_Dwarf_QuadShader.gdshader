// NOTE: Shader automatically converted from Godot Engine 3.4.4.stable.mono's SpatialMaterial.

shader_type spatial;
render_mode blend_add, depth_draw_opaque, unshaded, skip_vertex_transform;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

varying vec4 custom;

varying vec3 dwarf_color;
varying vec3 halo;

float distanceTo(vec3 v, mat4 m){
	vec3 truev = (m*vec4(v, 1.0)).xyz;
	return length(truev);
}


void vertex() {
	
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	
	VERTEX = (MODELVIEW_MATRIX*vec4(VERTEX,1.0)).xyz;

	custom = INSTANCE_CUSTOM;
	// WHITE DWARF "CLASS D"
	dwarf_color = vec3(1.0);
	halo = vec3(0.2,0.8,0.9);
	//BROWN DWARFS
	if(custom.x < 0.3){ //CLASS L
		dwarf_color = vec3(0.7,0.1,0.2);
		halo = vec3(0.6, 0.05, 0.1);
	}
	if(custom.x < 0.15){ //CLASS T
		dwarf_color = vec3(0.5,0.1,0.35);
		halo = vec3(0.4,0.05,0.3);
	}
	if(custom.x < 0.05){ //CLASS Y
		dwarf_color = vec3(0.25,0.1,0.30);
		halo = dwarf_color;
	}
}


void fragment() {
	vec2 base_uv = UV; //ABECEDA
	
	float scale = 0.2;
	
	float dist = clamp(length(UV * 2.0 - 1.0), 0.0, 1.0);
	if(dist>scale){
		discard;
	}
	float truedist = dist/scale;
	float i = pow(cos(truedist*PI/2.0)*1.,1.8);
	vec3 halocorrected = vec3(pow(halo.x, 1.0-i), pow(halo.y, 1.0-i), pow(halo.z, 1.0-i));
	vec3 color = halocorrected*dwarf_color;
	
	
	ALBEDO = pow(sqrt(i)*color, vec3(2.2));
	ALPHA = sqrt(i);
}
