class_name FrenzyDurationUpgrade
extends Upgrade
## Each tier makes frenzies last longer.

## Extra seconds per tier.
@export_range(0.0, 30.0, 1.0) var seconds_per_tier := 5.0


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Frenzies last %s instead of %s" % [_format_duration(1), _format_duration(0)]
	var now := "Tier %d: frenzies last %s" % [level, _format_duration(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_duration(level + 1)]


func _format_duration(level: int) -> String:
	return format_number(Game.FRENZY_DURATION + seconds_per_tier * level) + "s"


func create_icon() -> Control:
	return create_sprite_icon(&"lucky_cube")


func modify_frenzy_duration(seconds: float, level: int) -> float:
	return seconds + seconds_per_tier * level
