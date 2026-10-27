class_name StartingDronesUpgrade
extends Upgrade
## Each tier starts every run with one more mining drone out.


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Runs start with a drone out"
	var now := "Tier %d: runs start with %d drone%s" % [level, level, "" if level == 1 else "s"]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d drones" % [now, level + 1]


func create_icon() -> Control:
	return create_sprite_icon(&"drone")


func modify_starting_drones(count: int, level: int) -> int:
	return count + level
