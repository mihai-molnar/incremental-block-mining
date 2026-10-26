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
	var icon := TextureRect.new()
	icon.texture = PixelSprites.get_texture(&"blast")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(26, 26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func modify_blast_radius(radius: int, level: int) -> int:
	return radius + level
