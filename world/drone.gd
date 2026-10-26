class_name Drone
extends Node2D
## A mining drone. Picks an unbroken square, flies over it and drills it until it breaks,
## then moves on to another. Its hits go through the work area, so they pay out like clicks.
## The node's position is the drill tip.

## Top speed, and how quickly the drone slows down as it nears its target.
const FLY_SPEED := 220.0
const FLY_EASE := 10.0
## Height above a square's center the drill tip hovers at while working.
const HOVER_HEIGHT := 5.0
## How far the drill dips on each hit, and how long it takes to come back up.
const PECK_DEPTH := 4.0
const PECK_DURATION := 0.15
const ROTOR_FRAME := 0.05
## Where the drill tip is in the drone sprite.
const DRILL_TIP := Vector2(6, 11)
const SHADOW_COLOR := Color(0, 0, 0, 0.3)

var swarm: DroneSwarm
## Where the drone waits when there's nothing to mine.
var home := Vector2.ZERO

var _target: CubeSquare
var _cooldown := 0.0
var _time := 0.0
var _peck := 0.0
var _peck_tween: Tween


func _ready() -> void:
	# Start out of step with the other drones, so they don't all bob and hit in unison.
	_time = randf() * 10.0
	_cooldown = randf() / Game.get_drone_hit_rate()


func _process(delta: float) -> void:
	_time += delta
	# A square that broke and whose cube is gone has been freed along with it.
	if not is_instance_valid(_target) or not swarm.is_workable(_target):
		_target = swarm.find_target(self)
	var goal := home if _target == null else _target.global_position - Vector2(0, HOVER_HEIGHT)
	var distance := global_position.distance_to(goal)
	global_position = global_position.move_toward(goal, clampf(distance * FLY_EASE, 30.0, FLY_SPEED) * delta)
	_cooldown -= delta
	if _target and distance < 1.0 and _cooldown <= 0.0:
		_cooldown = 1.0 / Game.get_drone_hit_rate()
		_drill()
	queue_redraw()


## The square the drone is working on, or null.
func get_target() -> CubeSquare:
	return _target if is_instance_valid(_target) else null


func _drill() -> void:
	swarm.work_area.drone_hit(_target)
	if _peck_tween:
		_peck_tween.kill()
	_peck = 1.0
	_peck_tween = create_tween()
	_peck_tween.tween_property(self, "_peck", 0.0, PECK_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var bob := roundf(sin(_time * 5.0)) if _peck == 0.0 else 0.0
	var dip := roundf(_peck * PECK_DEPTH)
	draw_rect(Rect2(-3, 7, 7, 2), SHADOW_COLOR)
	var sprite := &"drone" if floori(_time / ROTOR_FRAME) % 2 == 0 else &"drone_spin"
	draw_texture(PixelSprites.get_texture(sprite), -DRILL_TIP + Vector2(0, bob + dip))
