class_name LightningBolt
extends Node2D
## A jagged electric line between two points that crackles into a new shape every few
## frames and fades out. Frees itself when done.

const JITTER_INTERVAL := 0.04
## Distance between kinks, and how far a kink strays from the straight line.
const SEGMENT := 6.0
const STRAY := 3.0

var from := Vector2.ZERO
var to := Vector2.ZERO
var duration := 0.3
var glow_color := Color("73eff7")

var _t := 0.0
var _jitter_wait := 0.0
var _points := PackedVector2Array()


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	_jitter_wait -= delta
	if _jitter_wait <= 0.0:
		_jitter_wait = JITTER_INTERVAL
		_reshape()
	queue_redraw()


func _reshape() -> void:
	_points.clear()
	var steps := maxi(ceili(from.distance_to(to) / SEGMENT), 1)
	var normal := (to - from).orthogonal().normalized()
	for i in steps + 1:
		var point := from.lerp(to, float(i) / steps)
		if i > 0 and i < steps:
			point += normal * randf_range(-STRAY, STRAY)
		_points.append(point.round())


func _draw() -> void:
	if _points.size() < 2:
		return
	var fade := 1.0 - _t / duration
	draw_polyline(_points, Color(glow_color, 0.6 * fade), 3.0)
	draw_polyline(_points, Color(1, 1, 1, fade), 1.0)
