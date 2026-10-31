class_name Cube
extends Node2D
## A grid of breakable squares, centered on the node's position.
## Knows nothing about money or effects: it reports what happens through signals.

## Emitted on every successful hit, including the one that breaks a square.
signal square_hit(cube: Cube, square: CubeSquare)
signal square_broken(cube: Cube, square: CubeSquare)
## Emitted when the last square breaks. The cube stops accepting hits.
signal completed(cube: Cube)
## Emitted once, when the spawn drop touches down (or when it's cut short by a pickup).
signal landed(cube: Cube)

const SHADOW_OFFSET := Vector2(2, 3)
const LIFTED_SHADOW_OFFSET := Vector2(5, 8)
const SHADOW_COLOR := Color(0, 0, 0, 0.35)
## Frame around a cube a multiplier square is boosting.
const BOOST_COLOR := Color("a7f070")

var cube_type: CubeType

var hovered := false:
	set(v):
		if hovered != v:
			hovered = v
			queue_redraw()

var _squares: Array[CubeSquare] = []
## Required squares (see SquareType.required) still unbroken.
var _remaining := 0
var _shadow_offset := SHADOW_OFFSET
var _has_landed := false
var _tween: Tween


func setup(type: CubeType) -> void:
	cube_type = type
	var size := get_size()
	for y in type.grid_size.y:
		for x in type.grid_size.x:
			var square := CubeSquare.new()
			var square_type := type.square_type
			if type.mixed_square_type and randf() < type.mixed_chance:
				square_type = type.mixed_square_type
			square.setup(square_type, Vector2i(x, y), type)
			square.position = Vector2(x + 0.5, y + 0.5) * CubeSquare.SIZE - size / 2.0
			add_child(square)
			_squares.append(square)
	recount()


func get_size() -> Vector2:
	return Vector2(cube_type.grid_size * CubeSquare.SIZE)


## Footprint in the parent's coordinate space (ignores animation scale).
func get_rect() -> Rect2:
	var size := get_size()
	return Rect2(position - size / 2.0, size)


## Done once every required square is broken. Rocks left over crumble with it.
func is_complete() -> bool:
	return _remaining == 0


## Whether none of its squares has taken a hit yet.
func is_untouched() -> bool:
	for square in _squares:
		if square.hp < square.max_hp:
			return false
	return true


## Recounts the required squares left, after squares changed type.
func recount() -> void:
	_remaining = _squares.filter(func(square: CubeSquare) -> bool:
		return square.square_type.required and not square.is_broken()).size()
	queue_redraw()


## What its squares pay right now: x1, plus each unbroken multiplier square's bonus.
func get_value_multiplier() -> float:
	var multiplier := 1.0
	for square in _squares:
		if not square.is_broken():
			multiplier += square.square_type.cube_value_bonus
	return multiplier


## Whether any required square that isn't a multiplier is still unbroken. Drones leave
## multipliers alone until it's false.
func has_regular_squares_left() -> bool:
	for square in _squares:
		if not square.is_broken() and square.square_type.required and square.square_type.cube_value_bonus <= 0.0:
			return true
	return false


func has_point(global_point: Vector2) -> bool:
	var size := get_size()
	return Rect2(-size / 2.0, size).has_point(to_local(global_point))


func get_square_at(global_point: Vector2) -> CubeSquare:
	var local := to_local(global_point) + get_size() / 2.0
	var c := Vector2i((local / CubeSquare.SIZE).floor())
	if c.x < 0 or c.y < 0 or c.x >= cube_type.grid_size.x or c.y >= cube_type.grid_size.y:
		return null
	return _squares[c.y * cube_type.grid_size.x + c.x]


func get_squares() -> Array[CubeSquare]:
	return _squares


## Clicks still needed to finish it: the hits left on its unbroken required squares.
func get_hits_left() -> int:
	var total := 0
	for square in _squares:
		if square.square_type.required and not square.is_broken():
			total += square.hp
	return total


## Clicks the whole cube took when it was new: its required squares' full hits.
func get_total_hits() -> int:
	var total := 0
	for square in _squares:
		if square.square_type.required:
			total += square.max_hp
	return total


## What all the cube's squares pay together, broken or not.
func get_total_value() -> int:
	var total := 0
	for square in _squares:
		total += square.value
	return total


## Each square's clicks left (0 = broken) and, when it isn't the cube's default, its type.
## In grid order, for the save file.
func get_save_data() -> Array[Dictionary]:
	var squares: Array[Dictionary] = []
	for square in _squares:
		var entry := {"hp": square.hp}
		if square.square_type != cube_type.square_type:
			entry["type"] = square.square_type.resource_path
		squares.append(entry)
	return squares


## Puts back squares saved by get_save_data(). Call after setup(), before adding the cube
## to the tree. The cube counts as already landed, so its squares don't convert again.
func load_save_data(squares: Array) -> void:
	for i in mini(squares.size(), _squares.size()):
		var entry: Variant = squares[i]
		if not entry is Dictionary:
			continue
		var type := Game.load_saved_resource(entry.get("type")) as SquareType
		_squares[i].restore(type if type else cube_type.square_type, int(entry.get("hp", 1)))
	recount()
	_has_landed = true


## Hits one of this cube's squares. Returns false if it couldn't be hit.
func hit_square(square: CubeSquare, damage := 1) -> bool:
	if is_complete() or square.is_broken():
		return false
	var broke := square.hit(damage)
	square_hit.emit(self, square)
	if broke:
		if square.square_type.required:
			_remaining -= 1
		square_broken.emit(self, square)
		queue_redraw()
		if _remaining == 0:
			completed.emit(self)
	return true


## Hits the square under the point. Returns the square that was hit, or null if nothing was.
func hit_at(global_point: Vector2, damage := 1) -> CubeSquare:
	var square := get_square_at(global_point)
	if square and hit_square(square, damage):
		return square
	return null


func flash_white() -> void:
	for square in _squares:
		square.flash_white()


# --- Animation -------------------------------------------------------------

func play_spawn() -> void:
	var target := position
	position.y -= 28.0
	modulate.a = 0.0
	scale = Vector2(0.8, 1.2)
	_restart_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.08)
	_tween.parallel().tween_property(self, "position", target, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "scale", Vector2(0.9, 1.1), 0.2)
	_tween.tween_callback(_land)
	_tween.tween_property(self, "scale", Vector2(1.25, 0.75), 0.05)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_lifted(lifted: bool) -> void:
	_land()
	_restart_tween()
	modulate.a = 1.0
	if lifted:
		_tween.tween_method(_set_shadow_offset, _shadow_offset, LIFTED_SHADOW_OFFSET, 0.1)
		_tween.parallel().tween_property(self, "scale", Vector2.ONE * 1.08, 0.1) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_set_shadow_offset(SHADOW_OFFSET)
		scale = Vector2(1.15, 0.88)
		_tween.tween_property(self, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _land() -> void:
	if _has_landed:
		return
	_has_landed = true
	landed.emit(self)


func _restart_tween() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()


func _set_shadow_offset(offset: Vector2) -> void:
	_shadow_offset = offset
	queue_redraw()


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	# Shadows only under squares that are still solid, so ghosts read as empty.
	for square in _squares:
		if not square.is_broken():
			var rect := Rect2(square.position - Vector2.ONE * CubeSquare.HALF, Vector2.ONE * CubeSquare.SIZE)
			draw_rect(Rect2(rect.position + _shadow_offset, rect.size), SHADOW_COLOR)
	if get_value_multiplier() > 1.0 and not is_complete():
		_draw_frame(Rect2(-get_size() / 2.0, get_size()).grow(1), BOOST_COLOR)
	if hovered:
		_draw_frame(Rect2(-get_size() / 2.0, get_size()).grow(2), Color(1, 1, 1, 0.85))


func _draw_frame(frame: Rect2, color: Color) -> void:
	for side in [
		Rect2(frame.position, Vector2(frame.size.x, 1)),
		Rect2(frame.position + Vector2(0, frame.size.y - 1), Vector2(frame.size.x, 1)),
		Rect2(frame.position, Vector2(1, frame.size.y)),
		Rect2(frame.position + Vector2(frame.size.x - 1, 0), Vector2(1, frame.size.y)),
	]:
		draw_rect(side, color)
