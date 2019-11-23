extends Node

class_name SandSystem

var sand_voxels :=  PoolByteArray ()
var damage := PoolByteArray()

var size_x : int = 100
var size_y : int = 100
var size_z : int = 100

enum SandState {
	NONE,
	SAND
}

var cube_spatial_dict = {}

onready var cube_scene = load("res://Prefabs/SandSystem/SandCube.tscn")

func position_to_int(position: Vector3) -> PoolIntArray:
	var arr := PoolIntArray()
	arr.append(int(position.x))
	arr.append(int(position.y))
	arr.append(int(position.z))
	return arr

func fixed_position(position: Vector3) -> Vector3:
	var x := int(position.x)
	var y := int(position.y)
	var z := int(position.z)
	var result := Vector3(x, y, z)
	return result

func position_to_index(position: Vector3) -> int:
	var int_positions := position_to_int(position)
	return int(int_positions[0]) + (int(int_positions[1]) * size_x) + (int(int_positions[2]) * (size_x * size_y))


func add_sand(position: Vector3) -> void:
	var position_index := position_to_index(position)
	sand_voxels.set(position_to_index(position), SandState.SAND)
	damage.set(position_to_index(position), 0)
	var cube : Spatial = cube_scene.instance()
	add_child(cube)
	cube_spatial_dict[position_index] = cube
	cube.translation = fixed_position(position)

func remove_sand(position: Vector3) -> void:
	var position_index := position_to_index(position)
	sand_voxels.set(position_to_index(position), SandState.NONE)
	if cube_spatial_dict.has(position_index):
		var cube : Spatial = cube_spatial_dict[position_index]
		cube.queue_free()
		cube_spatial_dict.erase(position_index)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sand_voxels.resize(size_x * size_y * size_z)
	damage.resize(size_x * size_y * size_z)
	for index in sand_voxels.size():
		sand_voxels.set(index, SandState.NONE)
		damage.set(index, 0)

	print(sand_voxels.size())

	add_sand(Vector3(0, 0, 0))

	# var mesh := Mesh.new()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
