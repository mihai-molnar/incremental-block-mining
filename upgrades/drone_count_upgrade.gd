class_name DroneCountUpgrade
extends Upgrade
## Each tier adds a mining drone, which flies to squares and hits them on its own.


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "A drone that flies around hitting squares for you"
	var now := "Tier %d: %d drone%s" % [level, level, "" if level == 1 else "s"]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d drones" % [now, level + 1]


func create_icon() -> Control:
	return create_sprite_icon(&"drone")


func modify_drone_count(count: int, level: int) -> int:
	return count + level
