shader_type spatial;
render_mode unshaded;

uniform float dayNightValue = 1.0; // 0 = day, 1 = night

uniform sampler2D moonSampler;
uniform sampler2D sunSampler;

varying vec3 viewDir;

void vertex()
{
	viewDir = normalize(VERTEX);
}

float rand12(vec3 uvw)
{
	return fract(sin(dot(uvw, vec3(12.9898, 78.233, 64.2158))) * 43758.5453);
}

float stars(vec3 inViewDir)
{
	return mix(0.0, 5.0, pow(rand12(inViewDir), 1000.0));	
}

void fragment()
{
	float delta = abs(2.0*fract(dayNightValue)-1.0);
	
	float y = viewDir.y*0.5+0.5;
	vec3 dayCol = mix(vec3(0.25, 0.01, 0.04), vec3(0.36, 0.32, 0.12), pow(y, 3.0));
	vec3 nightCol = mix(vec3(0.05, 0.05, 0.1), vec3(0.07, 0.07, 0.15), pow(y+0.3, 10.0)) + pow(y, 2.0) * stars(viewDir);
	
	vec3 fogCol = mix(vec3(0.95, 0.7, 0.6), vec3(0.6, 0.7, 0.95), delta);
	float fog = clamp(pow(1.0-viewDir.y, 20.0)-0.2, 0, 1.0);
	
	ALBEDO = mix(mix(dayCol, nightCol, delta), fogCol, fog);
}