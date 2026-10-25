class_name ShakeCamera
extends Camera2D
## Camera with trauma-based screen shake: add_trauma() bumps it, it decays over time.

@export var max_offset := Vector2(7, 5)
## Trauma lost per second.
@export var decay := 2.2

var _trauma := 0.0


func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - decay * delta, 0.0)
	var strength := _trauma * _trauma
	offset = Vector2(
		randf_range(-1.0, 1.0) * max_offset.x * strength,
		randf_range(-1.0, 1.0) * max_offset.y * strength,
	).round()
