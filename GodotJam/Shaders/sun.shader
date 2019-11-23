shader_type spatial;
render_mode unshaded;

uniform float dayNightValue;
uniform float colMultiplier = 1.0;
uniform float horizon = 0.83;
uniform sampler2D texSampler;

void fragment()
{
	if ((SCREEN_UV.y) < horizon)
	{
		discard;
	}
	
	float delta = abs(2.0*fract(dayNightValue)-1.0);
	
	vec3 fogCol = mix(vec3(0.95, 0.7, 0.6), vec3(0.6, 0.7, 0.95), delta);
	float fog = clamp(pow(mix(1.0, 0.0, SCREEN_UV.y-.84), 10.0)-0.2, 0, 1.0);
	
	vec4 texColor = texture(texSampler, UV);
	ALBEDO = mix(vec3(texColor.rgb) * colMultiplier, fogCol, fog);
	
	ALPHA = texColor.a;
}
