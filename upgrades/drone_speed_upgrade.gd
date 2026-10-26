class_name DroneSpeedUpgrade
extends Upgrade
## Each tier makes every drone hit faster.

## Extra hit speed per tier (0.25 makes tier 1 25% faster, tier 2 50%...).
@export_range(0.0, 2.0, 0.05) var speed_per_tier := 0.25


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Drones hit %s faster" % _format_bonus(1)
	var now := "Tier %d: drones hit %s faster" % [level, _format_bonus(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_bonus(level + 1)]


func _format_bonus(level: int) -> String:
	return "%d%%" % roundi(speed_per_tier * level * 100.0)


func create_icon() -> Control:
	return create_sprite_icon(&"bolt")


func modify_drone_hit_rate(rate: float, level: int) -> float:
	return rate * (1.0 + speed_per_tier * level)
