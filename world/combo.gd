class_name Combo
extends Node
## The combo meter. Each of the player's clicks that hits something, landed within
## Game.get_combo_window() seconds of the last, adds Game.COMBO_STEP to a payout
## multiplier, up to Game.get_combo_cap(). Drone hits don't count, so active play pays more.

## Emitted when a hit raises the combo and when it runs out.
signal changed

## Hits in the current combo (0 = none going).
var hits := 0
## Seconds left to land the next hit before the combo drops.
var time_left := 0.0


func _ready() -> void:
	set_process(false)


func add_hit() -> void:
	hits += 1
	time_left = Game.get_combo_window()
	set_process(true)
	changed.emit()


## Payout multiplier: x1 on the first hit, then COMBO_STEP more for each hit after it.
func get_multiplier() -> float:
	if hits <= 1:
		return 1.0
	return minf(1.0 + Game.COMBO_STEP * (hits - 1), Game.get_combo_cap())


func is_maxed() -> bool:
	return hits > 1 and get_multiplier() >= Game.get_combo_cap()


## How much of the time to the next hit is left (1 = a hit just landed).
func get_time_ratio() -> float:
	return clampf(time_left / Game.get_combo_window(), 0.0, 1.0)


func _process(delta: float) -> void:
	time_left -= delta
	if time_left > 0.0:
		return
	hits = 0
	time_left = 0.0
	set_process(false)
	changed.emit()
