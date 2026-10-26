class_name CubeSquare
extends Node2D
## One breakable cell of a cube. Tracks its own damage and draws itself as a pixel-art
## tile, with cracks while damaged and a ghost outline once broken.
## Clicks needed come from Game (so upgrades apply), and are re-checked when one is bought.

const SIZE := 16
const HALF := SIZE / 2.0
## Crack branches generated per square; they're revealed in proportion to damage.
const CRACK_BRANCHES := 6
## How far the fill darkens toward the shadow color at full damage.
const DAMAGE_TINT := 0.45
## Shimmering squares: random wait between glints, and how long one sweep takes.
const SHINE_INTERVAL_MIN := 1.5
const SHINE_INTERVAL_MAX := 4.0
const SHINE_DURATION := 0.4
## Explosive squares: where the bomb emblem's fuse ends (relative to the tile center) and
## the colors its spark flickers through, one per frame.
const FUSE_TIP := Vector2(3, -6)
const FUSE_SPARK_COLORS: Array[Color] = [Color("ffcd75"), Color("f4f4f4"), Color("ef7d57"), Color("f4f4f4")]
const FUSE_SPARK_FRAME := 0.07

var square_type: SquareType
## The cube this square belongs to; some square types pay relative to it.
var cube_type: CubeType
var cell := Vector2i.ZERO
var max_hp := 1
var hp := 1
var value := 0

var hovered := false:
	set(v):
		if hovered != v:
			hovered = v
			queue_redraw()

## 0..1 white overlay, animated on hit.
var flash := 0.0:
	set(v):
		flash = v
		queue_redraw()

var _cracks: Array[PackedVector2Array] = []
var _tween: Tween
var _shine_wait := 0.0
## Progress (0..1) of the current glint, or negative when idle.
var _shine_t := -1.0
var _fuse_t := 0.0


func _ready() -> void:
	# Godot turns processing on when a node with _process enters the tree; only
	# shimmering and explosive squares need it.
	set_process(_is_animated())
	Game.upgrade_purchased.connect(_on_upgrade_purchased)


func setup(type: SquareType, grid_cell: Vector2i, in_cube: CubeType) -> void:
	square_type = type
	cube_type = in_cube
	cell = grid_cell
	max_hp = Game.get_square_hp(type, in_cube)
	hp = max_hp
	value = type.get_value(in_cube)
	_generate_cracks()
	_reset_shimmer()


## Puts back a saved square: its type and the clicks it had left (0 = broken).
func restore(type: SquareType, hp_left: int) -> void:
	square_type = type
	value = type.get_value(cube_type)
	max_hp = Game.get_square_hp(type, cube_type)
	hp = clampi(hp_left, 1, max_hp) if hp_left > 0 else 0
	_reset_shimmer()
	queue_redraw()


## Turns the square into another type, keeping any damage it already took.
func convert_to(type: SquareType) -> void:
	if is_broken():
		return
	square_type = type
	value = type.get_value(cube_type)
	_refresh_hp()
	_reset_shimmer()
	_punch(1.35)


## Re-reads how many clicks this square needs, keeping the hits it already took.
## A square never breaks from this alone: at worst it's one click from breaking.
func _refresh_hp() -> void:
	if is_broken():
		return
	var damage := max_hp - hp
	max_hp = Game.get_square_hp(square_type, cube_type)
	hp = maxi(max_hp - damage, 1)
	queue_redraw()


func _on_upgrade_purchased(_upgrade: Upgrade) -> void:
	_refresh_hp()


func is_broken() -> bool:
	return hp <= 0


func get_damage_ratio() -> float:
	return 1.0 - float(hp) / float(max_hp)


## Applies damage. Returns true if this hit broke the square.
func hit(damage := 1) -> bool:
	if is_broken():
		return false
	hp = maxi(hp - damage, 0)
	_punch(1.25 if is_broken() else 0.8)
	queue_redraw()
	return is_broken()


## Turns the square solid white; used for the freeze frame when the cube completes.
func flash_white() -> void:
	if _tween:
		_tween.kill()
	scale = Vector2.ONE
	flash = 1.0


func _reset_shimmer() -> void:
	_shine_t = -1.0
	_shine_wait = randf_range(0.3, SHINE_INTERVAL_MAX)
	set_process(_is_animated())


func _is_animated() -> bool:
	return not is_broken() and (square_type.shimmer or square_type.is_explosive())


func _process(delta: float) -> void:
	if is_broken():
		_shine_t = -1.0
		set_process(false)
		return
	if square_type.is_explosive():
		_update_fuse(delta)
	if square_type.shimmer:
		_update_shine(delta)


func _update_fuse(delta: float) -> void:
	var frame := floori(_fuse_t / FUSE_SPARK_FRAME)
	_fuse_t += delta
	if floori(_fuse_t / FUSE_SPARK_FRAME) != frame:
		queue_redraw()


func _update_shine(delta: float) -> void:
	if _shine_t < 0.0:
		_shine_wait -= delta
		if _shine_wait <= 0.0:
			_shine_t = 0.0
		return
	_shine_t += delta / SHINE_DURATION
	if _shine_t >= 1.0:
		_shine_t = -1.0
		_shine_wait = randf_range(SHINE_INTERVAL_MIN, SHINE_INTERVAL_MAX)
	queue_redraw()


func _punch(from_scale: float) -> void:
	if _tween:
		_tween.kill()
	flash = 1.0
	scale = Vector2.ONE * from_scale
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "flash", 0.0, 0.14)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	var rect := Rect2(-HALF, -HALF, SIZE, SIZE)
	if is_broken():
		_draw_ghost(rect)
	else:
		_draw_tile(rect)
		_draw_emblem()
		_draw_cracks()
		if _shine_t >= 0.0:
			_draw_shine(rect.grow(-1))
		if hovered:
			_draw_frame(rect.grow(-1), Color(1, 1, 1, 0.85))
	if flash > 0.0:
		draw_rect(rect, Color(1, 1, 1, flash))


func _draw_tile(rect: Rect2) -> void:
	var t := square_type
	draw_rect(rect, t.outline_color)
	var inner := rect.grow(-1)
	var p := inner.position
	var s := inner.size
	draw_rect(inner, t.base_color.lerp(t.shadow_color, get_damage_ratio() * DAMAGE_TINT))
	draw_rect(Rect2(p, Vector2(s.x, 1)), t.light_color)
	draw_rect(Rect2(p, Vector2(1, s.y)), t.light_color)
	draw_rect(Rect2(p + Vector2(0, s.y - 1), Vector2(s.x, 1)), t.shadow_color)
	draw_rect(Rect2(p + Vector2(s.x - 1, 0), Vector2(1, s.y)), t.shadow_color)
	draw_rect(Rect2(p + Vector2(1, 1), Vector2(3, 1)), t.shine_color)
	draw_rect(Rect2(p + Vector2(1, 2), Vector2(1, 1)), t.shine_color)


func _draw_emblem() -> void:
	if square_type.emblem.is_empty():
		return
	var texture := PixelSprites.get_texture(square_type.emblem)
	draw_texture(texture, (-texture.get_size() / 2.0).floor())
	if square_type.is_explosive():
		_draw_fuse_spark()


## A lit fuse: the tip cycles colors every frame and flares into a small cross every other one.
func _draw_fuse_spark() -> void:
	var frame := floori(_fuse_t / FUSE_SPARK_FRAME)
	var color := FUSE_SPARK_COLORS[frame % FUSE_SPARK_COLORS.size()]
	draw_rect(Rect2(FUSE_TIP, Vector2.ONE), color)
	if frame % 2 == 0:
		var flare := Color(color, 0.75)
		draw_rect(Rect2(FUSE_TIP + Vector2(-1, 0), Vector2(3, 1)), flare)
		draw_rect(Rect2(FUSE_TIP + Vector2(0, -1), Vector2(1, 3)), flare)


## A diagonal glint sweeping from the top-left to the bottom-right corner, then a
## small four-point twinkle in the top-right corner as it passes.
func _draw_shine(inner: Rect2) -> void:
	var side := int(inner.size.x)
	var band := [Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.35)]
	var front := roundi(lerpf(-band.size(), side * 2.0, _shine_t))
	for y in side:
		for i in band.size():
			var x := front - y - i
			if x >= 0 and x < side:
				draw_rect(Rect2(inner.position + Vector2(x, y), Vector2.ONE), band[i])
	var twinkle := sin(PI * clampf((_shine_t - 0.45) / 0.55, 0.0, 1.0))
	if twinkle > 0.05:
		var star := Vector2(HALF - 3, -HALF + 2)
		var arm := 2 if twinkle > 0.5 else 1
		var color := Color(1, 1, 1, twinkle)
		draw_rect(Rect2(star - Vector2(arm, 0), Vector2(arm * 2 + 1, 1)), color)
		draw_rect(Rect2(star - Vector2(0, arm), Vector2(1, arm * 2 + 1)), color)


func _draw_cracks() -> void:
	var damage := get_damage_ratio()
	if damage <= 0.0:
		return
	var visible_branches := ceili(CRACK_BRANCHES * damage)
	for i in mini(visible_branches, _cracks.size()):
		for px in _cracks[i]:
			draw_rect(Rect2(px + Vector2(1, 1), Vector2.ONE), square_type.light_color)
	for i in mini(visible_branches, _cracks.size()):
		for px in _cracks[i]:
			draw_rect(Rect2(px, Vector2.ONE), square_type.outline_color)


func _draw_ghost(rect: Rect2) -> void:
	var color := square_type.light_color
	draw_rect(rect.grow(-1), Color(color, 0.06))
	var dots := Color(color, 0.32)
	for i in range(0, SIZE, 2):
		draw_rect(Rect2(rect.position + Vector2(i, 0), Vector2.ONE), dots)
		draw_rect(Rect2(rect.position + Vector2(i, SIZE - 1), Vector2.ONE), dots)
	for i in range(2, SIZE - 1, 2):
		draw_rect(Rect2(rect.position + Vector2(0, i), Vector2.ONE), dots)
		draw_rect(Rect2(rect.position + Vector2(SIZE - 1, i), Vector2.ONE), dots)


func _draw_frame(rect: Rect2, color: Color) -> void:
	var p := rect.position
	var s := rect.size
	draw_rect(Rect2(p, Vector2(s.x, 1)), color)
	draw_rect(Rect2(p + Vector2(0, s.y - 1), Vector2(s.x, 1)), color)
	draw_rect(Rect2(p, Vector2(1, s.y)), color)
	draw_rect(Rect2(p + Vector2(s.x - 1, 0), Vector2(1, s.y)), color)


## Pre-generates jagged crack branches radiating from a point near the center.
## They are revealed progressively as the square takes damage.
func _generate_cracks() -> void:
	_cracks.clear()
	var origin := Vector2i(randi_range(-2, 1), randi_range(-2, 1))
	var directions: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]
	directions.shuffle()
	var limit := HALF - 2
	for i in CRACK_BRANCHES:
		var dir := directions[i % directions.size()]
		var branch := PackedVector2Array()
		var p := origin
		branch.append(Vector2(p))
		for step in randi_range(5, 8):
			match randi() % 3:
				0: p.x += dir.x
				1: p.y += dir.y
				_: p += dir
			if p.x < -limit or p.x >= limit or p.y < -limit or p.y >= limit:
				break
			branch.append(Vector2(p))
		_cracks.append(branch)
