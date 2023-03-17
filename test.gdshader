shader_type spatial;
render_mode unshaded, depth_draw_never, depth_prepass_alpha;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture,filter_linear_mipmap;
varying mat4 CAMERA;

void vertex() {
	CAMERA = INV_VIEW_MATRIX;
}

void fragment() {
	
	//Depth buffer shenanigans, interstellar dust blocking light
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	vec3 ndc2 = vec3(SCREEN_UV * 2.0 - 1.0, FRAGCOORD.z);
	vec4 current = INV_PROJECTION_MATRIX * vec4(ndc2, 1.0);
	current.xyz /= current.w;
	if (-current.z > -view.z){discard;}
	
	ALBEDO = vec3(0.1, 1.0, 0.0);
	ALPHA = 1.0;
}
