class_name ClearBonusUpgrade
extends Upgrade
## Each tier raises what finishing a cube pays on top of its squares.

## Extra multiplier per tier (0.25 takes a x1.25 clear bonus to x1.5, then x1.75...).
@export_range(0.0, 2.0, 0.05) var bonus_per_tier := 0.25


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Finished cubes pay %s instead of %s" % [_format_bonus(1), _format_bonus(0)]
	var now := "Tier %d: finished cubes pay %s" % [level, _format_bonus(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_bonus(level + 1)]


func _format_bonus(level: int) -> String:
	return "x" + format_number(Game.CLEAR_BONUS + bonus_per_tier * level)


func create_icon() -> Control:
	return create_sprite_icon(&"trophy")


func modify_clear_bonus(multiplier: float, level: int) -> float:
	return multiplier + bonus_per_tier * level
