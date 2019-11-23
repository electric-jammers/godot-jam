extends Control

func display(winner : int):
	$ColorRect/MarginContainer/VBoxContainer/Label.text = "Player " + String(winner) + " wins!"
	$AnimationPlayer.play("fade")
	$ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PlayAgainButton.grab_focus()


func _on_PlayAgainButton_pressed() -> void:
	get_tree().change_scene("res://Scenes/MainScene.tscn")


func _on_GoToMenuButton_pressed() -> void:
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
