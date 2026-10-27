class_name FrenzyDurationUpgrade
extends Upgrade
## Each tier makes frenzies last longer, and shield frenzies hold more clicks in step.

## Extra seconds per tier.
@export_range(0.0, 30.0, 1.0) var seconds_per_tier := 5.0
## A shield frenzy whose clicks the description lists too.
@export var shield_frenzy: Frenzy


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		var first := "Frenzies last %s instead of %s" % [_format_seconds(1), _format_seconds(0)]
		if shield_frenzy:
			first += "; %s %s instead of %d" % [shield_frenzy.get_title(), _format_clicks(1), _get_clicks(0)]
		return first
	var now := "Tier %d: frenzies last %s" % [level, _format_seconds(level)]
	var next := _format_seconds(level + 1)
	if shield_frenzy:
		now += ", %s %s" % [shield_frenzy.get_title(), _format_clicks(level)]
		next += ", " + _format_clicks(level + 1)
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, next]


func _get_seconds(level: int) -> float:
	return Game.FRENZY_DURATION + seconds_per_tier * level


func _format_seconds(level: int) -> String:
	return format_number(_get_seconds(level)) + "s"


## The shield frenzy's clicks at that tier, in step with the duration.
func _get_clicks(level: int) -> int:
	return roundi(shield_frenzy.shield_clicks * _get_seconds(level) / Game.FRENZY_DURATION)


func _format_clicks(level: int) -> String:
	return "%d clicks" % _get_clicks(level)


func create_icon() -> Control:
	return create_sprite_icon(&"lucky_cube")


func modify_frenzy_duration(seconds: float, level: int) -> float:
	return seconds + seconds_per_tier * level
