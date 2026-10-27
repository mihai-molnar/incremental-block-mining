class_name LuckyEvent
extends Node2D
## Sends a Lucky Cube drifting across the field once the player has broken
## Game.roll_lucky_interval() squares, with clicks and the chain reactions they set off.
## Drones' squares don't count, so it can't be waited out. Clicking it starts one of
## `frenzies` at random (Frenzy.start). The count waits while a Lucky Cube is out, a
## frenzy is running or the pickaxe is shielded, and stops when the pickaxe breaks.
## It comes after the work area in the tree, so it sees clicks first.

@export var fx: Fx
@export var work_area: WorkArea
@export var frenzies: Array[Frenzy] = []
## Rows the Lucky Cube can drift along, kept clear of the HUD at the top and bottom.
@export var lane_top := 70.0
@export var lane_bottom := 290.0

## Squares the player still has to break for the next Lucky Cube.
var _squares_left := 0
var _cube: LuckyCube


func _ready() -> void:
	_squares_left = Game.roll_lucky_interval()
	work_area.squares_broken.connect(_on_squares_broken)


func _on_squares_broken(count: int, soft: bool) -> void:
	if soft or _cube or Game.has_timed_effects() or Game.pickaxe_shield > 0 or not Game.is_run_active():
		return
	_squares_left -= count
	if _squares_left <= 0:
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
	elif _cube and Game.is_run_active() and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed \
			and _cube.has_point(get_canvas_transform().affine_inverse() * event.position):
		_catch()
		get_viewport().set_input_as_handled()


func _catch() -> void:
	var at := _cube.global_position
	_cube.queue_free()
	_cube = null
	_squares_left = Game.roll_lucky_interval()
	var frenzy := _pick_frenzy()
	if frenzy == null:
		return
	frenzy.start()
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
	_squares_left = Game.roll_lucky_interval()
