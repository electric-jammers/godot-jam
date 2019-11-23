shader_type spatial;

uniform float dayNightValue = 1.0; // 0 = day, 1 = night

varying vec3 viewDir;
void vertex()
{
	viewDir = normalize(VERTEX);
}

void fragment()
{
	float y = viewDir.y*0.5+0.5;
	vec3 dayCol = mix(vec3(0.25, 0.01, 0.04), vec3(0.36, 0.32, 0.12), pow(y, 3.0));
	vec3 nightCol = mix(vec3(0.03, 0.03, 0.08), vec3(0.07, 0.07, 0.15), pow(y, 4.0));
	
	ALBEDO = mix(dayCol, nightCol, dayNightValue);
}