extends Spatial

func _ready():
	GameState.enter_stage(GameState.GameStage.DAY)

func _input(event: InputEvent):
	if event is InputEventKey and event.scancode == KEY_T:
		var water = $WaterAnchor as WaterPlane
		water.animate_to_height(3.0)
		yield(water, "water_at_top")
		yield(get_tree().create_timer(1.0), "timeout")
		water.animate_away()
