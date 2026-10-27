class_name Frenzy
extends Upgrade
## A burst of luck that catching a Lucky Cube sets off. It isn't sold: Game folds it in
## like an owned upgrade while it runs (Game.add_timed_effect), through the same hooks.
## `title` names it on the banner and the HUD timer; `description` says what it does.

## Color of its banner and HUD timer.
@export var color := Color("ffcd75")
## Every payout from squares is multiplied by this.
@export var payout_multiplier := 1.0
## When set, every default square of a cube that lands turns into this type.
@export var square_type: SquareType
## Drones hit this many times as fast.
@export var drone_rate_multiplier := 1.0


## Whether it would do anything right now: drone frenzies need drones.
func is_useful() -> bool:
	return is_equal_approx(drone_rate_multiplier, 1.0) or Game.get_drone_count() > 0


func modify_payout_multiplier(multiplier: float, _level: int) -> float:
	return multiplier * payout_multiplier


func modify_square_type(for_cube: CubeType, current: SquareType, _level: int) -> SquareType:
	if square_type and current == for_cube.square_type:
		return square_type
	return current


func modify_drone_hit_rate(rate: float, _level: int) -> float:
	return rate * drone_rate_multiplier
