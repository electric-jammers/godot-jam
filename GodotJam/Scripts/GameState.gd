extends Node

enum GameStage {
	FRONTEND,
	DAY,
	NIGHT
}

var current_time := 0.0
var stage = GameStage.FRONTEND

func enter_stage(new_game_stage):
	stage = new_game_stage
