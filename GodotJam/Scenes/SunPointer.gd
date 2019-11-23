extends DirectionalLight

export var isSun = true

var initialLightEnergy = 1.0;

func _ready():
	initialLightEnergy = light_energy;

func _process(delta):
	look_at(Vector3.ZERO, Vector3.UP);
	var time = fmod(GameState.get_normalized_day_night_cycle_time(), 1.0)
	var stageTime = GameState.get_normalized_stage_time()


	if (isSun and (time > 0.75 or time < 0.25)) or (not isSun and (time > 0.25 and time < 0.75)):
		light_energy = 0.0
		shadow_enabled = false
	else:
		light_energy = pow(lerp(0.0, initialLightEnergy, 1.0 - abs(stageTime - 0.5) * 2.0), 0.2);
		shadow_enabled = true

	if isSun:
		print(String(light_energy))
