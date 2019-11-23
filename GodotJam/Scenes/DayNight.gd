extends Spatial

export var dayNightValue = 0.0

func _process(delta):
	dayNightValue = fmod(OS.get_ticks_msec()*0.001, 1.0);
	rotation = Vector3(0.0, 0.0, dayNightValue);
