extends Node

class_name SandSystem

var arr :=  PoolByteArray ()

var size_x : int = 100
var size_y : int = 100
var size_z : int = 100

enum SandState {
	NONE,
	SAND
}

var cube_spatial_dict = {}

func position_to_int(position: Vector3) -> PoolIntArray:
	var arr := PoolIntArray()
	arr.append(int(position.x))
	arr.append(int(position.y))
	arr.append(int(position.z))
	return arr


func position_to_index(position: Vector3) -> int:
	var int_positions := position_to_int(position)
	return int(int_positions[0]) + (int(int_positions[1]) * size_x) + (int(int_positions[2]) * (size_x * size_y))


func add_sand(position: Vector3) -> void:
	var position_index = position_to_index(position)
	arr.set(position_to_index(position), SandState.SAND)
	# cube_spatial_dict[position_index] = # new spawned cube

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	arr.resize(size_x * size_y * size_z)
	for index in arr.size():
		arr.set(index, SandState.NONE)

	print(arr.size())

	# var mesh := Mesh.new()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
