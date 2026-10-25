class_name FlyingCoin
extends Sprite2D
## Coin that arcs from a point on screen to a target (the HUD money counter).

signal arrived(coin: FlyingCoin)

var value := 0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _control := Vector2.ZERO


func launch(from: Vector2, to: Vector2, duration: float, delay := 0.0) -> void:
	texture = PixelSprites.get_texture(&"coin")
	_from = from
	_to = to
	_control = from + Vector2(randf_range(-36.0, 36.0), randf_range(-56.0, -24.0))
	position = from
	visible = delay <= 0.0
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(show)
	tween.tween_method(_move_along, 0.0, 1.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_arrive)


## Quadratic bezier from start to target, bending through a random control point.
func _move_along(t: float) -> void:
	var u := 1.0 - t
	position = (u * u * _from + 2.0 * u * t * _control + t * t * _to).round()


func _arrive() -> void:
	arrived.emit(self)
	queue_free()
