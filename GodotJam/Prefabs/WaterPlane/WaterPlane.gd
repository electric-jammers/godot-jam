extends Spatial
class_name WaterPlane

# Subnodes
onready var _water_plane := $WaterPlane as MeshInstance
onready var _move_to_top_tween := $MoveToTop as Tween

# Signals
signal water_at_top

# Funcs
func _ready():
	var shader_mat = _water_plane.get_surface_material(0) as ShaderMaterial
	shader_mat.set_shader_param("waterTexture", load("res://Textures/SimpleCaustics.png"))
	GameState._water_system = self

func animate_to_height(target_height: float, duration: float = 1.0):
	_move_to_top_tween.interpolate_property(_water_plane, "translation:y", 0.0, target_height, duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	_move_to_top_tween.start()

	yield(_move_to_top_tween, "tween_all_completed")
	emit_signal("water_at_top")

func animate_away(duration: float = 1.0):
	_move_to_top_tween.interpolate_property(_water_plane, "translation:y", null, 0, duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	_move_to_top_tween.start()

	yield(_move_to_top_tween, "tween_all_completed")

func _process(delta):
	var shader_mat = _water_plane.get_surface_material(0) as ShaderMaterial
	shader_mat.set_shader_param("dayNightValue", GameState.get_normalized_day_night_cycle_time())
	var turb = pow(abs(GameState.get_normalized_day_night_cycle_time() - 0.5) * 2.0, 1.5)
	shader_mat.set_shader_param("waterTurbulence", turb)

func _exit_tree():
	GameState._water_system = null
