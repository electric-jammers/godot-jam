extends DirectionalLight

func _process(delta):
	look_at(Vector3.ZERO, Vector3.UP);
