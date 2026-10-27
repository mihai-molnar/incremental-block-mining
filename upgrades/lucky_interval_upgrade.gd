class_name LuckyIntervalUpgrade
extends Upgrade
## Each tier makes Lucky Cubes drift by after fewer squares broken.

## How many fewer squares per tier (0.15 makes tier 1 need 15% fewer, tier 2 30%...).
@export_range(0.0, 0.25, 0.01) var cut_per_tier := 0.15


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Lucky Cubes come after %s fewer squares broken. Click one for a frenzy" % _format_cut(1)
	var now := "Tier %d: Lucky Cubes come after %s fewer squares" % [level, _format_cut(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_cut(level + 1)]


func _format_cut(level: int) -> String:
	return "%d%%" % roundi(cut_per_tier * level * 100.0)


func create_icon() -> Control:
	return create_sprite_icon(&"clover")


func modify_lucky_interval(squares: float, level: int) -> float:
	return squares * maxf(1.0 - cut_per_tier * level, 0.1)
