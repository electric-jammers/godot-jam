extends Control


onready var cam = $'../../Camera'

onready var tex = load('res://icon.png')

func _draw():
	draw_rect(Rect2(Vector2(0.0, 0.0), OS.window_size), Color(sin(OS.get_ticks_msec()), cos(OS.get_ticks_msec()), sin(OS.get_ticks_msec())))
	var world_point = cam.translation + Vector3(-1, 0, -1).normalized()
	if cam.is_position_behind(world_point):
		var pos_2d = cam.unproject_position(world_point)
		draw_texture_rect(tex, Rect2(Vector2(pos_2d.x - 100.0, pos_2d.y - 100.0), Vector2(200, 200)), false)
