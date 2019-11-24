extends Node

# Emitted when stage changes
signal stage_changed(new_stage)
signal player_died(player_index)
signal player_hit(player_index, hit_velocity)
signal game_over(winning_player_index)

enum GameStage {
	FRONTEND,

	DAY,
	NIGHT,

	GAME_OVER
}

const STAGE_LEN := 5.0

var current_time := 0.0
var time_in_stage := 0.0
var current_water_height := 2.0
var current_water_damage := 5

var stage = GameStage.FRONTEND

var _sand_system: SandSystem
var _water_system: WaterPlane

# Player death handling
const GAME_OVER_TIMER_DURATION = 1.0
var game_over_timer := Timer.new()
var alive_players := [true, true]

func _ready() -> void:
	game_over_timer.one_shot = true
	game_over_timer.wait_time = GAME_OVER_TIMER_DURATION
	game_over_timer.connect("timeout", self, "_game_over_timer_timeout")
	add_child(game_over_timer)

# 0 = midnight, 0.5 = noon, 1 = midnight
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
	if (stage == GameStage.DAY or stage == GameStage.NIGHT) and  get_normalized_stage_time() > 1.0:
		if stage == GameStage.DAY:
			enter_stage(GameStage.NIGHT)
		elif stage == GameStage.NIGHT:
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

	if new_game_stage == GameStage.GAME_OVER:
		var dm0 = _sand_system.dummies[0] as MeshInstance
		dm0.visible = false;
		var dm1 = _sand_system.dummies[1] as MeshInstance
		dm1.visible = false;

	time_in_stage = 0.0

func get_sand_system() -> SandSystem:
	return _sand_system

func report_player_death(player_index: int):
	alive_players[player_index] = false
	game_over_timer.start()

	emit_signal("player_died", player_index)

func report_player_hit(player_index: int, hit_force : Vector3):
	emit_signal("player_hit", player_index, hit_force)

func _game_over_timer_timeout():
	var winning_player := -1

	for i in range(alive_players.size()):
		if alive_players[i]:
			winning_player = i
		alive_players[i] = true
	enter_stage(GameStage.GAME_OVER)

	emit_signal("game_over", winning_player)
