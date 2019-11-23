extends MeshInstance

func _process(delta):
	var shader_mat = get_surface_material(0) as ShaderMaterial
	shader_mat.set_shader_param("dayNightValue", GameState.get_normalized_stage_time())
