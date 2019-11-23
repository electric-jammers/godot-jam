extends Spatial

export var dayNightValue = 0.0

func _process(delta):
	dayNightValue = (OS.get_ticks_msec()*0.001);
	rotation = Vector3(0.0, 0.0, dayNightValue);

