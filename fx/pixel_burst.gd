class_name PixelBurst
extends Node2D
## One-shot burst of square pixel particles. Set the properties, add it to the tree,
## then call start(). Frees itself once every particle has died.

var colors: Array[Color] = [Color.WHITE]
var amount := 10
## Zero means particles fly in every direction.
var direction := Vector2.ZERO
## Half-angle (radians) around `direction`.
var spread := PI
var speed_min := 40.0
var speed_max := 120.0
var gravity := 320.0
var damping := 1.5
var lifetime_min := 0.3
var lifetime_max := 0.6
var size_min := 1
var size_max := 3
## Particles start at a random offset within +-extents.
var emit_extents := Vector2.ZERO

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _age := PackedFloat32Array()
var _life := PackedFloat32Array()
var _size := PackedInt32Array()
var _color := PackedColorArray()


func start() -> void:
	for i in amount:
		var angle := randf() * TAU
		if direction != Vector2.ZERO:
			angle = direction.angle() + randf_range(-spread, spread)
		_pos.append(Vector2(randf_range(-emit_extents.x, emit_extents.x), randf_range(-emit_extents.y, emit_extents.y)))
		_vel.append(Vector2.from_angle(angle) * randf_range(speed_min, speed_max))
		_age.append(0.0)
		_life.append(randf_range(lifetime_min, lifetime_max))
		_size.append(randi_range(size_min, size_max))
		_color.append(colors.pick_random())


func _process(delta: float) -> void:
	var alive := false
	var drag := maxf(1.0 - damping * delta, 0.0)
	for i in _pos.size():
		_age[i] += delta
		if _age[i] >= _life[i]:
			continue
		alive = true
		_vel[i] = _vel[i] * drag + Vector2(0.0, gravity * delta)
		_pos[i] += _vel[i] * delta
	if not alive:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	for i in _pos.size():
		var t := _age[i] / _life[i]
		if t >= 1.0:
			continue
		var s := maxf(1.0, roundf(_size[i] * (1.0 - t * t)))
		draw_rect(Rect2((_pos[i] - Vector2(s, s) / 2.0).round(), Vector2(s, s)), _color[i])
