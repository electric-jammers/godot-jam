extends Node

# Emitted when stage changes
signal stage_changed(new_stage)

enum GameStage {
	FRONTEND,

	DAY,
	NIGHT
}

const STAGE_LEN = 30.0

var current_time := 0.0
var time_in_stage := 0.0

var stage = GameStage.FRONTEND

# 0 = noon, 0.5 = midnight, 1 = noon
func get_normalized_stage_time():
	return time_in_stage / STAGE_LEN

func _process(delta: float):
	if stage == GameStage.FRONTEND:
		return

	current_time += delta
	time_in_stage += delta

func enter_stage(new_game_stage):
	stage = new_game_stage
	emit_signal("stage_changed", new_game_stage)

	time_in_stage = 0.0
