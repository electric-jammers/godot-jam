extends CSGBox

func _process(delta):
	var shader_mat = material as ShaderMaterial
	shader_mat.set_shader_param("playerY", translation.y)
