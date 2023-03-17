shader_type spatial;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture,filter_linear_mipmap;
void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment(){
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	//EMISSION = vec3(1.0);
}