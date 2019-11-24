extends Control

onready var label : Label = $ColorRect/MarginContainer/VBoxContainer/Label

func display(winner : int):
	if winner == -1:
		label.text = "It's a tie!"
	else:
		label.text =  _get_player_color(winner) + " player wins!"
	$AnimationPlayer.play("fade")
	$ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PlayAgainButton.grab_focus()

func _get_player_color(player_index : int) -> String:
	if player_index == 0:
		return "Red"
	elif player_index == 1:
		return "Green"
	else:
		return ""

func _on_PlayAgainButton_pressed() -> void:
	get_tree().change_scene("res://Scenes/MainScene.tscn")


func _on_GoToMenuButton_pressed() -> void:
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
