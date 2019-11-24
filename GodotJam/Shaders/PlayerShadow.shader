shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disable;

varying flat mat4 model_view_matrix;

void vertex(){
	model_view_matrix = MODELVIEW_MATRIX;
}

void fragment()
{
	vec4 posWS = inverse(model_view_matrix) * INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r * 2.0 - 1.0, 1.0);
	posWS.xyz /= posWS.w;

//	float v = step(length(posWS.xz), 0.5);
	float v = smoothstep(0.5, 0.3, length(posWS.xz)) * 0.65;
	
	ALBEDO = vec3(0);
	ALPHA = v;
}
