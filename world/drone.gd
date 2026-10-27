class_name Drone
extends Node2D
## A mining drone. Picks an unbroken square, flies over it and drills it until it breaks,
## then moves on to another. Its hits go through the work area, so they pay out like clicks.
## Each hit costs it one HP, shown on a bar above it; the swarm lets it go at 0.
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
## The HP bar above the drone: below LOW_HP of its max it turns red.
const HP_BAR := Rect2(-4, -14, 8, 1)
const LOW_HP := 0.25
const HP_COLOR := Color("38b764")
const LOW_HP_COLOR := Color("e43b44")
const HP_TRACK_COLOR := Color("333c57")

var swarm: DroneSwarm
## Where the drone waits when there's nothing to mine.
var home := Vector2.ZERO
## Hits left before it breaks, out of the HP it was launched with.
var hp := 1
var max_hp := 1

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
	if not Game.is_run_active():
		# The pickaxe broke: the run is over, so drones head home.
		_target = null
	elif not is_instance_valid(_target) or not swarm.is_workable(_target):
		# A square that broke and whose cube is gone has been freed along with it.
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
	hp -= 1
	if hp <= 0:
		swarm.on_drone_spent(self)
		return
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
	var ratio := float(hp) / max_hp
	var bar := HP_BAR
	bar.position.y += bob + dip
	draw_rect(bar, HP_TRACK_COLOR)
	bar.size.x = maxf(roundf(bar.size.x * ratio), 1.0)
	draw_rect(bar, LOW_HP_COLOR if ratio < LOW_HP else HP_COLOR)
