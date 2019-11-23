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
	return mix(0.0, 2.0, pow(fract(sin(dot(uvw, vec3(12.9898, 78.233, 64.2158))) * 43758.5453), 1000.0));
}

void fragment()
{
	// TODO: Use this once value is set appropirately:
	// float delta = dayNightValue;
	float delta = sin(TIME*0.5+3.1415)*0.5+0.5;
	
	float y = viewDir.y*0.5+0.5;
	vec3 dayCol = mix(vec3(0.25, 0.01, 0.04), vec3(0.36, 0.32, 0.12), pow(y, 3.0));
	vec3 nightCol = mix(vec3(0.03, 0.03, 0.08), vec3(0.07, 0.07, 0.15), pow(y, 4.0)) + rand12(viewDir);
	
	ALBEDO = mix(dayCol, nightCol, delta);
}