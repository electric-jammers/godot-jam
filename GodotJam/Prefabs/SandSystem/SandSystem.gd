extends Node

class_name SandSystem

var sand_voxels :=  PoolByteArray ()
var health := PoolByteArray()

var size_x : int = 100
var size_y : int = 100
var size_z : int = 100

var root_position = Vector3(50, 0, 50)

enum SandType {
	NONE,
	SOFT_SAND,
	HARD_SAND
}

var cube_spatial_dict = {}

onready var soft_sand_prefab = load("res://Prefabs/SandSystem/SoftSand.tscn")
onready var hard_sand_prefab = load("res://Prefabs/SandSystem/HardSand.tscn")

func index_to_world_position(index: int) -> Vector3:
	# warning-ignore:integer_division
	var y := index / (size_x * size_z)
	# warning-ignore:integer_division
	var z := (index - (y * size_x * size_z)) / size_x
	var x := index - ((y * size_x * size_z) + (z * size_x))
	var result := Vector3(x, y, z)
	return result - root_position

func position_to_index(position: Vector3) -> int:
	position = position + root_position
	var x := int(position.x)
	var y := int(position.y)
	var z := int(position.z)
	return internal_ints_to_index(x, y, z)

func internal_ints_to_index(var x, var y, var z) -> int:
	return int(x) + (int(y) * size_x * size_z) + (int(z) * (size_x))

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

func add_sand(position: Vector3, type_of_sand: int) -> void:
	if type_of_sand == SandType.NONE:
		print("Trying to add sand outside of the sand bounds!")
		return

	var position_index := position_to_index(position)
	if position_index < 0 or position_index >= sand_voxels.size():
		print("Trying to add sand outside of the sand bounds!")
		return

	if sand_voxels[position_index] != SandType.NONE:
		print("Replacing sand that is already there!")
		internal_remove_sand(position_index)

	var cube : Spatial
	var initial_health = 10
	match type_of_sand:
		SandType.SOFT_SAND:
			cube = soft_sand_prefab.instance()
			initial_health = 10
		SandType.HARD_SAND:
			cube = hard_sand_prefab.instance()
			initial_health = 20

	sand_voxels[position_index] = type_of_sand
	health[position_index] = initial_health
	add_child(cube)
	cube_spatial_dict[position_index] = cube
	cube.translation = index_to_world_position(position_index)


func remove_sand(position: Vector3) -> void:
	var position_index := position_to_index(position)
	internal_remove_sand(position_index)

func internal_remove_sand(position_index: int) -> void:
	if position_index < 0 or position_index >= sand_voxels.size():
		print("Trying to remove sand outside of the sand bounds!")
		return

	sand_voxels[position_index] =  SandType.NONE
	if cube_spatial_dict.has(position_index):
		var cube : Spatial = cube_spatial_dict[position_index]
		cube.queue_free()
		cube_spatial_dict.erase(position_index)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sand_voxels.resize(size_x * size_y * size_z)
	health.resize(size_x * size_y * size_z)
	for index in sand_voxels.size():
		sand_voxels.set(index, SandType.NONE)
		health.set(index, 0)

	for z in size_z:
		for x in size_x:
			add_sand(Vector3(x, 0, z) - root_position, SandType.HARD_SAND)
			add_sand(Vector3(x, 1, z) - root_position, SandType.HARD_SAND)
			add_sand(Vector3(x, 2, z) - root_position, SandType.SOFT_SAND)
			add_sand(Vector3(x, 3, z) - root_position, SandType.SOFT_SAND)



