class_name LuckyCube
extends Node2D
## The golden cube a Lucky event sends drifting across the field, bobbing and shedding
## sparkles. LuckyEvent catches clicks on it. Emits `escaped` and frees itself once it has
## crossed the screen uncaught.

signal escaped

const PALETTE := preload("res://cubes/squares/gold_square.tres")
const TILE := 12
const SIZE := TILE * 2
## Seconds to cross the screen, and how high and how often it bobs on the way.
const CROSSING_TIME := 14.0
const BOB_HEIGHT := 10.0
const BOB_PERIOD := 2.4
## Clicks this far outside it still count, since it's moving.
const HIT_MARGIN := 6.0
const TRAIL_INTERVAL := 0.07

var fx: Fx

var _x := 0.0
var _lane_y := 0.0
var _speed := 0.0
var _end_x := 0.0
var _t := 0.0
var _trail_wait := 0.0


## Starts it just off one side of a screen `width` wide, drifting along the row at `y`.
func launch(from_left: bool, y: float, width: float) -> void:
	var margin := SIZE + BOB_HEIGHT
	_x = -margin if from_left else width + margin
	_end_x = width + margin if from_left else -margin
	_speed = (width + margin * 2.0) / CROSSING_TIME * (1.0 if from_left else -1.0)
	_lane_y = y
	_t = randf() * BOB_PERIOD
	_place()


func has_point(world_point: Vector2) -> bool:
	var half := SIZE / 2.0 + HIT_MARGIN
	return Rect2(global_position - Vector2.ONE * half, Vector2.ONE * half * 2.0).has_point(world_point)


func _process(delta: float) -> void:
	_t += delta
	_x += _speed * delta
	_place()
	_trail_wait -= delta
	if _trail_wait <= 0.0:
		_trail_wait = TRAIL_INTERVAL
		if fx:
			fx.lucky_trail(global_position)
	if (_speed > 0.0 and _x >= _end_x) or (_speed < 0.0 and _x <= _end_x):
		escaped.emit()
		queue_free()
	queue_redraw()


func _place() -> void:
	position = Vector2(_x, _lane_y + sin(_t / BOB_PERIOD * TAU) * BOB_HEIGHT).round()


func _draw() -> void:
	var half := SIZE / 2.0
	# A soft halo that pulses, so it catches the eye against dark cubes.
	var glow := 0.35 + 0.35 * sin(_t * 6.0)
	_draw_frame(Rect2(-half - 2, -half - 2, SIZE + 4, SIZE + 4), Color(PALETTE.shine_color, glow))
	for y in 2:
		for x in 2:
			_draw_tile(Rect2(Vector2(x, y) * TILE - Vector2.ONE * half, Vector2.ONE * TILE))
	var star := PixelSprites.get_texture(&"star")
	draw_texture(star, (-star.get_size() / 2.0).floor())


## A bevelled gold tile, drawn like a cube square.
func _draw_tile(rect: Rect2) -> void:
	draw_rect(rect, PALETTE.outline_color)
	var inner := rect.grow(-1)
	var p := inner.position
	var s := inner.size
	draw_rect(inner, PALETTE.base_color)
	draw_rect(Rect2(p, Vector2(s.x, 1)), PALETTE.light_color)
	draw_rect(Rect2(p, Vector2(1, s.y)), PALETTE.light_color)
	draw_rect(Rect2(p + Vector2(0, s.y - 1), Vector2(s.x, 1)), PALETTE.shadow_color)
	draw_rect(Rect2(p + Vector2(s.x - 1, 0), Vector2(1, s.y)), PALETTE.shadow_color)
	draw_rect(Rect2(p + Vector2(1, 1), Vector2(2, 1)), PALETTE.shine_color)


func _draw_frame(rect: Rect2, color: Color) -> void:
	var p := rect.position
	var s := rect.size
	draw_rect(Rect2(p, Vector2(s.x, 1)), color)
	draw_rect(Rect2(p + Vector2(0, s.y - 1), Vector2(s.x, 1)), color)
	draw_rect(Rect2(p + Vector2(0, 1), Vector2(1, s.y - 2)), color)
	draw_rect(Rect2(p + Vector2(s.x - 1, 1), Vector2(1, s.y - 2)), color)
