extends AudioStreamPlayer

export(Array, AudioStream) var stream_array

func _ready() -> void:
	randomize()

func play(from_position := 0.0):
	var sound_index = randi() % stream_array.size()

	stream = stream_array[sound_index]
	.play(from_position)
