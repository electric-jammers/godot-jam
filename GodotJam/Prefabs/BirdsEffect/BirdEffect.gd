tool
extends Spatial

onready var animation_player = $AnimationPlayer

var bird_scene : PackedScene = preload("res://Scenes/birdie.tscn")

export var birds_count := 4 setget set_birds_count
export var radius := 1
export var speed := 1
export var duration := 2

var _phase := 0.0
var _birds : Array

func _ready() -> void:
	set_birds_count(birds_count)
	pass


func set_birds_count(count : int):
	for bird in _birds:
		bird.queue_free()

	_birds.clear()

	for i in range(count):
		var bird = bird_scene.instance()
		var phase := ((PI * 2) / count) * i

		bird.rotate_y(phase)
		bird.translate(Vector3(radius, 0, 0))
		bird.scale = Vector3(0.2, 0.2, 0.2)

		add_child(bird)
		_birds.append(bird)

func play():
	animation_player.play("Fade")


func _process(delta : float):
	rotation.y += delta * speed
