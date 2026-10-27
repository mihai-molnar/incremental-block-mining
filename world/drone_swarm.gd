class_name DroneSwarm
extends Node2D
## The mining drones out on the field. Launches one for every drone bought (and Drone Bay's
## when a run starts), finds them squares to mine and lets each go when its HP runs out.
## Saves their HP with the game. Drawn above the work area, so drones fly over the cubes.

## Idle drones line up along the top of the field, right of the money counter.
const HOME_START := Vector2(140, 18)
const HOME_SPACING := 22.0
## Random slack added to distances when picking a square, so drones don't all sweep a
## cube in the same order.
const TARGET_JITTER := 24.0

@export var work_area: WorkArea
@export var fx: Fx

var _drones: Array[Drone] = []


func _ready() -> void:
	Game.drone_launched.connect(func() -> void: _add_drone(Game.get_drone_hp(), true))
	Game.saving.connect(_on_saving)
	# Drones from a loaded save, or a new run's Drone Bay, are simply there.
	var saved: Variant = Game.take_saved("drones", [])
	if saved is Array:
		for hp: Variant in saved:
			_add_drone(int(hp), false)
	Game.set_drones_out(_drones.size())


## Whether a drone can keep working on this square. Drones leave rocks alone.
func is_workable(square: CubeSquare) -> bool:
	if square == null or square.is_broken() or not square.square_type.required:
		return false
	var cube := square.get_parent() as Cube
	return not cube.is_complete() and cube != work_area.get_held_cube()


## The nearest workable square no other drone is on, or null if there's none. Multiplier
## squares wait until the rest of their cube is broken, so the bonus pays on all of it.
func find_target(drone: Drone) -> CubeSquare:
	var claimed: Array[CubeSquare] = []
	for other in _drones:
		var target := other.get_target()
		if other != drone and target:
			claimed.append(target)
	var best: CubeSquare = null
	var best_score := INF
	var held := work_area.get_held_cube()
	for cube in work_area.get_cubes():
		if cube.is_complete() or cube == held:
			continue
		var multipliers_wait := cube.has_regular_squares_left()
		for square in cube.get_squares():
			if square.is_broken() or square in claimed or not square.square_type.required:
				continue
			if multipliers_wait and square.square_type.cube_value_bonus > 0.0:
				continue
			var score := square.global_position.distance_to(drone.global_position) + randf() * TARGET_JITTER
			if score < best_score:
				best_score = score
				best = square
	return best


## Called by a drone whose last hit used up its HP: it breaks, and the rest close ranks.
func on_drone_spent(drone: Drone) -> void:
	_drones.erase(drone)
	fx.drone_broken(drone.global_position)
	drone.queue_free()
	for i in _drones.size():
		_drones[i].home = _get_home(i)
	Game.set_drones_out(_drones.size())


## Every drone breaks at once (the mine collapsing at the end of a run).
func clear() -> void:
	for drone in _drones:
		fx.drone_broken(drone.global_position)
		drone.queue_free()
	_drones.clear()
	Game.set_drones_out(0)


func _add_drone(hp: int, fly_in: bool) -> void:
	if hp <= 0 or _drones.size() >= Game.MAX_DRONES:
		return
	var drone := Drone.new()
	drone.swarm = self
	drone.hp = hp
	drone.max_hp = maxi(hp, Game.get_drone_hp())
	drone.home = _get_home(_drones.size())
	# New drones fly in from above the screen.
	drone.position = drone.home - Vector2(0, 40) if fly_in else drone.home
	add_child(drone)
	_drones.append(drone)
	Game.set_drones_out(_drones.size())


func _get_home(index: int) -> Vector2:
	return HOME_START + Vector2(HOME_SPACING * index, 0)


func _on_saving(data: Dictionary) -> void:
	var hps: Array[int] = []
	for drone in _drones:
		hps.append(drone.hp)
	data["drones"] = hps
