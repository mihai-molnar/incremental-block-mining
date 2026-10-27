class_name ComboCapUpgrade
extends Upgrade
## Each tier lets the combo meter climb to a higher payout multiplier.

## Extra multiplier per tier (0.5 takes a x2 cap to x2.5, then x3...).
@export_range(0.0, 2.0, 0.05) var cap_per_tier := 0.5


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Combos go up to %s instead of %s" % [_format_cap(1), _format_cap(0)]
	var now := "Tier %d: combos go up to %s" % [level, _format_cap(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_cap(level + 1)]


func _format_cap(level: int) -> String:
	return "x" + format_number(Game.COMBO_CAP + cap_per_tier * level)


func create_icon() -> Control:
	return create_sprite_icon(&"flame")


func modify_combo_cap(cap: float, level: int) -> float:
	return cap + cap_per_tier * level
