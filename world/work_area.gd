class_name WorkArea
extends Node2D
## The play field. Spawns purchased cubes and routes the mouse to them depending on the
## tool mode: BREAK hits squares, MOVE drags whole cubes around.
## Cubes are this node's children; the last child is drawn on top.

signal mode_changed(mode: Mode)
## Emitted on every break-mode click on the field (hit or miss), for cursor animation.
signal tool_used(hit: bool)

enum Mode { BREAK, MOVE }

const SPAWN_GAP := 6.0
const SPAWN_STEP := 8.0
## Delay before upgraded squares start converting after a cube lands, and between each.
const CONVERT_DELAY := 0.15
const CONVERT_STAGGER := 0.08

@export var fx: Fx
## Region where cubes can be placed.
@export var bounds := Rect2(12, 30, 616, 300)
## Preferred region for new cubes (kept clear of the shop sidebar).
@export var spawn_bounds := Rect2(12, 30, 372, 300)
@export var drag_follow_speed := 30.0

var mode := Mode.BREAK

var _mouse_screen := Vector2.ZERO
var _dragged: Cube
var _drag_offset := Vector2.ZERO
var _hovered_cube: Cube
var _hovered_squares: Array[CubeSquare] = []
## While a click is being resolved, hits and breaks are collected here so the effects
## and payout play once per click instead of once per square.
var _resolving_click := false
var _clicked_hits: Array[CubeSquare] = []
var _clicked_breaks: Array[CubeSquare] = []


func _ready() -> void:
	Game.cube_purchased.connect(spawn_cube)


func set_mode(new_mode: Mode) -> void:
	if new_mode == mode:
		return
	if _dragged:
		_end_drag()
	mode = new_mode
	mode_changed.emit(mode)


func is_dragging() -> bool:
	return _dragged != null


func get_cubes() -> Array[Cube]:
	var cubes: Array[Cube] = []
	for child in get_children():
		if child is Cube and not child.is_queued_for_deletion():
			cubes.append(child)
	return cubes


func spawn_cube(type: CubeType) -> Cube:
	var cube := Cube.new()
	cube.setup(type)
	cube.position = _find_spawn_position(cube.get_size())
	add_child(cube)
	cube.square_hit.connect(_on_square_hit)
	cube.square_broken.connect(_on_square_broken)
	cube.completed.connect(_on_cube_completed)
	cube.landed.connect(_on_cube_landed)
	cube.play_spawn()
	_update_field_value()
	return cube


## Mouse position in world space, taken from the latest mouse event.
func get_mouse_world_position() -> Vector2:
	return get_canvas_transform().affine_inverse() * _mouse_screen


## Unbroken squares a pickaxe click at the point would hit. A size-1 pickaxe hits the
## square under the point on the topmost cube; bigger ones hit every square whose center
## lies in a box of that many squares centered on the point, across cubes.
func get_squares_in_reach(point: Vector2) -> Array[CubeSquare]:
	var result: Array[CubeSquare] = []
	var size := Game.get_pickaxe_size()
	if size <= 1:
		var cube := get_cube_at(point)
		var square := cube.get_square_at(point) if cube else null
		if square and not square.is_broken():
			result.append(square)
		return result
	var half := size * CubeSquare.SIZE / 2.0
	var reach := Rect2(point - Vector2.ONE * half, Vector2.ONE * half * 2.0)
	for cube in get_cubes():
		if cube.is_complete():
			continue
		for square in cube.get_squares():
			if not square.is_broken() and reach.has_point(square.global_position):
				result.append(square)
	return result


## Topmost cube under the point that can still be interacted with.
func get_cube_at(global_point: Vector2) -> Cube:
	for i in range(get_child_count() - 1, -1, -1):
		var cube := get_child(i) as Cube
		if cube and not cube.is_complete() and cube.has_point(global_point):
			return cube
	return null


# --- Input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mode_break"):
		set_mode(Mode.BREAK)
	elif event.is_action_pressed("mode_move"):
		set_mode(Mode.MOVE)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point := get_mouse_world_position()
		match mode:
			Mode.BREAK:
				_break_at(point)
			Mode.MOVE:
				_start_drag(point)
	else:
		return
	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# Seen here (before the GUI) so the position is tracked even over UI and a drag
	# always ends, even when released over the shop.
	if event is InputEventMouse:
		_mouse_screen = event.position
	if _dragged and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()


func _notification(what: int) -> void:
	# Drop whatever is held when the game pauses; the release would be missed otherwise.
	if what == NOTIFICATION_PAUSED and _dragged:
		_end_drag()


func _process(delta: float) -> void:
	var point := get_mouse_world_position()
	if _dragged:
		var target := _get_drag_target(point)
		_dragged.position = _dragged.position.lerp(target, 1.0 - exp(-drag_follow_speed * delta))
	_update_hover(point)


func _break_at(point: Vector2) -> void:
	var targets := get_squares_in_reach(point)
	_resolving_click = true
	for square in targets:
		(square.get_parent() as Cube).hit_square(square)
	_resolving_click = false
	_resolve_click()
	tool_used.emit(not targets.is_empty())


func _start_drag(point: Vector2) -> void:
	var cube := get_cube_at(point)
	if cube == null:
		return
	_dragged = cube
	_drag_offset = cube.position - point
	cube.move_to_front()
	cube.set_lifted(true)
	Sfx.play(&"pickup", 0.05)


func _end_drag() -> void:
	var cube := _dragged
	cube.position = _get_drag_target(get_mouse_world_position()).round()
	_dragged = null
	cube.set_lifted(false)
	fx.cube_dropped(cube)


## Where the dragged cube should be for a mouse position, kept inside the bounds.
func _get_drag_target(point: Vector2) -> Vector2:
	var size := _dragged.get_size()
	var area := Rect2(bounds.position + size / 2.0, bounds.size - size)
	return (point + _drag_offset).clamp(area.position, area.end)


func _update_hover(point: Vector2) -> void:
	var cube: Cube = null
	var squares: Array[CubeSquare] = []
	if get_viewport().gui_get_hovered_control() == null:
		if mode == Mode.MOVE:
			cube = _dragged if _dragged else get_cube_at(point)
		else:
			squares = get_squares_in_reach(point)
	_set_hovered(cube, squares)


func _set_hovered(cube: Cube, squares: Array[CubeSquare]) -> void:
	if _hovered_cube != cube:
		if is_instance_valid(_hovered_cube):
			_hovered_cube.hovered = false
		_hovered_cube = cube
		if cube:
			cube.hovered = true
	for square in _hovered_squares:
		if is_instance_valid(square) and square not in squares:
			square.hovered = false
	for square in squares:
		square.hovered = true
	_hovered_squares = squares


# --- Cube events -----------------------------------------------------------------

## Once a cube is down, owned upgrades decide which of its squares change type.
func _on_cube_landed(cube: Cube) -> void:
	fx.cube_landed(cube)
	var delay := CONVERT_DELAY
	for square in cube.get_squares():
		var new_type := Game.roll_square_type(cube.cube_type)
		if new_type != square.square_type:
			get_tree().create_timer(delay).timeout.connect(_convert_square.bind(square, new_type))
			delay += CONVERT_STAGGER


func _convert_square(square: CubeSquare, type: SquareType) -> void:
	if not is_instance_valid(square) or square.is_broken():
		return
	square.convert_to(type)
	fx.square_converted(square.global_position, type)
	_update_field_value()


func _on_square_hit(_cube: Cube, square: CubeSquare) -> void:
	if not square.is_broken():
		_clicked_hits.append(square)
	if not _resolving_click:
		_resolve_click()


func _on_square_broken(_cube: Cube, square: CubeSquare) -> void:
	_clicked_breaks.append(square)
	if not _resolving_click:
		_resolve_click()


## Pays out and plays the effects for everything the last click hit and broke.
func _resolve_click() -> void:
	if not _clicked_hits.is_empty():
		fx.squares_hit(_clicked_hits)
	if not _clicked_breaks.is_empty():
		var total := 0
		for square in _clicked_breaks:
			total += square.value
		_update_field_value()
		Game.earn(total)
		fx.squares_broken(_clicked_breaks)
	_clicked_hits = []
	_clicked_breaks = []


func _on_cube_completed(cube: Cube) -> void:
	if cube == _dragged:
		_end_drag()
	_set_hovered(null, [])
	cube.flash_white()
	Sfx.play(&"explode", 0.05)
	await fx.hitstop(0.09)
	fx.cube_exploded(cube)
	cube.queue_free()


## Reports how much money is still locked in unbroken squares, for the purchase guard.
func _update_field_value() -> void:
	var total := 0
	for cube in get_cubes():
		for square in cube.get_squares():
			if not square.is_broken():
				total += square.value
	Game.set_field_value(total)


# --- Placement -------------------------------------------------------------------

func _find_spawn_position(size: Vector2) -> Vector2:
	var spot: Variant = _find_free_spot(spawn_bounds, size)
	if spot == null:
		spot = _find_free_spot(bounds, size)
	if spot == null:
		var area := Rect2(spawn_bounds.position + size / 2.0, spawn_bounds.size - size)
		spot = Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
	var result: Vector2 = spot
	return result.round()


## Free spot closest to the middle of `area` (with a little randomness), or null.
func _find_free_spot(area: Rect2, size: Vector2) -> Variant:
	var occupied: Array[Rect2] = []
	for cube in get_cubes():
		occupied.append(cube.get_rect().grow(SPAWN_GAP))
	var center := area.get_center()
	var best: Variant = null
	var best_score := INF
	var x := area.position.x + size.x / 2.0
	while x <= area.end.x - size.x / 2.0:
		var y := area.position.y + size.y / 2.0
		while y <= area.end.y - size.y / 2.0:
			var candidate := Rect2(Vector2(x, y) - size / 2.0, size)
			if not occupied.any(func(r: Rect2) -> bool: return r.intersects(candidate)):
				var score := Vector2(x, y).distance_to(center) + randf() * 40.0
				if score < best_score:
					best_score = score
					best = Vector2(x, y)
			y += SPAWN_STEP
		x += SPAWN_STEP
	return best
