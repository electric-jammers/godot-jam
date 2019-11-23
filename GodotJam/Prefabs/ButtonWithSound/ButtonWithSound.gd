extends Button

onready var sound_player : AudioStreamPlayer = $AudioStreamPlayer

func _on_Button_pressed() -> void:
	sound_player.play(0.3)
