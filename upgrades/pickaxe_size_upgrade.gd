class_name PickaxeSizeUpgrade
extends Upgrade
## Each level widens the area one click hits by 2 squares a side: 2x2, then 4x4, 6x6...


static func get_side(level: int) -> int:
	return 2 * level if level > 0 else 1


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Each click hits 2x2 squares"
	var side := get_side(level)
	var now := "Tier %d: hits %dx%d" % [level, side, side]
	if is_maxed():
		return now + " (max)"
	var next := get_side(level + 1)
	return "%s\nNext tier: %dx%d" % [now, next, next]


## The pickaxe sprite at double size, to set it apart from Sharp Pickaxe.
func create_icon() -> Control:
	var icon := TextureRect.new()
	icon.texture = PixelSprites.get_texture(&"pickaxe")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 28)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func modify_pickaxe_size(size: int, level: int) -> int:
	return size * get_side(level)
