extends Spatial

func _ready():
	GameState.enter_stage(GameState.GameStage.DAY)
	GameState.connect("player_died", self, "_on_player_died")

func _input(event: InputEvent):
	if event is InputEventKey and event.scancode == KEY_T:
		var water = $WaterAnchor as WaterPlane
		water.animate_to_height(3.0)
		yield(water, "water_at_top")
		yield(get_tree().create_timer(1.0), "timeout")
		water.animate_away()

func _on_player_died(index : int):
	var winner := 0

	if index == 0:
		winner = 1

	$EndGameOverlay.display(winner + 1)
