tool
extends CSGMesh

func _process(delta):
	var spatialMat := material as SpatialMaterial
	spatialMat.albedo_color = Color(sin(OS.get_ticks_msec()*0.01)*0.5+0.5, sin(OS.get_ticks_msec()*0.02+2.515)*0.5+0.5, sin(OS.get_ticks_msec()*0.002+0.121561)*0.5+0.5);
	
	var move_dir := Vector2(0, 0)
	
	if(Input.get_action_strength("move_up") > 0):
		move_dir += Vector2(0, -1)
	if(Input.get_action_strength("move_down") > 0):
		move_dir += Vector2(0, 1)
	if(Input.get_action_strength("move_left") > 0):
		move_dir += Vector2(-1, 0)
	if(Input.get_action_strength("move_right") > 0):
		move_dir += Vector2(1, 0)
		
	if move_dir.length_squared() > 0:
		spatialMat.albedo_color = Color(0, 0, 0)
	
	translation += Vector3(move_dir.x, 0, move_dir.y)
	
	
	
