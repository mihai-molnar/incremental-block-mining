class_name AutoBuyUpgrade
extends Upgrade
## Buys cubes on its own: each tier keeps one more cube of the player's choice on the field.
## The cube is picked with the Auto toggle on its shop row.


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Rebuys the cube you pick (Auto in the shop) when the field runs out"
	var now := "Tier %d: keeps %d cube%s on the field" % [level, level, "" if level == 1 else "s"]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d cubes" % [now, level + 1]


func create_icon() -> Control:
	return create_sprite_icon(&"conveyor")


func modify_auto_buy_slots(slots: int, level: int) -> int:
	return slots + level
