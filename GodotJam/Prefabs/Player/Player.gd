extends KinematicBody

# Subnode
onready var _meshes := $Mesh as Spatial
onready var _floor_raycast := $FloorCast as RayCast
onready var _dash_timer := $DashTimer as Timer

# Consts
const AIR_FRICTION := 0.25
const GROUND_FRICTION := 0.3
const SPEED := 200.0
const DASH_POWER := 4000.0
const JUMP_POWER := 2500.0
const GRAVITY := 100.0

# Public state
export(int, 0, 1) var player_index := 0

# Private state
var _velocity := Vector3()
var _on_ground := false
var _is_dead := false

var _carried_blocks: Array # of Spatial
var _carried_blocks_info: Array # of int

func _ready():
	var material = load("res://Materials/CharacterSkin.tres").duplicate() as SpatialMaterial
	for child in _meshes.get_children():
		if child is MeshInstance:
			child.set_surface_material(0, material)

	material.albedo_color = [Color(0.698039, 0.364706, 0.27451), Color(0.356863, 0.662745, 0.513726)][player_index]

func _process(delta: float):
	if _is_dead or GameState.stage == GameState.GameStage.GAME_OVER:
		return
	# Input
	var dir := Vector3()
	dir.x = Input.get_action_strength("move_-X_Player" + str(player_index+1)) - Input.get_action_strength("move_+X_Player" + str(player_index+1))
	dir.z = Input.get_action_strength("move_-Y_Player" + str(player_index+1)) - Input.get_action_strength("move_+Y_Player" + str(player_index+1))

	_velocity += dir * SPEED
	_on_ground = _floor_raycast.is_colliding()

	var sand = GameState.get_sand_system()

	# Picking up
	var action_location : Vector3 = translation - Vector3(0.0, 1.0, 0.0) + (_meshes.transform.basis.z * 2.0)
	sand.draw_dummy(action_location, player_index)
	if Input.is_action_just_pressed("action_pickup_Player" + str(player_index+1)):
		var sand_info = sand.extract_sand(action_location)

		if sand_info.size() > 0:
			var new_block = sand_info[0]

			_carried_blocks.push_back(new_block)
			_carried_blocks_info.push_back(sand_info[1])

			var block_collision = new_block.get_node("CollisionShape") as CollisionShape
			block_collision.disabled = true

			new_block.get_parent_spatial().remove_child(new_block)
			new_block.translation = Vector3(0.0, _carried_blocks.size() * 1.0 + 2.0, 0.0)
			add_child(new_block)

			$SandSoundPlayer.play()

	if Input.is_action_just_pressed("action_place_Player" + str(player_index+1)):
		if not _carried_blocks.empty():
			var in_front = action_location + Vector3(0.0, 10.0, 0.0)
			if sand.add_sand(in_front, _carried_blocks_info.back()):
				_carried_blocks.pop_back().queue_free()
				_carried_blocks_info.pop_back()
				$SandSoundPlayer.play()


	# "Physics"
	if _on_ground:
		if Input.is_action_just_pressed("jump_Player" + str(player_index+1)):
			_velocity.y += JUMP_POWER
			$JumpSoundPlayer.play()

		_velocity *= 1.0 - GROUND_FRICTION
	else:
		_velocity *= 1.0 - AIR_FRICTION
		_velocity += Vector3(0.0, -GRAVITY, 0.0)

	move_and_slide(_velocity * delta)

	# Dash
	if player_index == 0:
		$Mesh/DebugLabel.text = str(_dash_timer.time_left)

	if _dash_timer.time_left <= 0.0 and Input.is_action_just_pressed("dash_Player" + str(player_index+1)):
		_dash_timer.start()
		_velocity += DASH_POWER * _meshes.transform.basis.z

	# Facing
	if not Input.is_action_pressed("strafe_Player" + str(player_index+1)):
		var ground_velocity = _velocity
		ground_velocity.y = 0.0

		if ground_velocity.length_squared() > 100.0:
			var new_basis := Basis()
			new_basis.y = Vector3.UP
			new_basis.z = ground_velocity.normalized()
			new_basis.x = new_basis.z.cross(new_basis.y).normalized()

			_meshes.transform.basis = new_basis

	# Death by falling
	if translation.y < -4:
		$DrownSoundPlayer.play()
		GameState.report_player_death(player_index)
		_is_dead = true
