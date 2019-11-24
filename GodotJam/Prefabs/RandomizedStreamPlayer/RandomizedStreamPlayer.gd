extends AudioStreamPlayer

export(Array, AudioStream) var stream_array
export var looping := false
export var loop_duration := 10
export var random_spread := 0.5

onready var timer = $Timer

func _ready() -> void:
	randomize()
	if looping:
		timer.start(loop_duration * random_spread)

func play(from_position := 0.0):
	var sound_index = randi() % stream_array.size()

	stream = stream_array[sound_index]

	if looping:
		var new_time := loop_duration + 0.1

		loop_duration += rand_range(-1 * random_spread, random_spread) * loop_duration
		timer.start(loop_duration)

	.play(from_position)

func _on_Timer_timeout() -> void:
	play(0.0)
