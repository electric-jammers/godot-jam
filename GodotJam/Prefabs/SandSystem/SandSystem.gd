extends Node

class_name SandSystem

var sand_voxels :=  PoolByteArray ()
var health := PoolByteArray()

var size_x : int = 26
var size_y : int = 16
var size_z : int = 16

const BLOCK_SIZE := 1.5

var root_position = Vector3(12.5, 0, 7.5) * BLOCK_SIZE

enum SandType {
	NONE,
	SOFT_SAND,
	HARD_SAND,
	ROCK
}

var cube_spatial_dict = {}
var locations_to_drop = []

onready var soft_sand_prefab = load("res://Prefabs/SandSystem/SoftSand.tscn")
onready var hard_sand_prefab = load("res://Prefabs/SandSystem/HardSand.tscn")
onready var rock_prefab = load("res://Prefabs/SandSystem/Rock.tscn")
onready var dummy_prefab = load("res://Prefabs/SandSystem/Dummy.tscn")

var dummies = {}

func index_to_world_position(index: int) -> Vector3:
	# warning-ignore:integer_division
	var y := index / (size_x * size_z)
	# warning-ignore:integer_division
	var z := (index - (y * size_x * size_z)) / size_x
	var x := index - ((y * size_x * size_z) + (z * size_x))
	var result := Vector3(x, y, z)
	return (result * BLOCK_SIZE) - root_position

func position_to_index(position: Vector3) -> int:
	position = (position + root_position) / BLOCK_SIZE
	var x := int(position.x)
	var y := int(position.y)
	var z := int(position.z)
	return internal_ints_to_index(x, y, z)


func internal_ints_to_index(var x, var y, var z) -> int:
	return int(x) + (int(y) * size_x * size_z) + (int(z) * (size_x))

func get_sand_height(xz_pos: Vector2) -> float:

	var y_lowest :int= 0
	var x := int (xz_pos.x - root_position.x)
	var z := int (xz_pos.y - root_position.z)

	for y in size_y:
		var position_index = internal_ints_to_index(x, y, z)
		if position_index < 0 or position_index >= sand_voxels.size():
			print("Trying to get sand height out of bounds!")
			return -1.0

		if sand_voxels[position_index] == SandType.NONE:
			return float(y)

	return float(size_y)


func damage_sand(position: Vector3, damage_amount: int) -> void:
	var position_index := position_to_index(position)
	internal_damage_sand(position_index, damage_amount)

func internal_damage_sand(position_index: int, damage_amount: int) -> void:
	if position_index < 0 or position_index >= sand_voxels.size():
		print("Trying to damage sand outside of the sand bounds!")
		return

	if sand_voxels[position_index] == SandType.NONE:
		return

	var health_value := health[position_index] - damage_amount
	if(health_value <= 0):
		health[position_index] = 0
		internal_remove_sand(position_index)
	else:
		health[position_index] = health_value

func damage_all_sand_up_to_height(max_height: int, damage_amount: int) -> void:
	for height in max_height:
		for z in size_z:
			for x in size_x:
				var postition_index := internal_ints_to_index(x, height, z)
				internal_damage_sand(postition_index, damage_amount)

func add_sand(position: Vector3, type_of_sand: int) -> bool:
	if type_of_sand == SandType.NONE:
		print("Trying to add sand outside of the sand bounds!")
		return false

	var position_index := position_to_index(position)
	if position_index < 0 or position_index >= sand_voxels.size():
		print("Trying to add sand outside of the sand bounds!")
		return false

	if sand_voxels[position_index] != SandType.NONE:
		print("Replacing sand that is already there!")
		internal_remove_sand(position_index)
		return false

	# make sure that the sand is stacked on top of other sand!
	var next_position_to_check := position
	while int(next_position_to_check.y) > 0:
		next_position_to_check.y = next_position_to_check.y - 1
		var next_position_index_to_check := position_to_index(next_position_to_check)
		if sand_voxels[next_position_index_to_check] != SandType.NONE:
			break
		position_index = next_position_index_to_check
		position = next_position_to_check

	var cube : Spatial
	var initial_health = 10
	match type_of_sand:
		SandType.SOFT_SAND:
			cube = soft_sand_prefab.instance()
			initial_health = 10
		SandType.HARD_SAND:
			cube = hard_sand_prefab.instance()
			initial_health = 20
		SandType.ROCK:
			cube = rock_prefab.instance()
			initial_health = 30

	sand_voxels[position_index] = type_of_sand
	health[position_index] = initial_health
	add_child(cube)
	cube_spatial_dict[position_index] = cube
	cube.translation = index_to_world_position(position_index)
	return true

func draw_dummy(position: Vector3, dummy_index: int) -> void:
	var position_index = position_to_index(position)
	var snapped_position = index_to_world_position(position_index)
	if !dummies.has(dummy_index):
		var dummy = dummy_prefab.instance()
		add_child(dummy)
		dummies[dummy_index] = dummy
	var dummy = dummies[dummy_index]
	dummy.translation = snapped_position
	dummy.translation.y += 1.0


func remove_sand(position: Vector3) -> void:
	var position_index := position_to_index(position)
	internal_remove_sand(position_index)

func extract_sand(position: Vector3) -> Array:
	var position_index := position_to_index(position)
	return internal_extract_sand(position_index)

func internal_remove_sand(position_index: int) -> void:
	var sand_object := internal_extract_sand(position_index)
	if sand_object.size() > 0:
		sand_object[0].queue_free()

func internal_extract_sand(position_index: int) -> Array:
	if position_index < 0 or position_index >= sand_voxels.size():
		#print("Trying to remove sand outside of the sand bounds!")
		return []

	var sand_type := sand_voxels[position_index]
	if sand_type == SandType.NONE:
		#print("No sand to extract here!")
		return []

	sand_voxels[position_index] =  SandType.NONE
	if cube_spatial_dict.has(position_index):
		var cube : Spatial = cube_spatial_dict[position_index]
		cube_spatial_dict.erase(position_index)
		locations_to_drop.append(position_index)
		return [cube, sand_type]

	return []

func drop_sand() -> void:
	for location_to_drop in locations_to_drop:
		var y_lowest :int= location_to_drop / (size_x * size_z)
		var z :int= (location_to_drop - (y_lowest * size_x * size_z)) / size_x
		var x :int= location_to_drop - ((y_lowest * size_x * size_z) + (z * size_x))

		for y in range(y_lowest, size_y):
			var index : int = internal_ints_to_index(x, y, z)

			if sand_voxels[index] == SandType.NONE:
				continue

			for y_below in range(y - 1, y_lowest - 1, -1):
				if y_lowest < 0:
					continue
				var below_index := internal_ints_to_index(x, y_below, z)
				if sand_voxels[below_index] != SandType.NONE:
					break

				sand_voxels[below_index] = sand_voxels[index]
				health[below_index] = health[index]
				cube_spatial_dict[below_index] = cube_spatial_dict[index]
				sand_voxels[index] = SandType.NONE
				health[index] = 0
				cube_spatial_dict.erase(index)

				cube_spatial_dict[below_index].translation = index_to_world_position(below_index)
				index = below_index

	locations_to_drop.clear()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sand_voxels.resize(size_x * size_y * size_z)
	health.resize(size_x * size_y * size_z)
	for index in sand_voxels.size():
		sand_voxels.set(index, SandType.NONE)
		health.set(index, 0)

	for z in size_z:
		for x in size_x:
			add_sand(Vector3(x * BLOCK_SIZE, 0, z * BLOCK_SIZE) - root_position, SandType.ROCK)
			add_sand(Vector3(x * BLOCK_SIZE, 1, z * BLOCK_SIZE) - root_position, SandType.HARD_SAND)
			add_sand(Vector3(x * BLOCK_SIZE, 2, z * BLOCK_SIZE) - root_position, SandType.HARD_SAND)
			add_sand(Vector3(x * BLOCK_SIZE, 3, z * BLOCK_SIZE) - root_position, SandType.SOFT_SAND)
			add_sand(Vector3(x * BLOCK_SIZE, 4, z * BLOCK_SIZE) - root_position, SandType.SOFT_SAND)

	GameState._sand_system = self


func _exit_tree():
	GameState._sand_system = null

func _process(delta: float) -> void:
	call_deferred("drop_sand")




