extends KinematicBody

# Subnode
onready var _meshes := $Mesh as Spatial
onready var _shovel := $ShovelAnimationPlayer as AnimationPlayer
onready var _floor_raycast := $FloorCast as RayCast
onready var _dash_timer := $DashTimer as Timer

# Consts
const AIR_FRICTION := 0.25
const GROUND_FRICTION := 0.3

const SPEED := 200.0

const DASH_POWER := 4000.0
const STEP_POWER := 1500.0
const JUMP_POWER := 3000.0

const GRAVITY := 100.0

# Public state
export(int, 0, 1) var player_index := 0

# Private state
var _velocity := Vector3()
var _on_ground := false
var _is_dead := false
var _is_animating_shovel := false

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
	var half_block = Vector3(SandSystem.BLOCK_SIZE, 0.0, SandSystem.BLOCK_SIZE) * 0.5
	var under_me = translation - Vector3(0.0, SandSystem.BLOCK_SIZE, 0.0)
	var facing_dir = _meshes.transform.basis.z

	if abs(facing_dir.x) > abs(facing_dir.z):
		facing_dir.z = 0
	else:
		facing_dir.x = 0

	var action_location: Vector3 = under_me + (facing_dir * SandSystem.BLOCK_SIZE) + half_block
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
			new_block.translation = Vector3(0.0, _carried_blocks.size() * (0.1 + SandSystem.BLOCK_SIZE) + 2.0, 0.0)
			add_child(new_block)

			$SandSoundPlayer.play()
			$Mesh/Particles/Sand.emitting = true
			_shovel.stop(true)
			_shovel.play("ShovelAnim")

	# Placing
	if Input.is_action_just_pressed("action_place_Player" + str(player_index+1)):
		if not _carried_blocks.empty():
			var in_front = action_location + Vector3(0.0, 10.0, 0.0)
			if sand.add_sand(in_front, _carried_blocks_info.back()):
				_carried_blocks.pop_back().queue_free()
				_carried_blocks_info.pop_back()
				$SandSoundPlayer.play()
				$Mesh/Particles/Sand.emitting = true
				_is_animating_shovel = true

	# "Physics"
	if _on_ground:
		if Input.is_action_just_pressed("jump_Player" + str(player_index+1)):
			_velocity.y += JUMP_POWER
			$JumpSoundPlayer.play()

		_velocity *= 1.0 - GROUND_FRICTION
	else:
		_velocity *= Vector3(1.0 - AIR_FRICTION, 1.0, 1.0 - AIR_FRICTION)
		_velocity += Vector3(0.0, -GRAVITY, 0.0)

	move_and_slide(_velocity * min(delta, 0.3))

	var slide_coll: KinematicCollision = get_slide_collision(0)
	if player_index == 0 and slide_coll != null:
		var sand_height_here = GameState.get_sand_system().get_sand_height(Vector2(translation.x, translation.z))
		var sand_height_there = GameState.get_sand_system().get_sand_height(Vector2(slide_coll.position.x, slide_coll.position.z))
		$Mesh/DebugLabel.text = "Hop: " + str(sand_height_here) + " -> " + str(sand_height_there)

	# Dash
	if _dash_timer.time_left <= 0.0 and Input.is_action_just_pressed("dash_Player" + str(player_index+1)):
		_dash_timer.start()
		_velocity += DASH_POWER * _meshes.transform.basis.z

	# Facing
	if not Input.is_action_pressed("strafe_Player" + str(player_index+1)):
		var ground_velocity = _velocity
		ground_velocity.y = 0.0

		if ground_velocity.length_squared() > 100.0:
			_face_dir(ground_velocity)
	else:
		var look_dir := Vector3()
		look_dir.x = Input.get_action_strength("look_-X_Player" + str(player_index+1)) - Input.get_action_strength("look_+X_Player" + str(player_index+1))
		look_dir.z = Input.get_action_strength("look_-Y_Player" + str(player_index+1)) - Input.get_action_strength("look_+Y_Player" + str(player_index+1))

		if look_dir.length_squared() > 0.5 * 0.5:
			_face_dir(look_dir)

	# Death by falling
	if translation.y < -4:
		$DrownSoundPlayer.play()
		GameState.report_player_death(player_index)
		while not _carried_blocks.empty():
			_carried_blocks.pop_back().queue_free()
			_carried_blocks_info.pop_back()
		_is_dead = true

func _face_dir(dir: Vector3):
	var new_basis := Basis()
	new_basis.y = Vector3.UP
	new_basis.z = dir.normalized()
	new_basis.x = new_basis.z.cross(new_basis.y).normalized()

	_meshes.transform.basis = new_basis
