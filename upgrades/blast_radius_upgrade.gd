class_name BlastRadiusUpgrade
extends Upgrade
## Each tier makes explosions reach one square further.


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Explosions reach 1 square further"
	var now := "Tier %d: explosions reach %d square%s further" % [level, level, "" if level == 1 else "s"]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d further" % [now, level + 1]


func create_icon() -> Control:
	return create_sprite_icon(&"blast")


func modify_blast_radius(radius: int, level: int) -> int:
	return radius + level
