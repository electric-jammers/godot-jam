extends MeshInstance

func _process(delta):
	var shader = get_surface_material(0) as ShaderMaterial
	shader.set_shader_param("dayNightValue", GameState.get_normalized_stage_time())
