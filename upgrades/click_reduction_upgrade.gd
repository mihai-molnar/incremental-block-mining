class_name ClickReductionUpgrade
extends Upgrade
## Each tier makes every square take one click less to break (never below 1).


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Squares take 1 click less (min 1)"
	var now := "Tier %d: %d click%s less" % [level, level, "" if level == 1 else "s"]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d less (min 1)" % [now, level + 1]


func create_icon() -> Control:
	var icon := TextureRect.new()
	icon.texture = PixelSprites.get_texture(&"pickaxe")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(26, 26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func modify_square_hp(_square_type: SquareType, hp: int, level: int) -> int:
	return hp - level
