class_name CritChanceUpgrade
extends Upgrade
## Each tier raises the chance that one of the player's hits breaks a square outright.

## Extra crit chance per tier (0.02 makes tier 1 add 2%, tier 2 4%...).
@export_range(0.0, 0.2, 0.01) var chance_per_tier := 0.02


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Each hit has a %s chance to crit instead of %s. A crit breaks a square in one hit" % [
			_format_chance(1), _format_chance(0)]
	var now := "Tier %d: each hit has a %s chance to crit" % [level, _format_chance(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_chance(level + 1)]


func _format_chance(level: int) -> String:
	return "%d%%" % roundi((Game.CRIT_CHANCE + chance_per_tier * level) * 100.0)


func create_icon() -> Control:
	return create_sprite_icon(&"star")


func modify_crit_chance(chance: float, level: int) -> float:
	return chance + chance_per_tier * level
