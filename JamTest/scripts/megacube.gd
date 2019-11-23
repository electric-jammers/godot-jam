extends RigidBody

onready var csgmesh = $CSGMesh

var move_dir := Vector2(0, 0)

func _process(delta: float) -> void:
	var spatialMat := csgmesh.material as SpatialMaterial


	move_dir =  Vector2(0, 0)

	if(Input.get_action_strength("move_up") > 0):
		move_dir += Vector2(0, -1)
	if(Input.get_action_strength("move_down") > 0):
		move_dir += Vector2(0, 1)
	if(Input.get_action_strength("move_left") > 0):
		move_dir += Vector2(-1, 0)
	if(Input.get_action_strength("move_right") > 0):
		move_dir += Vector2(1, 0)


	var throbSpeed : float = 0.001
	throbSpeed = throbSpeed + 0.001 * move_dir.length_squared()
	spatialMat.albedo_color = Color(sin(OS.get_ticks_msec()*throbSpeed)*0.5+0.5, sin(OS.get_ticks_msec()*throbSpeed*2+2.515)*0.5+0.5, sin(OS.get_ticks_msec()*throbSpeed*0.2+0.121561)*0.5+0.5);

func _physics_process(delta: float) -> void:
	apply_central_impulse(Vector3(move_dir.x, 0, move_dir.y) * mass)

	if(Input.get_action_strength("jump") > 0):
		apply_central_impulse(Vector3(0, 1, 0) * mass)



