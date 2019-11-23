extends DirectionalLight

export var isSun = true

var initialLightEnergy = 1.0;

func _ready():
	initialLightEnergy = light_energy;

func _process(delta):
	look_at(Vector3.ZERO, Vector3.UP);
	var dayNightVal = get_parent().get_parent().dayNightValue;
	if (isSun and dayNightVal > 0.5) or (not isSun and dayNightVal < 0.5):
		light_energy = 0.0
	else:
		light_energy = initialLightEnergy
