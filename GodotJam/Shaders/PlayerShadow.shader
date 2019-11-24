shader_type spatial;
render_mode unshaded;//, depth_draw_never, depth_test_disable;

uniform float playerY = 0.0;

varying flat mat4 model_view_matrix;

void vertex(){
	model_view_matrix = MODELVIEW_MATRIX;
}

void fragment()
{
	vec4 posWS = inverse(model_view_matrix) * INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r * 2.0 - 1.0, 1.0);
	posWS.xyz /= posWS.w;

	float heightScale = clamp((playerY - posWS.y + 8.5) / 5.0, 0, 1);

//	float v = step(length(posWS.xz), 0.5);
	vec2 thresholds = mix(vec2(1.0, 0.6), vec2(1.4, 0.1), heightScale);
	float v = smoothstep(thresholds.x, thresholds.y, length(posWS.xz)) * mix(0.65, 0.2, heightScale);
	
	ALBEDO = vec3(0);
	ALPHA = v;
}
