class_name Frenzy
extends Upgrade
## A burst of luck that catching a Lucky Cube sets off. It isn't sold: Game folds it in
## like an owned upgrade while it runs (Game.add_timed_effect), through the same hooks.
## A shield frenzy (`shield_clicks`) isn't timed: it shields the pickaxe for a number of
## clicks instead. `title` names it on the banner and the HUD timer; `description` says
## what it does.

## Color of its banner and HUD timer.
@export var color := Color("ffcd75")
## Every payout from squares is multiplied by this.
@export var payout_multiplier := 1.0
## When set, every default square of a cube that lands turns into this type.
@export var square_type: SquareType
## Drones hit this many times as fast.
@export var drone_rate_multiplier := 1.0
## When above 0, catching it shields the pickaxe for this many clicks on squares (more
## with Gold Fever, in step with frenzy durations) instead of starting a timed frenzy.
@export var shield_clicks := 0


## Sets it off: a shield, or a timed frenzy for Game.get_frenzy_duration().
func start() -> void:
	if shield_clicks > 0:
		Game.add_pickaxe_shield(get_shield_clicks())
	else:
		Game.add_timed_effect(self, Game.get_frenzy_duration())


func get_shield_clicks() -> int:
	return roundi(shield_clicks * Game.get_frenzy_duration() / Game.FRENZY_DURATION)


func get_description() -> String:
	if shield_clicks > 0:
		return "Your next %d clicks on squares cost no HP" % get_shield_clicks()
	return super()


## Whether it would do anything right now: drone frenzies need drones.
func is_useful() -> bool:
	return is_equal_approx(drone_rate_multiplier, 1.0) or Game.drones_out > 0


func modify_payout_multiplier(multiplier: float, _level: int) -> float:
	return multiplier * payout_multiplier


func modify_square_type(for_cube: CubeType, current: SquareType, _level: int) -> SquareType:
	if square_type and current == for_cube.square_type:
		return square_type
	return current


func modify_drone_hit_rate(rate: float, _level: int) -> float:
	return rate * drone_rate_multiplier
