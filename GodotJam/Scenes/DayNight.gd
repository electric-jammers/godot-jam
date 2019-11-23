extends Spatial

func _process(delta):
	rotation = Vector3(0.0, 0.0, GameState.get_normalized_day_night_cycle_time() * PI * 2.0);
