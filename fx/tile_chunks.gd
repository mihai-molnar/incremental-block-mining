class_name TileChunks
extends Node2D
## A tile splitting into four chunks that pop outward and fall. Set the colors and
## optional push, add it to the tree, then call start(). Frees itself when done.

var outline_color := Color.BLACK
var fill_color := Color.WHITE
var highlight_color := Color.WHITE
## Extra velocity added to every chunk (e.g. away from an explosion center).
var push := Vector2.ZERO
var chunk_size := 7.0
var gravity := 650.0
var lifetime := 0.6

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _age := 0.0


func start() -> void:
	for offset in [Vector2(-4, -4), Vector2(4, -4), Vector2(-4, 4), Vector2(4, 4)]:
		_pos.append(offset)
		var velocity: Vector2 = offset.normalized() * randf_range(30.0, 80.0)
		velocity.y -= randf_range(70.0, 140.0)
		_vel.append(velocity + push * randf_range(0.7, 1.3))


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	for i in _pos.size():
		_vel[i] = _vel[i] + Vector2(0.0, gravity * delta)
		_pos[i] += _vel[i] * delta
	queue_redraw()


func _draw() -> void:
	var k := _age / lifetime
	var s := roundf(chunk_size * (1.0 - k * k * k))
	if s < 1.0:
		return
	for p in _pos:
		var rect := Rect2((p - Vector2(s, s) / 2.0).round(), Vector2(s, s))
		draw_rect(rect, outline_color)
		if s > 2.0:
			draw_rect(rect.grow(-1), fill_color)
			draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(s - 2.0, 1)), highlight_color)
