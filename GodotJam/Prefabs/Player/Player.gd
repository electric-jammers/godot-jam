extends KinematicBody


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
var _velocity := Vector3()

var _airFriction := 0.02
var _groundFriction := 0.05
var _speed := 500
var _gravity := 500

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	var dir := Vector3()

	dir.x = Input.get_action_strength("move_+X_Player1") - Input.get_action_strength("move_-X_Player1")

	dir.z = Input.get_action_strength("move_+Y_Player1") - Input.get_action_strength("move_-Y_Player1")

	if(is_on_floor())
		_velocity *= 1.0 - _groundFriction
	else
		_velocity *= 1.0 - _airFriction
		_velocity += _gravity * delta


	move_and_slide(_velocity)


