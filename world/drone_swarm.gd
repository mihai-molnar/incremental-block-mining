class_name DroneSwarm
extends Node2D
## Keeps as many mining drones flying as the player owns, and finds them squares to mine.
## Drawn above the work area, so drones fly over the cubes.

## Idle drones line up along the top of the field, right of the money counter.
const HOME_START := Vector2(140, 18)
const HOME_SPACING := 22.0
## Random slack added to distances when picking a square, so drones don't all sweep a
## cube in the same order.
const TARGET_JITTER := 24.0

@export var work_area: WorkArea

var _drones: Array[Drone] = []


func _ready() -> void:
	Game.upgrade_purchased.connect(func(_upgrade: Upgrade) -> void: _add_missing_drones(true))
	# Drones owned from a loaded save are simply there.
	_add_missing_drones(false)


## Whether a drone can keep working on this square.
func is_workable(square: CubeSquare) -> bool:
	if square == null or square.is_broken():
		return false
	var cube := square.get_parent() as Cube
	return not cube.is_complete() and cube != work_area.get_held_cube()


## The nearest workable square no other drone is on, or null if there's none.
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
		for square in cube.get_squares():
			if square.is_broken() or square in claimed:
				continue
			var score := square.global_position.distance_to(drone.global_position) + randf() * TARGET_JITTER
			if score < best_score:
				best_score = score
				best = square
	return best


func _add_missing_drones(fly_in: bool) -> void:
	while _drones.size() < Game.get_drone_count():
		var drone := Drone.new()
		drone.swarm = self
		drone.home = HOME_START + Vector2(HOME_SPACING * _drones.size(), 0)
		# New drones fly in from above the screen.
		drone.position = drone.home - Vector2(0, 40) if fly_in else drone.home
		add_child(drone)
		_drones.append(drone)
