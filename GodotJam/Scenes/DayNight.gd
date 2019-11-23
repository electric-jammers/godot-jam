extends Spatial

func _process(delta):
	rotation = Vector3(0.0, 0.0, GameState.get_normalized_stage_time() * PI * 2.0);
