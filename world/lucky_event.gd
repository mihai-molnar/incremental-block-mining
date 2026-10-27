class_name LuckyEvent
extends Node2D
## Every few minutes (Game.roll_lucky_interval) sends a Lucky Cube drifting across the
## field. Clicking it starts one of `frenzies` at random for Game.get_frenzy_duration().
## The countdown waits while a Lucky Cube is out or a frenzy is running.
## It comes after the work area in the tree, so it sees clicks first.

@export var fx: Fx
@export var frenzies: Array[Frenzy] = []
## Rows the Lucky Cube can drift along, kept clear of the HUD at the top and bottom.
@export var lane_top := 70.0
@export var lane_bottom := 290.0

var _wait := 0.0
var _cube: LuckyCube


func _ready() -> void:
	_wait = Game.roll_lucky_interval()


func _process(delta: float) -> void:
	if _cube or Game.has_timed_effects():
		return
	_wait -= delta
	if _wait <= 0.0:
		spawn()


## Sends a Lucky Cube across now, unless one is already out.
func spawn() -> void:
	if _cube:
		return
	_cube = LuckyCube.new()
	_cube.fx = fx
	add_child(_cube)
	_cube.launch(randf() < 0.5, randf_range(lane_top, lane_bottom), get_viewport_rect().size.x)
	_cube.escaped.connect(_on_escaped)
	fx.lucky_cube_appeared()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("dev_lucky_cube"):
		spawn()
		get_viewport().set_input_as_handled()
	elif _cube and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and _cube.has_point(get_canvas_transform().affine_inverse() * event.position):
		_catch()
		get_viewport().set_input_as_handled()


func _catch() -> void:
	var at := _cube.global_position
	_cube.queue_free()
	_cube = null
	_wait = Game.roll_lucky_interval()
	var frenzy := _pick_frenzy()
	if frenzy == null:
		return
	Game.add_timed_effect(frenzy, Game.get_frenzy_duration())
	fx.lucky_caught(at, frenzy)


func _pick_frenzy() -> Frenzy:
	var useful: Array[Frenzy] = []
	for frenzy in frenzies:
		if frenzy.is_useful():
			useful.append(frenzy)
	if useful.is_empty():
		return null
	return useful.pick_random()


func _on_escaped() -> void:
	_cube = null
	_wait = Game.roll_lucky_interval()
