class_name SquareShockwave
extends Node2D
## Expanding, fading square outline. Frees itself when done.

var start_half_size := 32.0
var end_half_size := 72.0
var duration := 0.35
var thickness := 3.0
var color := Color.WHITE

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := ease(_t / duration, 0.4)
	var half := roundf(lerpf(start_half_size, end_half_size, k))
	var w := maxf(1.0, roundf(thickness * (1.0 - k)))
	var c := Color(color, 1.0 - k)
	var outer := Rect2(-half, -half, half * 2.0, half * 2.0)
	draw_rect(Rect2(outer.position, Vector2(outer.size.x, w)), c)
	draw_rect(Rect2(outer.position + Vector2(0, outer.size.y - w), Vector2(outer.size.x, w)), c)
	draw_rect(Rect2(outer.position + Vector2(0, w), Vector2(w, outer.size.y - w * 2.0)), c)
	draw_rect(Rect2(outer.position + Vector2(outer.size.x - w, w), Vector2(w, outer.size.y - w * 2.0)), c)
