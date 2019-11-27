extends KinematicBody
class_name Player

# Subnode
onready var _meshes := $Mesh as Spatial
onready var _shovel := $ShovelAnimationPlayer as AnimationPlayer
onready var _floor_raycast := $FloorCast as RayCast
onready var _dash_timer := $DashTimer as Timer

onready var _winner_cam_parent := $CamParent as Spatial
onready var _winner_cam := $CamParent/Camera as Camera

onready var _walking_particles = $Mesh/Particles/Walking
onready var _sand_particles = $Mesh/Particles/Sand
onready var _bubble_particles = $Mesh/Particles/Bubbles
onready var _step_timer := $StepTimer as Timer
onready var _pickup_recently_timer := $PickupTimer as Timer
onready var _birds_effect := $Mesh/Particles/BirdsEffect

# Consts
const AIR_FRICTION := 0.25
const GROUND_FRICTION := 0.3

const SPEED := 200.0

const DASH_POWER := 4000.0
const STEP_POWER := 1800.0
const JUMP_POWER := 3000.0

const GRAVITY := 100.0

const HIT_FORCE := 11000
const HIT_FORCE_UP := 2000

# Public state
export(int, 0, 1) var player_index := 0

# Private state
var _velocity := Vector3()
var _hit_velocity := Vector3()
var _won := false
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

	GameState.connect("game_over", self, "_on_game_over")
	GameState.connect("player_hit", self, "_on_player_hit")

func _physics_process(delta: float):
	if _won:
		_winner_cam_parent.rotate_y(delta * 2);

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
	var action_location: Vector3 = _get_pickup_action_location()
	var dummy = sand.draw_dummy(action_location, player_index)

	if Input.is_action_just_pressed("action_pickup_Player" + str(player_index+1)):
		var dummy_area =  dummy.get_node("Area") as Area
		var overlaps = dummy_area.get_overlapping_bodies()

		for overlap in overlaps:
			var player = overlap as Player
			if player != null and player != self:
				GameState.report_player_hit(player.player_index, _meshes.transform.basis.z * HIT_FORCE + (_meshes.transform.basis.y * HIT_FORCE_UP))
				return

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

			_pickup_recently_timer.start()

			$SandSoundPlayer.play()
			_sand_particles.emitting = true
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
				_sand_particles.emitting = true

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

	# Getting hit
	if _hit_velocity.length_squared() > 0.01:
		_velocity += _hit_velocity
		_hit_velocity = Vector3()
		_birds_effect.play()

	var new_velocity := move_and_slide(_velocity / 60.0)
	var horizontal_velocity := Vector2(new_velocity.x, new_velocity.z)

	if horizontal_velocity.length_squared() > 0.5 and abs(new_velocity.y) < 0.0001:
		_walking_particles.emitting = true

	# Detect walls and hop up (only if not hopped or collected recently)
	if _step_timer.time_left <= 0.0 and _pickup_recently_timer.time_left <= 0.0:
		for slide_index in get_slide_count():
			var slide_coll: KinematicCollision = get_slide_collision(slide_index )

			var sand_height_here = GameState.get_sand_system().get_sand_height(translation + Vector3(SandSystem.BLOCK_SIZE, 0.0, SandSystem.BLOCK_SIZE) * 0.5)
			var sand_height_there = GameState.get_sand_system().get_sand_height(_get_pickup_action_location())

			# if player_index == 0:
				# $Mesh/DebugLabel.text = "Hop: " + str(sand_height_here) + " -> " + str(sand_height_there)

			if sand_height_there == sand_height_here + 1:
				_velocity.y += STEP_POWER
				_step_timer.start()
				break

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

	# Death by drowning
	if translation.y < -4:
		$DrownSoundPlayer.play()
		GameState.report_player_death(player_index)
		while not _carried_blocks.empty():
			_carried_blocks.pop_back().queue_free()
			_carried_blocks_info.pop_back()
		_is_dead = true
		_bubble_particles.emitting = true

func _get_pickup_action_location() -> Vector3:
	var half_block = Vector3(SandSystem.BLOCK_SIZE, 0.0, SandSystem.BLOCK_SIZE) * 0.5
	var under_me = translation #- Vector3(0.0, SandSystem.BLOCK_SIZE, 0.0)
	var facing_dir = _meshes.transform.basis.z

	if abs(facing_dir.x) > abs(facing_dir.z):
		facing_dir.z = 0
	else:
		facing_dir.x = 0

	var action_location: Vector3 = under_me + (facing_dir * SandSystem.BLOCK_SIZE) + half_block
	return action_location



func _face_dir(dir: Vector3):
	var new_basis := Basis()
	new_basis.y = Vector3.UP
	new_basis.z = dir.normalized()
	new_basis.x = new_basis.z.cross(new_basis.y).normalized()

	_meshes.transform.basis = new_basis


func _on_game_over(winner: int):
	if player_index == winner:
		_winner_cam.make_current()
		_won = true

func _on_player_hit(hit_player: int, hit_velocity : Vector3):
	if player_index == hit_player:
		_hit_velocity = hit_velocity
