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
## Pause between the links of a chain reaction, so each wave of explosions reads on its own.
const CHAIN_DELAY := 0.12


## A square that broke and is going off: an explosive, breaking a ring `radius` squares
## out, or lightning, breaking its row and column. Keeps its own copy of where, since by
## the time a chain reaction reaches it, its cube may be gone.
class Blast:
	var at: Vector2
	var radius: int
	var lines: bool
	## Lightning: the cube it was on, which its bolts span at the least.
	var area: Rect2

	func _init(center: Vector2, reach: int, strike_lines := false, cube_area := Rect2()) -> void:
		at = center
		radius = reach
		lines = strike_lines
		area = cube_area


@export var fx: Fx
@export var combo: Combo
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
## What the squares broken by the click being resolved pay, multiplier squares included.
var _clicked_value := 0
## Each cube's value multiplier as the click being resolved first reached it, so breaking
## a multiplier square doesn't take the bonus off the squares broken alongside it.
var _cube_bonus := {}
## Explosive and lightning squares broken since the last blast went off; the next wave
## of the chain.
var _pending_blasts: Array[Blast] = []


func _ready() -> void:
	Game.cube_purchased.connect(spawn_cube)
	Game.saving.connect(_on_saving)
	_restore_cubes(Game.take_saved("cubes", []))


func set_mode(new_mode: Mode) -> void:
	if new_mode == mode:
		return
	if _dragged:
		_end_drag()
	mode = new_mode
	mode_changed.emit(mode)


func is_dragging() -> bool:
	return _dragged != null


## The cube being dragged, or null.
func get_held_cube() -> Cube:
	return _dragged


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
	_add_cube(cube)
	cube.play_spawn()
	_update_field_value()
	return cube


## A mining drone's hit on one square. Resolved like a click, with softer effects.
func drone_hit(square: CubeSquare) -> void:
	_hit_squares([square], true)


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


## Unbroken squares a blast at the point takes out: every square whose center is within
## `radius` and a half squares of it, across cubes. Radius 1 is the full ring of 8 around
## the explosive; bigger ones round off the corners.
func get_squares_in_blast(center: Vector2, radius: int) -> Array[CubeSquare]:
	var result: Array[CubeSquare] = []
	var reach := (radius + 0.5) * CubeSquare.SIZE
	for cube in get_cubes():
		if cube.is_complete():
			continue
		for square in cube.get_squares():
			if not square.is_broken() and square.global_position.distance_to(center) <= reach:
				result.append(square)
	return result


## Unbroken squares a lightning square at the point strikes: every square whose center
## lies within half a square of its row or column, on any cube.
func get_squares_in_lines(center: Vector2) -> Array[CubeSquare]:
	var result: Array[CubeSquare] = []
	for cube in get_cubes():
		if cube.is_complete():
			continue
		for square in cube.get_squares():
			var offset := square.global_position - center
			if not square.is_broken() and (absf(offset.x) < CubeSquare.HALF or absf(offset.y) < CubeSquare.HALF):
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
	if not targets.is_empty():
		combo.add_hit()
	_hit_squares(targets, false)
	tool_used.emit(not targets.is_empty())


## Hits the squares as one click. Explosives the click breaks go off as part of the same
## click, so its payout includes what they blew up. Soft clicks (drones) play quieter
## effects, never crit and don't get the combo multiplier.
func _hit_squares(targets: Array[CubeSquare], soft: bool) -> void:
	var crit_chance := 0.0 if soft else Game.get_crit_chance()
	var crits: Array[CubeSquare] = []
	_resolving_click = true
	for square in targets:
		var damage := 1
		# A crit only shows when it saves clicks: a square one hit from breaking can't crit.
		if square.hp > 1 and randf() < crit_chance:
			damage = square.hp
			crits.append(square)
		_hit(square, damage)
	_detonate(_take_pending_blasts())
	_resolving_click = false
	if not crits.is_empty():
		fx.critical_hits(crits)
	_resolve_click(soft)


## One link of a chain reaction: explosives caught in the previous blasts go off and pay
## out together. Any explosives they catch are the next link. Chains a drone set off stay soft.
func _chain_blasts(blasts: Array[Blast], soft: bool) -> void:
	_resolving_click = true
	_detonate(blasts)
	_resolving_click = false
	_resolve_click(soft)


## Breaks every square each blast reaches, whatever clicks it had left.
func _detonate(blasts: Array[Blast]) -> void:
	for blast in blasts:
		var struck: Array[CubeSquare] = []
		if blast.lines:
			struck = get_squares_in_lines(blast.at)
			fx.lightning(blast.at, _get_bolt_span(blast, struck))
		else:
			struck = get_squares_in_blast(blast.at, blast.radius)
			fx.explosion(blast.at, blast.radius)
		for square in struck:
			_hit(square, square.hp)


## How far a lightning blast's bolts reach: across its cube and every square they struck.
func _get_bolt_span(blast: Blast, struck: Array[CubeSquare]) -> Rect2:
	var span := blast.area if blast.area.has_area() else Rect2(blast.at, Vector2.ZERO)
	for square in struck:
		span = span.merge(Rect2(square.global_position - Vector2.ONE * CubeSquare.HALF, Vector2.ONE * CubeSquare.SIZE))
	return span


## Hits a square as part of the click being resolved. The click's first hit on each cube
## notes the cube's value multiplier for every square the click breaks there.
func _hit(square: CubeSquare, damage: int) -> void:
	var cube := square.get_parent() as Cube
	if not _cube_bonus.has(cube):
		_cube_bonus[cube] = cube.get_value_multiplier()
	cube.hit_square(square, damage)


func _take_pending_blasts() -> Array[Blast]:
	var blasts := _pending_blasts
	_pending_blasts = []
	return blasts


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
		var new_type := Game.roll_square_type(cube.cube_type, square.square_type)
		if new_type != square.square_type:
			get_tree().create_timer(delay).timeout.connect(_convert_square.bind(square, new_type))
			delay += CONVERT_STAGGER


func _convert_square(square: CubeSquare, type: SquareType) -> void:
	if not is_instance_valid(square) or square.is_broken() or (square.get_parent() as Cube).is_complete():
		return
	square.convert_to(type)
	# A rock turned into ore is one more square the cube needs broken.
	(square.get_parent() as Cube).recount()
	fx.square_converted(square.global_position, type)
	_update_field_value()


func _on_square_hit(_cube: Cube, square: CubeSquare) -> void:
	if not square.is_broken():
		_clicked_hits.append(square)
	if not _resolving_click:
		_resolve_click()


func _on_square_broken(cube: Cube, square: CubeSquare) -> void:
	_clicked_breaks.append(square)
	var bonus: float = _cube_bonus.get(cube, cube.get_value_multiplier())
	_clicked_value += roundi(square.value * bonus)
	var radius := Game.get_blast_radius(square.square_type)
	if radius > 0:
		_pending_blasts.append(Blast.new(square.global_position, radius))
	if square.square_type.strikes_lines:
		var area := Rect2(cube.global_position - cube.get_size() / 2.0, cube.get_size())
		_pending_blasts.append(Blast.new(square.global_position, 0, true, area))
	if not _resolving_click:
		_resolve_click()


## Pays out and plays the effects for everything the last click hit and broke, then
## lines up any explosives it broke as the next link of a chain reaction. Payouts get
## Game.get_payout_multiplier() (a money frenzy), and the player's clicks the combo too.
func _resolve_click(soft := false) -> void:
	if not _pending_blasts.is_empty():
		var timer := get_tree().create_timer(CHAIN_DELAY, false)
		timer.timeout.connect(_chain_blasts.bind(_take_pending_blasts(), soft))
	if not _clicked_hits.is_empty():
		fx.squares_hit(_clicked_hits, soft)
	if not _clicked_breaks.is_empty():
		var total := roundi(_clicked_value * Game.get_payout_multiplier())
		var payout := total if soft else combo.multiply(total)
		_update_field_value()
		Game.earn(payout)
		fx.squares_broken(_clicked_breaks, payout, soft)
	_clicked_hits = []
	_clicked_breaks = []
	_clicked_value = 0
	_cube_bonus.clear()


## A finished cube pays its clear bonus right away; the banner shows with the explosion.
func _on_cube_completed(cube: Cube) -> void:
	if cube == _dragged:
		_end_drag()
	_set_hovered(null, [])
	var multiplier := Game.get_clear_bonus()
	var bonus := Game.get_clear_payout(cube.get_total_value())
	Game.earn(bonus)
	cube.flash_white()
	Sfx.play(&"explode", 0.05)
	await fx.hitstop(0.09)
	fx.cube_exploded(cube)
	if bonus > 0:
		fx.cube_cleared(cube, multiplier, bonus)
	cube.queue_free()


## Reports how much money is still locked in unbroken squares, for the purchase guard.
func _update_field_value() -> void:
	var total := 0
	for cube in get_cubes():
		for square in cube.get_squares():
			if not square.is_broken():
				total += square.value
	Game.set_field_value(total)


# --- Saving -------------------------------------------------------------------------

func _on_saving(data: Dictionary) -> void:
	var cubes: Array[Dictionary] = []
	for cube in get_cubes():
		if not cube.is_complete():
			cubes.append({
				"type": cube.cube_type.resource_path,
				"x": cube.position.x,
				"y": cube.position.y,
				"squares": cube.get_save_data(),
			})
	data["cubes"] = cubes


## Puts back the cubes that were on the field when the game was saved, as they were.
func _restore_cubes(saved: Variant) -> void:
	if not saved is Array:
		return
	for entry: Variant in saved:
		if not entry is Dictionary:
			continue
		var type := Game.load_saved_resource(entry.get("type")) as CubeType
		if type == null:
			continue
		var cube := Cube.new()
		cube.setup(type)
		var squares: Variant = entry.get("squares")
		if squares is Array:
			cube.load_save_data(squares)
		cube.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		if cube.is_complete():
			cube.free()
		else:
			_add_cube(cube)
	_update_field_value()


func _add_cube(cube: Cube) -> void:
	add_child(cube)
	cube.square_hit.connect(_on_square_hit)
	cube.square_broken.connect(_on_square_broken)
	cube.completed.connect(_on_cube_completed)
	cube.landed.connect(_on_cube_landed)


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
