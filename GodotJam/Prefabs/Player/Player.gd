extends KinematicBody

# Subnode
onready var _meshes = $Mesh as Spatial
onready var _floor_raycast = $FloorCast as RayCast

# Consts
const AIR_FRICTION := 0.02
const GROUND_FRICTION := 0.05
const SPEED := 40.0
const JUMP_POWER := 800.0
const GRAVITY := 25.0

# Public state
export(int, 0, 1) var player_index := 0

# Private state
var _velocity := Vector3()
var _on_ground := false

func _process(delta: float):
	# Input
	var dir := Vector3()
	dir.x = Input.get_action_strength("move_-X_Player" + str(player_index+1)) - Input.get_action_strength("move_+X_Player" + str(player_index+1))
	dir.z = Input.get_action_strength("move_-Y_Player" + str(player_index+1)) - Input.get_action_strength("move_+Y_Player" + str(player_index+1))

	_velocity += dir * SPEED
	_on_ground = _floor_raycast.is_colliding()

	$DebugLabel.text = "ground? " + str(_on_ground)

	# "Physics"
	if _on_ground:
		if Input.is_action_just_pressed("jump_Player" + str(player_index+1)):
			_velocity.y += JUMP_POWER

		_velocity *= 1.0 - GROUND_FRICTION
	else:
		_velocity *= 1.0 - AIR_FRICTION
		_velocity += Vector3(0.0, -GRAVITY, 0.0)

	move_and_slide(_velocity * delta)

	# Facing
	var ground_velocity = _velocity
	ground_velocity.y = 0.0

	if ground_velocity.length_squared() > 100.0:
		var new_basis := Basis()
		new_basis.y = Vector3.UP
		new_basis.z = ground_velocity.normalized()
		new_basis.x = new_basis.z.cross(new_basis.y).normalized()

		_meshes.transform.basis = new_basis
