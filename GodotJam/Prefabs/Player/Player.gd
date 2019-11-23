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
var _is_dead := false

var _carried_block: Spatial
var _carried_block_info: int

func _ready():
	var material = load("res://Materials/CharacterSkin.tres").duplicate() as SpatialMaterial
	for child in _meshes.get_children():
		if child is MeshInstance:
			child.set_surface_material(0, material)

	material.albedo_color = [Color.red, Color.blue][player_index]

func _process(delta: float):
	if _is_dead:
		return
	# Input
	var dir := Vector3()
	dir.x = Input.get_action_strength("move_-X_Player" + str(player_index+1)) - Input.get_action_strength("move_+X_Player" + str(player_index+1))
	dir.z = Input.get_action_strength("move_-Y_Player" + str(player_index+1)) - Input.get_action_strength("move_+Y_Player" + str(player_index+1))

	_velocity += dir * SPEED
	_on_ground = _floor_raycast.is_colliding()

	# Picking up
	if Input.is_action_just_pressed("action_Player" + str(player_index+1)):
		var sand = GameState.get_sand_system()

		if not _carried_block:
			var sand_info = sand.extract_sand(translation - Vector3(0.0, 1.0, 0.0))

			if sand_info.size() > 0:
				_carried_block = sand_info[0]
				_carried_block_info = sand_info[1]

				var block_collision = _carried_block.get_node("CollisionShape") as CollisionShape
				block_collision.disabled = true

				_carried_block.get_parent_spatial().remove_child(_carried_block)
				_carried_block.translation = Vector3(0.0, 3.0, 0.0)
				add_child(_carried_block)
		else:
			var in_front = global_transform.origin + Vector3(0.0, 0.5, 0.0) - _meshes.transform.basis.z
			if sand.add_sand(in_front, _carried_block_info):
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

	if translation.y < -4:
		$DrownSoundPlayer.play()
		GameState.report_player_death(player_index)
		_is_dead = true
