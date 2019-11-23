extends Node

# Emitted when stage changes
signal stage_changed(new_stage)
signal player_died(player_index)

enum GameStage {
	FRONTEND,

	DAY,
	NIGHT
}

const STAGE_LEN := 5.0

var current_time := 0.0
var time_in_stage := 0.0
var current_water_height := 2.0
var current_water_damage := 5

var stage = GameStage.FRONTEND

var _sand_system: SandSystem
var _water_system: WaterPlane

# 0 = noon, 0.5 = midnight, 1 = noon
func get_normalized_day_night_cycle_time() -> float:
	var result : float
	if stage == GameStage.NIGHT:
		result = 0.75 + (get_normalized_stage_time()/2)
		if result > 1.0:
			result = result - 1.0
	elif stage == GameStage.DAY:
		result = 0.25 + (get_normalized_stage_time()/2)
	else:
		result =  0.0
	return result

func get_normalized_stage_time() -> float:
	return time_in_stage / STAGE_LEN

func _process(delta: float):
	if _water_system == null:
		return
	current_time += delta
	time_in_stage += delta
	if get_normalized_stage_time() > 1.0:
		if stage == GameStage.DAY:
			enter_stage(GameStage.NIGHT)
		else:
			enter_stage(GameStage.DAY)

func enter_stage(new_game_stage):
	if stage == new_game_stage:
		return

	if new_game_stage == GameStage.DAY and stage == GameStage.NIGHT:
		_water_system.animate_away()
	if new_game_stage == GameStage.NIGHT:
		_water_system.animate_to_height(current_water_height)
		_sand_system.damage_all_sand_up_to_height(current_water_height, current_water_damage)

	stage = new_game_stage
	emit_signal("stage_changed", new_game_stage)

	time_in_stage = 0.0

func get_sand_system() -> SandSystem:
	return _sand_system

func report_player_death(player_index: int):
	print("AAAAAAAAAH Player Died: " + str(player_index))
	emit_signal("player_died", player_index)
