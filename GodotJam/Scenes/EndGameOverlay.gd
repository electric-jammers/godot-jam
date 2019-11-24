extends Control

onready var green_label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/GreenScore
onready var red_label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/RedScore
onready var label = $ColorRect/MarginContainer/VBoxContainer/Label

func display(winner : int):
	var loser = 0
	if winner == 0:
		loser = 1
	if winner == -1:
		var tieMessage = randi()%3
		if tieMessage == 0:
			label.text = "It's a tie!"
		if tieMessage == 1:
			label.text = "No winners today!"
		if tieMessage == 2:
			label.text = "Well that's sad, no winners!"
	else:
		# Score labels
		GameState.players_win_count[winner] += 1
		green_label.text = String(GameState.players_win_count[0])
		red_label.text = String(GameState.players_win_count[1])

		var tieMessage = randi()%5
		if tieMessage == 0:
			label.text =  _get_player_color(winner) + " completely dominated " + _get_player_color(loser) + "!"
		if tieMessage == 1:
			label.text =  _get_player_color(winner) + " was clearly the better gamer."
		if tieMessage == 2:
			label.text =  "Epic gamer " + _get_player_color(winner) + " destroyed " + _get_player_color(loser) + "!"
		if tieMessage == 3:
			label.text = _get_player_color(winner) + " outsmarted " + _get_player_color(loser) + "!"
		if tieMessage == 4:
			label.text = _get_player_color(loser) + " sleeps with the fishes, " + _get_player_color(winner) + " won the game!"
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
