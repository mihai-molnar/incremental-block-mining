class_name AutoBuyer
extends Node
## Buys the cube picked with Auto in the shop whenever the field holds fewer unfinished
## cubes than the Auto-Buyer upgrade keeps there.

## Seconds between checks, so a cleared field refills after a beat rather than instantly.
const CHECK_INTERVAL := 0.5

@export var work_area: WorkArea

var _wait := 0.0


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = CHECK_INTERVAL
	var cube_type := Game.auto_buy_cube
	if cube_type == null or _count_unfinished_cubes() >= Game.get_auto_buy_slots():
		return
	if Game.try_spend(cube_type.price):
		Game.deliver_cube(cube_type)


func _count_unfinished_cubes() -> int:
	return work_area.get_cubes().filter(func(cube: Cube) -> bool: return not cube.is_complete()).size()
