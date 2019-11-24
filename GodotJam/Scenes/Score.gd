extends RichTextLabel


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.connect("game_over", self, "_on_game_over")

func _on_game_over(winner: int):
	if winner != -1:
		GameState.players_win_count[winner] += 1
		bbcode_text = "[color=red]" + String(GameState.players_win_count[0]) + "[/color] - [color=green]"+ String(GameState.players_win_count[1]) +"[/color]"
