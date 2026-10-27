class_name DroneHpUpgrade
extends Upgrade
## Each tier makes mining drones last more hits before they break.

@export var hp_per_tier := 20


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Drones last %d more hits" % hp_per_tier
	var now := "Tier %d: drones last %d more hits" % [level, hp_per_tier * level]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d more" % [now, hp_per_tier * (level + 1)]


func create_icon() -> Control:
	return create_sprite_icon(&"drone")


func modify_drone_hp(hp: int, level: int) -> int:
	return hp + hp_per_tier * level
