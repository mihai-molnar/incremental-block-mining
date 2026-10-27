class_name ComboWindowUpgrade
extends Upgrade
## Each tier gives the player longer between hits before the combo drops.

## Extra seconds per tier.
@export_range(0.0, 1.0, 0.05) var seconds_per_tier := 0.25


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Combos last %s between hits instead of %s" % [_format_window(1), _format_window(0)]
	var now := "Tier %d: combos last %s between hits" % [level, _format_window(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_window(level + 1)]


func _format_window(level: int) -> String:
	return format_number(Game.COMBO_WINDOW + seconds_per_tier * level) + "s"


func create_icon() -> Control:
	return create_sprite_icon(&"hourglass")


func modify_combo_window(seconds: float, level: int) -> float:
	return seconds + seconds_per_tier * level
