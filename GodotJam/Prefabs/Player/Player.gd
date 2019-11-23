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

var _carried_block: Spatial

func _process(delta: float):
	# Input
	var dir := Vector3()
	dir.x = Input.get_action_strength("move_-X_Player" + str(player_index+1)) - Input.get_action_strength("move_+X_Player" + str(player_index+1))
	dir.z = Input.get_action_strength("move_-Y_Player" + str(player_index+1)) - Input.get_action_strength("move_+Y_Player" + str(player_index+1))

	_velocity += dir * SPEED
	_on_ground = _floor_raycast.is_colliding()

	# Picking up
	if Input.is_action_just_pressed("action_Player" + str(player_index+1)):
		if not _carried_block:
			var ss = GameState.get_sand_system()
			var sandy = ss.extract_sand(translation - Vector3(0.0, 1.0, 0.0))

			if sandy.size() > 0:
				var node = sandy[0]
				var type = sandy[1]

				_carried_block = node

				var block_collision = _carried_block.get_node("CollisionShape") as CollisionShape
				block_collision.disabled = true

				_carried_block.get_parent_spatial().remove_child(_carried_block)
				_carried_block.translation = Vector3(0.0, 3.0, 0.0)
				add_child(_carried_block)
		else:
			#TODO: place in front

			_carried_block.queue_free()
			_carried_block = null


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
